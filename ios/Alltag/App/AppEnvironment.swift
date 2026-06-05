import Foundation
import Observation
import SwiftUI

/// Lightweight dependency container for the app (P0-06).
///
/// Owns the long-lived controllers/services and is injected once into the
/// SwiftUI environment, so any view can read what it needs without global
/// singletons. As features land, their use-cases are constructed here from these
/// foundations (persistence, language, theme).
///
/// There is no purchase/entitlement service: the app is a **paid app** (D5) —
/// the App Store charges a single upfront price and everything is unlocked on
/// install, so there is nothing to gate at runtime.
@MainActor
@Observable
final class AppEnvironment {
    let theme: ThemeController
    let language: LanguageStore
    let persistence: PersistenceController
    /// On-device inference facade: model readiness + the swappable engine (P0-07).
    let llm: LLMService
    /// Active-persona store + preserved past situations (P2-02/P4-01).
    let personas: PersonaStore
    /// Per-persona checklist progress, preserved across mode switches (P4-01/03).
    let checklist: ChecklistStore
    /// Onboarding navigation + completion gate (P2).
    let onboarding: OnboardingController
    /// Local-notification permission (P2-03), abstracted for testability.
    let notifications: NotificationAuthorizing
    /// First-run model readiness for the Decoder (P3-00).
    let decoderReadiness: DecoderReadinessController
    /// One capture → OCR → explain → result run for the Decoder (P3-01…P3-03).
    let decoder: DecoderController
    /// Deadlines + reminder scheduling for the Dates agenda (P3-07/08).
    let deadlines: DeadlineStore
    /// On-device document vault + expiry handling (P3-05/06).
    let vault: VaultStore

    /// GDPR export/delete-all, composed from the stores (P3-09).
    var dataManagement: DataManagementController {
        DataManagementController(vault: vault, deadlines: deadlines, checklist: checklist)
    }

    init(
        persistence: PersistenceController,
        llm: LLMService,
        fileStore: EncryptedFileStore = .ephemeral(),
        theme: ThemeController = ThemeController(),
        language: LanguageStore = LanguageStore(),
        personas: PersonaStore = PersonaStore(),
        onboarding: OnboardingController = OnboardingController(),
        notifications: NotificationAuthorizing = SystemNotificationAuthorizer(),
        reminders: any ReminderScheduling = SystemReminderScheduler(),
        recognizer: any TextRecognizing = VisionTextRecognizer()
    ) {
        self.persistence = persistence
        self.llm = llm
        self.theme = theme
        self.language = language
        self.personas = personas
        self.checklist = ChecklistStore(context: persistence.container.mainContext)
        self.onboarding = onboarding
        self.notifications = notifications
        self.decoderReadiness = DecoderReadinessController(provisioner: llm.provisioner)
        self.decoder = DecoderController(
            recognizer: recognizer,
            decode: DecodeLetterUseCase(engine: llm.engine))
        let deadlines = DeadlineStore(
            context: persistence.container.mainContext, scheduler: reminders)
        self.deadlines = deadlines
        self.vault = VaultStore(
            context: persistence.container.mainContext,
            fileStore: fileStore,
            deadlines: deadlines,
            scheduler: reminders)
    }

    /// Production container. Falls back to an in-memory store if the on-disk
    /// SwiftData stack can't be opened, so the app still launches (the failure
    /// is logged for diagnosis) rather than crashing on first run.
    static func live() -> AppEnvironment {
        let llm = makeLLM()
        let fileStore = makeFileStore()
        do {
            return AppEnvironment(
                persistence: try PersistenceController(), llm: llm, fileStore: fileStore)
        } catch {
            assertionFailure("Persistent store unavailable, using in-memory: \(error)")
            // `inMemory` cannot realistically fail, but if it does there is no
            // recoverable app state — a crash here is acceptable.
            return AppEnvironment(
                persistence: try! PersistenceController(inMemory: true),
                llm: llm, fileStore: fileStore)
        }
    }

    /// The Keychain-backed encrypted document store (D4/A-09), degrading to a
    /// temp-directory store if Documents is somehow unavailable so the app still
    /// launches; the Vault then surfaces save errors per-action.
    private static func makeFileStore() -> EncryptedFileStore {
        do {
            return try EncryptedFileStore(keyStore: KeychainKeyStore())
        } catch {
            assertionFailure("Document store unavailable, using temp directory: \(error)")
            return try! EncryptedFileStore(
                directory: FileManager.default.temporaryDirectory
                    .appendingPathComponent("AlltagVault", isDirectory: true),
                keyStore: KeychainKeyStore())
        }
    }

    /// Builds the LLM facade, degrading to a temp-directory model store if
    /// Application Support is somehow unavailable — the app must still launch
    /// (model provisioning then surfaces its own readiness UI).
    private static func makeLLM() -> LLMService {
        do {
            return try LLMService.live()
        } catch {
            assertionFailure("LLM store unavailable, using temp directory: \(error)")
            let store = try! ModelStore(
                directory: FileManager.default.temporaryDirectory
                    .appendingPathComponent("AlltagModels", isDirectory: true))
            let provisioner = ModelProvisioner(
                store: store, downloader: URLSessionModelDownloader())
            return LLMService(
                catalog: .v1, store: store, provisioner: provisioner,
                engine: StubLLMEngine(), runtime: .current)
        }
    }
}
