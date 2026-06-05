import Foundation

/// Content model for the Verpflichtungserklärung explainer (P6-T3).
///
/// Pure, versioned content (keys only, no literals) explaining the German
/// *Verpflichtungserklärung* — a formal "declaration of commitment" in which a
/// person resident in Germany (the **sponsor**) legally promises to cover a
/// visitor's living costs so the visitor can obtain a visa / prove funds.
///
/// **Information only** (RDG / D9): a Verpflichtungserklärung is *legally
/// binding* and consequential — the screen surfaces a legal-severity caution and
/// always routes the user to the responsible authority. This file carries no
/// logic, only the ordered explainer sections and the sponsor's checklist.

/// One explainer section: a heading plus one or more body/bullet blocks (each a
/// localization key).
struct VerpflichtungSection: Identifiable, Equatable {
    let id: String
    /// Section heading.
    let headingKey: String
    /// One or more body / bullet keys, in display order.
    let bodyKeys: [String]
}

/// One item the sponsor brings when applying (stable id + title key). Static,
/// informational — not wired to the persisted `ChecklistStore`.
struct VerpflichtungItem: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// Versioned catalog of explainer sections + the sponsor's checklist (X-06 /
/// AGENTS: content isolated from views). Fees, thresholds and validity change —
/// re-verify periodically against the local Ausländerbehörde (OQ-1).
enum VerpflichtungCatalog {

    /// The explainer sections, in reading order.
    static let sections: [VerpflichtungSection] = [
        VerpflichtungSection(
            id: "what",
            headingKey: "tool_verpflichtung_what_heading",
            bodyKeys: [
                "tool_verpflichtung_what_body",
                "tool_verpflichtung_what_covers",
            ]),
        VerpflichtungSection(
            id: "who",
            headingKey: "tool_verpflichtung_who_heading",
            bodyKeys: [
                "tool_verpflichtung_who_body",
            ]),
        VerpflichtungSection(
            id: "where",
            headingKey: "tool_verpflichtung_where_heading",
            bodyKeys: [
                "tool_verpflichtung_where_body",
            ]),
        VerpflichtungSection(
            id: "proof",
            headingKey: "tool_verpflichtung_proof_heading",
            bodyKeys: [
                "tool_verpflichtung_proof_body",
            ]),
        VerpflichtungSection(
            id: "cost",
            headingKey: "tool_verpflichtung_cost_heading",
            bodyKeys: [
                "tool_verpflichtung_cost_body",
            ]),
        VerpflichtungSection(
            id: "binding",
            headingKey: "tool_verpflichtung_binding_heading",
            bodyKeys: [
                "tool_verpflichtung_binding_body",
            ]),
    ]

    /// What the sponsor brings to the appointment (static checklist).
    static let checklist: [VerpflichtungItem] = [
        VerpflichtungItem(
            id: "id",
            titleKey: "tool_verpflichtung_item_id"),
        VerpflichtungItem(
            id: "income",
            titleKey: "tool_verpflichtung_item_income"),
        VerpflichtungItem(
            id: "housing",
            titleKey: "tool_verpflichtung_item_housing"),
        VerpflichtungItem(
            id: "visitor",
            titleKey: "tool_verpflichtung_item_visitor"),
    ]
}
