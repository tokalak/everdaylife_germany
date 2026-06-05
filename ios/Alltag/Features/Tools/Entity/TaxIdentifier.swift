import Foundation

/// Content model for the Tax-ID & Steuernummer organizer (P6-W6).
///
/// Pure, versioned content (keys only, no literals) describing the German tax
/// identifiers a newcomer deals with, plus an ordered organizer checklist. The
/// "organizer" value is in *explaining* the identifiers, an actionable
/// checklist, and live format validation (`TaxIdValidator`) — it never stores
/// the user's actual numbers (D4 privacy).

/// A single German tax identifier the newcomer encounters.
///
/// Each field is a localization key (no literal strings): what it is, where to
/// find / how to get it, and when it is needed.
struct TaxIdentifier: Identifiable, Equatable {
    let id: String
    /// Display title (the identifier's name).
    let titleKey: String
    /// "What it is" explanation.
    let whatKey: String
    /// "Where to find it / how to get it".
    let whereKey: String
    /// "When you need it".
    let whenKey: String
}

/// One ordered step in the organizer checklist (static, informational — not
/// wired to the persisted `ChecklistStore`).
struct TaxIdStep: Identifiable, Equatable {
    let id: String
    let titleKey: String
    let subtitleKey: String
}

/// Versioned catalog of identifiers + checklist (X-06 / AGENTS: content isolated
/// from views). Re-verify wording periodically (OQ-1).
enum TaxIdentifierCatalog {

    /// The identifiers, ordered by how the newcomer meets them:
    /// Steuer-ID (lifelong, automatic), Steuernummer (per activity, via
    /// Finanzamt) and USt-IdNr (VAT ID, businesses only).
    static let identifiers: [TaxIdentifier] = [
        TaxIdentifier(
            id: "steuer_id",
            titleKey: "tool_taxid_id_steuerid_title",
            whatKey: "tool_taxid_id_steuerid_what",
            whereKey: "tool_taxid_id_steuerid_where",
            whenKey: "tool_taxid_id_steuerid_when"),
        TaxIdentifier(
            id: "steuernummer",
            titleKey: "tool_taxid_id_steuernummer_title",
            whatKey: "tool_taxid_id_steuernummer_what",
            whereKey: "tool_taxid_id_steuernummer_where",
            whenKey: "tool_taxid_id_steuernummer_when"),
        TaxIdentifier(
            id: "ust_idnr",
            titleKey: "tool_taxid_id_ustidnr_title",
            whatKey: "tool_taxid_id_ustidnr_what",
            whereKey: "tool_taxid_id_ustidnr_where",
            whenKey: "tool_taxid_id_ustidnr_when"),
    ]

    /// The ordered organizer checklist (static informational steps).
    static let checklist: [TaxIdStep] = [
        TaxIdStep(
            id: "anmeldung",
            titleKey: "tool_taxid_step_anmeldung_title",
            subtitleKey: "tool_taxid_step_anmeldung_subtitle"),
        TaxIdStep(
            id: "await_letter",
            titleKey: "tool_taxid_step_await_letter_title",
            subtitleKey: "tool_taxid_step_await_letter_subtitle"),
        TaxIdStep(
            id: "give_employer",
            titleKey: "tool_taxid_step_give_employer_title",
            subtitleKey: "tool_taxid_step_give_employer_subtitle"),
        TaxIdStep(
            id: "request_steuernummer",
            titleKey: "tool_taxid_step_request_steuernummer_title",
            subtitleKey: "tool_taxid_step_request_steuernummer_subtitle"),
        TaxIdStep(
            id: "keep_safe",
            titleKey: "tool_taxid_step_keep_safe_title",
            subtitleKey: "tool_taxid_step_keep_safe_subtitle"),
    ]
}
