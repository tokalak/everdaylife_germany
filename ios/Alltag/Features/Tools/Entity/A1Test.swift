import Foundation

/// Content model for the A1 German test booking guide (P6-F2).
///
/// Pure, versioned content (keys only, no literals): an explainer about the
/// basic-German (CEFR A1) test typically required for spouse reunification —
/// what A1 is, why/when you need it, that exemptions exist, the test format,
/// where to take it and how to prepare — plus an ordered booking checklist.
///
/// **Information only** (RDG / D9): general orientation, not legal advice. This
/// file carries no logic, only the explainer sections and the booking steps.
/// Requirements and exemptions vary by case and consulate — re-verify
/// periodically (OQ-1). Brand names (Goethe-Institut, telc, ÖSD) are verbatim.

/// One explainer section: a heading plus one or more body/bullet blocks (each a
/// localization key).
struct A1TestSection: Identifiable, Equatable {
    let id: String
    /// Section heading.
    let headingKey: String
    /// One or more body / bullet keys, in display order.
    let bodyKeys: [String]
}

/// One ordered booking step (stable id + title key). Static, informational —
/// not wired to the persisted `ChecklistStore`.
struct A1TestStep: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// Versioned catalog of explainer sections + the booking checklist (X-06 /
/// AGENTS: content isolated from views). Exam names and exemption rules are
/// reasonably stable but re-verify wording against the Auswärtiges Amt /
/// licensed test centres periodically (OQ-1).
enum A1TestCatalog {

    /// The explainer sections, in reading order.
    static let sections: [A1TestSection] = [
        A1TestSection(
            id: "what_a1_is",
            headingKey: "tool_a1_test_what_heading",
            bodyKeys: [
                "tool_a1_test_what_body",
                "tool_a1_test_what_exams",
            ]),
        A1TestSection(
            id: "why_needed",
            headingKey: "tool_a1_test_why_heading",
            bodyKeys: [
                "tool_a1_test_why_body",
                "tool_a1_test_why_visa",
            ]),
        A1TestSection(
            id: "exemptions",
            headingKey: "tool_a1_test_exemptions_heading",
            bodyKeys: [
                "tool_a1_test_exemptions_body",
                "tool_a1_test_exemptions_examples",
                "tool_a1_test_exemptions_check",
            ]),
        A1TestSection(
            id: "format",
            headingKey: "tool_a1_test_format_heading",
            bodyKeys: [
                "tool_a1_test_format_parts",
                "tool_a1_test_format_pass",
            ]),
        A1TestSection(
            id: "where",
            headingKey: "tool_a1_test_where_heading",
            bodyKeys: [
                "tool_a1_test_where_body",
            ]),
        A1TestSection(
            id: "prepare",
            headingKey: "tool_a1_test_prepare_heading",
            bodyKeys: [
                "tool_a1_test_prepare_body",
            ]),
    ]

    /// The ordered booking checklist.
    static let steps: [A1TestStep] = [
        A1TestStep(
            id: "find_centre",
            titleKey: "tool_a1_test_step_find"),
        A1TestStep(
            id: "register_pay",
            titleKey: "tool_a1_test_step_register"),
        A1TestStep(
            id: "prepare",
            titleKey: "tool_a1_test_step_prepare"),
        A1TestStep(
            id: "bring_id",
            titleKey: "tool_a1_test_step_id"),
        A1TestStep(
            id: "collect_certificate",
            titleKey: "tool_a1_test_step_certificate"),
        A1TestStep(
            id: "submit_with_visa",
            titleKey: "tool_a1_test_step_submit"),
    ]
}
