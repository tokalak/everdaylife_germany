import Foundation

/// Content model for the Kindergeld (child benefit) application guide (P6-F5).
///
/// Pure, versioned content (keys only, no literals) plus a single yearly-changing
/// figure: a plain-language explainer of *Kindergeld* — the monthly child-benefit
/// payment from the *Familienkasse* (part of the Bundesagentur für Arbeit) — the
/// documents an applicant needs, and the ordered steps to apply.
///
/// **Information only** (RDG / D9): general orientation, not legal/tax advice.
/// Entitlement depends on residence status and individual circumstances, which
/// vary case by case. The monthly amount, age limits and backdating rules change
/// — re-verify periodically (OQ-1).

/// One explainer section: a heading plus one or more body/bullet blocks (each a
/// localization key).
struct KindergeldSection: Identifiable, Equatable {
    let id: String
    /// Section heading.
    let headingKey: String
    /// One or more body / bullet keys, in display order.
    let bodyKeys: [String]
}

/// One document the applicant needs (stable id + title key). Static,
/// informational — not wired to the persisted `ChecklistStore`.
struct KindergeldDocument: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// One ordered application step (stable id + title key). Static, informational.
struct KindergeldStep: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// The Kindergeld monthly amount per child, isolated as yearly data (X-06 /
/// AGENTS), mirroring `BlockedAccountRequirement` / `BlueCardThresholds`.
///
/// The figure is set by law and shown on the screen so parents know roughly what
/// they can expect per child each month. **This figure changes and MUST be
/// re-verified against the Familienkasse / Bundesagentur für Arbeit each year
/// (OQ-1).**
struct KindergeldRate: Equatable {
    let year: Int
    /// Monthly amount paid per child, in EUR.
    let monthlyPerChild: Double

    /// Current (2025) figure: €255 per child per month. Re-verify yearly (OQ-1).
    static let current = KindergeldRate(year: 2025, monthlyPerChild: 255)
}

/// Versioned catalog of explainer sections, documents and steps (X-06 / AGENTS:
/// content isolated from views). The amount, age limits and backdating window
/// change — re-verify against the Familienkasse (OQ-1).
enum KindergeldCatalog {

    /// The explainer sections, in reading order.
    static let sections: [KindergeldSection] = [
        KindergeldSection(
            id: "what",
            headingKey: "tool_kindergeld_what_heading",
            bodyKeys: [
                "tool_kindergeld_what_body",
                "tool_kindergeld_what_status",
            ]),
        KindergeldSection(
            id: "how_much",
            headingKey: "tool_kindergeld_how_much_heading",
            bodyKeys: [
                "tool_kindergeld_how_much_body",
                "tool_kindergeld_how_much_age",
            ]),
        KindergeldSection(
            id: "where",
            headingKey: "tool_kindergeld_where_heading",
            bodyKeys: [
                "tool_kindergeld_where_body",
            ]),
        KindergeldSection(
            id: "when_paid",
            headingKey: "tool_kindergeld_when_heading",
            bodyKeys: [
                "tool_kindergeld_when_body",
                "tool_kindergeld_when_backdate",
            ]),
    ]

    /// The documents the applicant needs to gather.
    static let documents: [KindergeldDocument] = [
        KindergeldDocument(
            id: "application",
            titleKey: "tool_kindergeld_doc_application"),
        KindergeldDocument(
            id: "birth_certificate",
            titleKey: "tool_kindergeld_doc_birth_certificate"),
        KindergeldDocument(
            id: "tax_id",
            titleKey: "tool_kindergeld_doc_tax_id"),
        KindergeldDocument(
            id: "residence_identity",
            titleKey: "tool_kindergeld_doc_residence_identity"),
        KindergeldDocument(
            id: "education_proof",
            titleKey: "tool_kindergeld_doc_education_proof"),
    ]

    /// The ordered application steps.
    static let steps: [KindergeldStep] = [
        KindergeldStep(
            id: "get_tax_ids",
            titleKey: "tool_kindergeld_step_tax_ids"),
        KindergeldStep(
            id: "fill_application",
            titleKey: "tool_kindergeld_step_fill"),
        KindergeldStep(
            id: "attach_documents",
            titleKey: "tool_kindergeld_step_attach"),
        KindergeldStep(
            id: "submit",
            titleKey: "tool_kindergeld_step_submit"),
        KindergeldStep(
            id: "receive",
            titleKey: "tool_kindergeld_step_receive"),
    ]
}
