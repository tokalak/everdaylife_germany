import Foundation
import Observation

/// Holds and persists the user's **active persona** (D1/P2-02).
///
/// `nil` until the user picks one during onboarding. Mirrors the
/// `LanguageStore`/`ThemeController` pattern (UserDefaults-backed, injected
/// defaults for test isolation). The richer multi-persona model with preserved
/// "past situations" (P4-01) layers on top of this.
@MainActor
@Observable
final class PersonaStore {
    private static let storageKey = "alltag.activePersona"

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var activePersona: Persona?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.storageKey),
           let stored = Persona(rawValue: raw) {
            activePersona = stored
        } else {
            activePersona = nil
        }
    }

    /// True once a persona has been chosen.
    var hasSelection: Bool { activePersona != nil }

    func select(_ persona: Persona) {
        activePersona = persona
        defaults.set(persona.rawValue, forKey: Self.storageKey)
    }
}
