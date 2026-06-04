import Foundation
import Observation
import SwiftUI

/// User-selectable appearance (A-20). "System" follows the device setting.
enum AppTheme: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    var id: String { rawValue }

    /// The `preferredColorScheme` to apply, or `nil` to defer to the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Localization key for the picker label (resolved against the catalog).
    var labelKey: LocalizedStringKey {
        switch self {
        case .system: return "appearance_system"
        case .light: return "appearance_light"
        case .dark: return "appearance_dark"
        }
    }
}

/// Holds and persists the chosen theme (A-20). Observed by the root view, which
/// applies `theme.colorScheme`.
@MainActor
@Observable
final class ThemeController {
    private static let storageKey = "alltag.theme"

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var theme: AppTheme

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.storageKey),
           let stored = AppTheme(rawValue: raw) {
            theme = stored
        } else {
            theme = .system
        }
    }

    func select(_ theme: AppTheme) {
        self.theme = theme
        defaults.set(theme.rawValue, forKey: Self.storageKey)
    }
}
