import Foundation
import Observation

/// Holds and persists the user's **active persona** plus the set of personas they
/// have ever engaged — their preserved **"past situations"** (D1/P2-02/P4-01).
///
/// One persona is active and drives Home; the others the user has used are kept
/// so switching back is lossless (their checklist progress lives in
/// `ChecklistStore`, keyed by persona, so it is never discarded here). The
/// multi-persona model is forward-looking — V1.1 may surface several at once;
/// V1 surfaces one. UserDefaults-backed with injected defaults for test
/// isolation, mirroring `LanguageStore`/`ThemeController`.
@MainActor
@Observable
final class PersonaStore {
    private static let activeKey = "alltag.activePersona"
    private static let engagedKey = "alltag.engagedPersonas"

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var activePersona: Persona?
    /// Every persona the user has ever selected, in first-seen order — the active
    /// one included. The basis for the "Past situations" UI (P5-05).
    private(set) var engagedPersonas: [Persona]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let active = defaults.string(forKey: Self.activeKey).flatMap(Persona.init(rawValue:))
        self.activePersona = active

        let stored = (defaults.array(forKey: Self.engagedKey) as? [String]) ?? []
        var engaged = stored.compactMap(Persona.init(rawValue:))
        // Heal older installs that have an active persona but no engaged list yet.
        if let active, !engaged.contains(active) { engaged.insert(active, at: 0) }
        self.engagedPersonas = engaged
    }

    /// True once a persona has been chosen.
    var hasSelection: Bool { activePersona != nil }

    /// Personas used before but not currently active — the "past situations".
    var pastPersonas: [Persona] {
        engagedPersonas.filter { $0 != activePersona }
    }

    /// Make `persona` active, recording it among the engaged set the first time
    /// it is seen. Used both by onboarding's first pick (P2-02) and by switching
    /// mode later (P4-01) — switching is lossless because progress is keyed by
    /// persona elsewhere, never cleared here.
    func select(_ persona: Persona) {
        activePersona = persona
        if !engagedPersonas.contains(persona) {
            engagedPersonas.append(persona)
            defaults.set(engagedPersonas.map(\.rawValue), forKey: Self.engagedKey)
        }
        defaults.set(persona.rawValue, forKey: Self.activeKey)
    }
}
