import SwiftUI

/// The five top-level destinations (IA decision D10):
/// **Home · Docs · Decode (center) · Dates · Settings**.
///
/// Modeled as a type (rather than inline in the `TabView`) so the set is
/// testable and the ordering — Decode deliberately in the center — is explicit.
enum AppTab: String, CaseIterable, Identifiable {
    case home, docs, decode, dates, settings

    var id: String { rawValue }

    /// Localization key for the tab title (String Catalog).
    var titleKey: LocalizedStringKey {
        switch self {
        case .home: return "tab_home"
        case .docs: return "tab_docs"
        case .decode: return "tab_decode"
        case .dates: return "tab_dates"
        case .settings: return "tab_settings"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .docs: return "folder"
        case .decode: return "doc.text.viewfinder" // the camera/decode anchor
        case .dates: return "calendar"
        case .settings: return "gearshape"
        }
    }
}
