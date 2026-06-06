import Foundation

/// Content model for the Post-arrival checklist (P6-F4).
///
/// Pure, versioned content (keys only, no literals): the ordered sequence of
/// registrations and setups a newly-arrived family works through in their first
/// weeks in Germany — register your address (Anmeldung) first because it gates
/// most of the others, then residence permits, health insurance, a bank account,
/// the tax-ID, Kita / school for the children, Kindergeld, and an Integrationskurs.
///
/// **Information only** (RDG / D9): general orientation, not legal advice. This
/// file carries no logic, only the ordered checklist. Deadlines and procedures
/// vary by city and change over time — re-verify periodically (OQ-1).

/// One ordered post-arrival step: a stable id, a title key and an optional short
/// detail key. Static, informational — not wired to the persisted `ChecklistStore`.
struct PostArrivalStep: Identifiable, Equatable {
    let id: String
    /// Step title.
    let titleKey: String
    /// Optional one-line detail / why-it-matters note.
    let detailKey: String?

    init(id: String, titleKey: String, detailKey: String? = nil) {
        self.id = id
        self.titleKey = titleKey
        self.detailKey = detailKey
    }
}

/// Versioned catalog of the ordered post-arrival checklist (X-06 / AGENTS:
/// content isolated from views). The order is deliberate — **Anmeldung first**,
/// because the Meldebescheinigung and the tax-ID that follows from it gate the
/// bank account, residence permit and most other steps. Re-verify wording and
/// deadlines against official sources periodically (OQ-1).
enum PostArrivalCatalog {

    /// Short "why the order matters" intro note key.
    static let introNoteKey = "tool_post_arrival_order_note"

    /// The ordered first-weeks checklist.
    static let steps: [PostArrivalStep] = [
        PostArrivalStep(
            id: "anmeldung",
            titleKey: "tool_post_arrival_step_anmeldung",
            detailKey: "tool_post_arrival_step_anmeldung_detail"),
        PostArrivalStep(
            id: "residence_permit",
            titleKey: "tool_post_arrival_step_permit",
            detailKey: "tool_post_arrival_step_permit_detail"),
        PostArrivalStep(
            id: "health_insurance",
            titleKey: "tool_post_arrival_step_health",
            detailKey: "tool_post_arrival_step_health_detail"),
        PostArrivalStep(
            id: "bank_account",
            titleKey: "tool_post_arrival_step_bank",
            detailKey: "tool_post_arrival_step_bank_detail"),
        PostArrivalStep(
            id: "tax_id",
            titleKey: "tool_post_arrival_step_tax_id",
            detailKey: "tool_post_arrival_step_tax_id_detail"),
        PostArrivalStep(
            id: "kita_school",
            titleKey: "tool_post_arrival_step_school",
            detailKey: "tool_post_arrival_step_school_detail"),
        PostArrivalStep(
            id: "kindergeld",
            titleKey: "tool_post_arrival_step_kindergeld",
            detailKey: "tool_post_arrival_step_kindergeld_detail"),
        PostArrivalStep(
            id: "integration_course",
            titleKey: "tool_post_arrival_step_integration",
            detailKey: "tool_post_arrival_step_integration_detail"),
    ]
}
