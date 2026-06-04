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

    init(
        persistence: PersistenceController,
        theme: ThemeController = ThemeController(),
        language: LanguageStore = LanguageStore()
    ) {
        self.persistence = persistence
        self.theme = theme
        self.language = language
    }

    /// Production container. Falls back to an in-memory store if the on-disk
    /// SwiftData stack can't be opened, so the app still launches (the failure
    /// is logged for diagnosis) rather than crashing on first run.
    static func live() -> AppEnvironment {
        do {
            return AppEnvironment(persistence: try PersistenceController())
        } catch {
            assertionFailure("Persistent store unavailable, using in-memory: \(error)")
            // `inMemory` cannot realistically fail, but if it does there is no
            // recoverable app state — a crash here is acceptable.
            return AppEnvironment(
                persistence: try! PersistenceController(inMemory: true))
        }
    }
}
