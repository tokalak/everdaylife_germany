import Foundation

/// Content model for the Freelance registration sub-flow (P6-W7).
///
/// Pure, versioned content (keys only, no literals) describing the two legal
/// forms of self-employment in Germany and the ordered steps to register each.
/// The screen (`FreelanceRegistrationView`) lets the user pick a path and renders
/// the right numbered steps; the engine (`FreelanceRegistrationEngine`) maps a
/// path to its steps. **Information only** (RDG / D9) — never a legal decision.

/// The two legal forms self-employment takes in Germany.
enum FreelancePath: String, CaseIterable, Identifiable {
    /// "Freie Berufe" — catalogue / liberal professions (no Gewerbe, no IHK).
    case freiberufler
    /// A trade business — needs a Gewerbeanmeldung and IHK/HWK membership.
    case gewerbe

    var id: String { rawValue }
    var titleKey: String { "tool_freelance_path_\(rawValue)_title" }
    var subtitleKey: String { "tool_freelance_path_\(rawValue)_subtitle" }
}

/// One ordered step in a registration path (stable id + title + detail key).
struct FreelanceStep: Identifiable, Equatable {
    let id: String
    let titleKey: String
    let detailKey: String
}

/// Versioned catalog of the registration steps for each path (X-06 / AGENTS:
/// content isolated from views and logic). Re-verify wording periodically (OQ-1).
enum FreelanceRegistrationCatalog {

    /// Freiberufler path: no Gewerbeamt and no chamber membership — you register
    /// straight with the Finanzamt via ELSTER.
    static let freiberuflerSteps: [FreelanceStep] = [
        FreelanceStep(
            id: "confirm_freiberufler",
            titleKey: "tool_freelance_fb_confirm_title",
            detailKey: "tool_freelance_fb_confirm_detail"),
        FreelanceStep(
            id: "elster_fragebogen",
            titleKey: "tool_freelance_fb_fragebogen_title",
            detailKey: "tool_freelance_fb_fragebogen_detail"),
        FreelanceStep(
            id: "receive_steuernummer",
            titleKey: "tool_freelance_fb_steuernummer_title",
            detailKey: "tool_freelance_fb_steuernummer_detail"),
        FreelanceStep(
            id: "kleinunternehmer_vat",
            titleKey: "tool_freelance_fb_vat_title",
            detailKey: "tool_freelance_fb_vat_detail"),
        FreelanceStep(
            id: "insurance",
            titleKey: "tool_freelance_fb_insurance_title",
            detailKey: "tool_freelance_fb_insurance_detail"),
        FreelanceStep(
            id: "start_invoicing",
            titleKey: "tool_freelance_fb_invoicing_title",
            detailKey: "tool_freelance_fb_invoicing_detail"),
    ]

    /// Gewerbe path: starts at the Gewerbeamt, which triggers the Finanzamt and
    /// automatic IHK/Handwerkskammer membership.
    static let gewerbeSteps: [FreelanceStep] = [
        FreelanceStep(
            id: "gewerbeanmeldung",
            titleKey: "tool_freelance_gw_anmeldung_title",
            detailKey: "tool_freelance_gw_anmeldung_detail"),
        FreelanceStep(
            id: "finanzamt_fragebogen",
            titleKey: "tool_freelance_gw_fragebogen_title",
            detailKey: "tool_freelance_gw_fragebogen_detail"),
        FreelanceStep(
            id: "chamber_membership",
            titleKey: "tool_freelance_gw_chamber_title",
            detailKey: "tool_freelance_gw_chamber_detail"),
        FreelanceStep(
            id: "receive_steuernummer",
            titleKey: "tool_freelance_gw_steuernummer_title",
            detailKey: "tool_freelance_gw_steuernummer_detail"),
        FreelanceStep(
            id: "vat_gewerbesteuer",
            titleKey: "tool_freelance_gw_taxes_title",
            detailKey: "tool_freelance_gw_taxes_detail"),
        FreelanceStep(
            id: "insurance",
            titleKey: "tool_freelance_gw_insurance_title",
            detailKey: "tool_freelance_gw_insurance_detail"),
    ]
}
