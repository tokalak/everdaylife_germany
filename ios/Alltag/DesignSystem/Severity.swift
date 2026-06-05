import SwiftUI

/// The four-level severity system reused across Decoder, Dates and Vault
/// (DS-01). A pure, testable mapping from a severity to its tokens: foreground
/// color, wash background, SF Symbol, and a localized label key.
///
/// Living in the DesignSystem (not a feature) keeps the visual language
/// consistent everywhere a severity is shown.
enum Severity: String, CaseIterable, Identifiable, Sendable, Codable, Equatable {
    case info       // neutral, FYI
    case action     // needs the user to do something
    case urgent     // time-critical / overdue risk
    case legal      // legally consequential — route to a lawyer (RDG)

    var id: String { rawValue }

    /// The accent / foreground color for this severity.
    var color: Color {
        switch self {
        case .info:   return AppColor.severityInfo
        case .action: return AppColor.severityAction
        case .urgent: return AppColor.severityUrgent
        case .legal:  return AppColor.severityLegal
        }
    }

    /// The tinted background ("wash") that pairs with `color`.
    var wash: Color {
        switch self {
        case .info:   return AppColor.severityInfoWash
        case .action: return AppColor.severityActionWash
        case .urgent: return AppColor.severityUrgentWash
        case .legal:  return AppColor.severityLegalWash
        }
    }

    /// SF Symbol representing the severity.
    var symbol: String {
        switch self {
        case .info:   return "info.circle.fill"
        case .action: return "bolt.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        case .legal:  return "building.columns.fill"
        }
    }

    /// Localized label key (resolved against the String Catalog).
    var labelKey: LocalizedStringKey {
        switch self {
        case .info:   return "severity_info"
        case .action: return "severity_action"
        case .urgent: return "severity_urgent"
        case .legal:  return "severity_legal"
        }
    }
}
