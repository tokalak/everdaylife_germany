import Foundation
import SwiftUI

/// The languages Alltag ships, in v1 (D7).
///
/// The full set is fixed from day one so the model, persistence, and RTL
/// plumbing are built once. Only `selectable` is offered in the UI today
/// (German + English); the rest are content-localized near launch (Phase 8) and
/// then flipped on. German is the default/development language.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case de, en, tr, fr, es, it, ar, ru, zh

    var id: String { rawValue }

    /// Default/development language (D7).
    static let `default`: AppLanguage = .de

    /// Languages the user can actually pick today. The others render in the
    /// onboarding list (P2-01) but are enabled in Phase 8.
    static let selectable: [AppLanguage] = [.de, .en]

    var isSelectable: Bool { Self.selectable.contains(self) }

    /// BCP-47 / `Locale` identifier.
    var localeIdentifier: String { rawValue }

    var locale: Locale { Locale(identifier: localeIdentifier) }

    /// Arabic is RTL; everything else LTR. RTL plumbing is built from day one
    /// (A-14, X-02) even though Arabic content lands in Phase 8.
    var isRTL: Bool { self == .ar }

    var layoutDirection: LayoutDirection { isRTL ? .rightToLeft : .leftToRight }

    /// Endonym — shown in its own script so users recognise their language.
    var endonym: String {
        switch self {
        case .de: return "Deutsch"
        case .en: return "English"
        case .tr: return "Türkçe"
        case .fr: return "Français"
        case .es: return "Español"
        case .it: return "Italiano"
        case .ar: return "العربية"
        case .ru: return "Русский"
        case .zh: return "中文"
        }
    }
}
