import Foundation

/// Classifies a nationality into its student entry route and supplies the
/// matching pre-arrival checklist (P6-S1).
///
/// Pure, exhaustively tested logic (A-05) over injected, versioned memberships
/// (`StudentPrearrivalData`). Codes are normalized (trimmed + uppercased).
/// EU/EEA/Switzerland → `freeMovement`; the §41 AufenthV privileged set →
/// `visaFreeEntryThenPermit`; everything else (including unknown codes) →
/// `nationalVisaRequired`. The ordered checklists are versioned content (keys
/// only). **Information only** — the screen carries the RDG note.
enum StudentPrearrivalEngine {

    /// The entry route for a nationality (ISO 3166-1 alpha-2 region code).
    static func route(
        for regionCode: String,
        data: StudentPrearrivalData = .current
    ) -> StudentEntryRoute {
        let code = regionCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if data.freeMovement.contains(code) { return .freeMovement }
        if data.privileged.contains(code) { return .visaFreeEntryThenPermit }
        return .nationalVisaRequired
    }

    /// The ordered pre-arrival checklist for a route.
    static func steps(for route: StudentEntryRoute) -> [PrearrivalStep] {
        switch route {
        case .freeMovement:           return freeMovementSteps
        case .visaFreeEntryThenPermit: return visaFreeEntrySteps
        case .nationalVisaRequired:   return nationalVisaSteps
        }
    }

    // MARK: - Versioned checklists (keys only; X-06 — isolated from views/logic)

    /// EU/EEA/Switzerland: no visa, no permit — just enrol, register and insure.
    private static let freeMovementSteps: [PrearrivalStep] = [
        PrearrivalStep(
            id: "fm_passport",
            titleKey: "tool_prearrival_fm_passport_title",
            detailKey: "tool_prearrival_fm_passport_detail"),
        PrearrivalStep(
            id: "fm_admission",
            titleKey: "tool_prearrival_fm_admission_title",
            detailKey: "tool_prearrival_fm_admission_detail"),
        PrearrivalStep(
            id: "fm_health",
            titleKey: "tool_prearrival_fm_health_title",
            detailKey: "tool_prearrival_fm_health_detail"),
        PrearrivalStep(
            id: "fm_accommodation",
            titleKey: "tool_prearrival_fm_accommodation_title",
            detailKey: "tool_prearrival_fm_accommodation_detail"),
        PrearrivalStep(
            id: "fm_anmeldung",
            titleKey: "tool_prearrival_fm_anmeldung_title",
            detailKey: "tool_prearrival_fm_anmeldung_detail"),
        PrearrivalStep(
            id: "fm_enroll",
            titleKey: "tool_prearrival_fm_enroll_title",
            detailKey: "tool_prearrival_fm_enroll_detail"),
        PrearrivalStep(
            id: "fm_bank",
            titleKey: "tool_prearrival_fm_bank_title",
            detailKey: "tool_prearrival_fm_bank_detail"),
    ]

    /// §41 AufenthV privileged: enter visa-free, apply for the permit after arrival.
    private static let visaFreeEntrySteps: [PrearrivalStep] = [
        PrearrivalStep(
            id: "vf_passport",
            titleKey: "tool_prearrival_vf_passport_title",
            detailKey: "tool_prearrival_vf_passport_detail"),
        PrearrivalStep(
            id: "vf_admission",
            titleKey: "tool_prearrival_vf_admission_title",
            detailKey: "tool_prearrival_vf_admission_detail"),
        PrearrivalStep(
            id: "vf_blocked_account",
            titleKey: "tool_prearrival_vf_blocked_title",
            detailKey: "tool_prearrival_vf_blocked_detail"),
        PrearrivalStep(
            id: "vf_health",
            titleKey: "tool_prearrival_vf_health_title",
            detailKey: "tool_prearrival_vf_health_detail"),
        PrearrivalStep(
            id: "vf_fees",
            titleKey: "tool_prearrival_vf_fees_title",
            detailKey: "tool_prearrival_vf_fees_detail"),
        PrearrivalStep(
            id: "vf_permit_appointment",
            titleKey: "tool_prearrival_vf_permit_title",
            detailKey: "tool_prearrival_vf_permit_detail"),
        PrearrivalStep(
            id: "vf_anmeldung",
            titleKey: "tool_prearrival_vf_anmeldung_title",
            detailKey: "tool_prearrival_vf_anmeldung_detail"),
        PrearrivalStep(
            id: "vf_enroll",
            titleKey: "tool_prearrival_vf_enroll_title",
            detailKey: "tool_prearrival_vf_enroll_detail"),
    ]

    /// Everyone else: get the national student/applicant visa before travelling.
    private static let nationalVisaSteps: [PrearrivalStep] = [
        PrearrivalStep(
            id: "nv_visa",
            titleKey: "tool_prearrival_nv_visa_title",
            detailKey: "tool_prearrival_nv_visa_detail"),
        PrearrivalStep(
            id: "nv_blocked_account",
            titleKey: "tool_prearrival_nv_blocked_title",
            detailKey: "tool_prearrival_nv_blocked_detail"),
        PrearrivalStep(
            id: "nv_admission",
            titleKey: "tool_prearrival_nv_admission_title",
            detailKey: "tool_prearrival_nv_admission_detail"),
        PrearrivalStep(
            id: "nv_health",
            titleKey: "tool_prearrival_nv_health_title",
            detailKey: "tool_prearrival_nv_health_detail"),
        PrearrivalStep(
            id: "nv_translations",
            titleKey: "tool_prearrival_nv_translations_title",
            detailKey: "tool_prearrival_nv_translations_detail"),
        PrearrivalStep(
            id: "nv_anmeldung",
            titleKey: "tool_prearrival_nv_anmeldung_title",
            detailKey: "tool_prearrival_nv_anmeldung_detail"),
        PrearrivalStep(
            id: "nv_permit",
            titleKey: "tool_prearrival_nv_permit_title",
            detailKey: "tool_prearrival_nv_permit_detail"),
        PrearrivalStep(
            id: "nv_enroll",
            titleKey: "tool_prearrival_nv_enroll_title",
            detailKey: "tool_prearrival_nv_enroll_detail"),
    ]
}
