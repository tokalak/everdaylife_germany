import SwiftUI

/// The five audiences Alltag serves (D2). One is **active** at a time and drives
/// the persona-specific Home, checklist and tools (D1).
///
/// This is the minimal persona model Onboarding needs to write the active
/// persona (P2-02). The fuller engine — preserved "past situations", switching
/// without losing progress (P4-01) — builds on this enum.
enum Persona: String, CaseIterable, Identifiable, Sendable {
    case tourist
    case student
    case worker
    case family
    case resident

    var id: String { rawValue }

    /// Persona name (String Catalog).
    var titleKey: LocalizedStringKey {
        switch self {
        case .tourist:  return "persona_tourist_title"
        case .student:  return "persona_student_title"
        case .worker:   return "persona_worker_title"
        case .family:   return "persona_family_title"
        case .resident: return "persona_resident_title"
        }
    }

    /// One-line "situation" descriptor shown under the title.
    var subtitleKey: LocalizedStringKey {
        switch self {
        case .tourist:  return "persona_tourist_subtitle"
        case .student:  return "persona_student_subtitle"
        case .worker:   return "persona_worker_subtitle"
        case .family:   return "persona_family_subtitle"
        case .resident: return "persona_resident_subtitle"
        }
    }

    var systemImage: String {
        switch self {
        case .tourist:  return "suitcase.fill"
        case .student:  return "graduationcap.fill"
        case .worker:   return "briefcase.fill"
        case .family:   return "figure.2.and.child.holdinghands"
        case .resident: return "key.fill"
        }
    }

    /// Card accent — drawn from the design-system palette (no new tokens).
    var accent: Color {
        switch self {
        case .tourist:  return AppColor.amber
        case .student:  return AppColor.severityLegal
        case .worker:   return AppColor.primary
        case .family:   return AppColor.severityInfo
        case .resident: return AppColor.primaryDeep
        }
    }
}
