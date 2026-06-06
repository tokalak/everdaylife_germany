import Foundation

/// Content model for the Kita/school enrollment basics tool (P6-F6).
///
/// Pure, versioned content (keys only, no literals): orients newcomer parents to
/// German childcare (Krippe / Kindergarten / Kita) and schooling (Schulpflicht,
/// Grundschule, the secondary school types, Willkommensklassen) — a clear
/// explainer plus an ordered practical-steps list.
///
/// **Information only** (RDG / D9): general orientation, not legal advice.
/// Childcare and school rules vary by Bundesland and municipality — re-verify
/// periodically (OQ-1). This file carries no logic, only the explainer sections
/// and the steps.

/// One explainer section: a heading plus one or more body/bullet blocks (each a
/// localization key).
struct KitaSchoolSection: Identifiable, Equatable {
    let id: String
    /// Section heading.
    let headingKey: String
    /// One or more body / bullet keys, in display order.
    let bodyKeys: [String]
}

/// One ordered practical step (stable id + title key). Static, informational —
/// not wired to the persisted `ChecklistStore`.
struct KitaSchoolStep: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// Versioned catalog of explainer sections + the practical steps (X-06 /
/// AGENTS: content isolated from views). The legal childcare entitlement and the
/// school-type split are stable but details (fees, vouchers, school types) vary
/// by Bundesland / municipality — re-verify periodically (OQ-1).
enum KitaSchoolCatalog {

    /// The explainer sections, in reading order.
    static let sections: [KitaSchoolSection] = [
        KitaSchoolSection(
            id: "childcare_stages",
            headingKey: "tool_kita_stages_heading",
            bodyKeys: [
                "tool_kita_stages_krippe",
                "tool_kita_stages_kindergarten",
                "tool_kita_stages_entitlement",
            ]),
        KitaSchoolSection(
            id: "applying_for_place",
            headingKey: "tool_kita_apply_heading",
            bodyKeys: [
                "tool_kita_apply_early",
                "tool_kita_apply_gutschein",
                "tool_kita_apply_fees",
            ]),
        KitaSchoolSection(
            id: "compulsory_school",
            headingKey: "tool_kita_school_heading",
            bodyKeys: [
                "tool_kita_school_age",
                "tool_kita_school_enrol",
            ]),
        KitaSchoolSection(
            id: "school_types",
            headingKey: "tool_kita_types_heading",
            bodyKeys: [
                "tool_kita_types_split",
                "tool_kita_types_varies",
            ]),
        KitaSchoolSection(
            id: "newcomer_support",
            headingKey: "tool_kita_support_heading",
            bodyKeys: [
                "tool_kita_support_classes",
            ]),
    ]

    /// The ordered practical steps.
    static let steps: [KitaSchoolStep] = [
        KitaSchoolStep(
            id: "register_address",
            titleKey: "tool_kita_step_anmeldung"),
        KitaSchoolStep(
            id: "research_options",
            titleKey: "tool_kita_step_research"),
        KitaSchoolStep(
            id: "apply_kita",
            titleKey: "tool_kita_step_apply"),
        KitaSchoolStep(
            id: "contact_school",
            titleKey: "tool_kita_step_school"),
        KitaSchoolStep(
            id: "ask_support",
            titleKey: "tool_kita_step_support"),
    ]
}
