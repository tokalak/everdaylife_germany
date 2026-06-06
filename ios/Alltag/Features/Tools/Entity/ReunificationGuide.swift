import Foundation

/// Content model for the Family-reunification quick guide (P6-R5).
///
/// Pure, versioned content (keys only, no literals): a concise orientation for a
/// settled long-term resident who wants to bring their family to Germany — who
/// they can bring, what they (the sponsor) must show, what the family member
/// needs, and how the process runs — followed by a short ordered step list.
///
/// **Information only** (RDG / D9): general orientation, not legal advice. This
/// is the *quick guide* — the Family persona ships deeper tools (the
/// reunification visa checklist and the sponsor document pack); this file
/// deliberately stays concise and does not duplicate them. Requirements vary by
/// case and consulate — re-verify periodically (OQ-1).

/// One explainer section: a heading plus one or more body/bullet blocks (each a
/// localization key).
struct ReunificationGuideSection: Identifiable, Equatable {
    let id: String
    /// Section heading.
    let headingKey: String
    /// One or more body / bullet keys, in display order.
    let bodyKeys: [String]
}

/// One ordered step (stable id + title key). Static, informational — not wired
/// to the persisted `ChecklistStore`.
struct ReunificationGuideStep: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// Versioned catalog of explainer sections + the step list (X-06 / AGENTS:
/// content isolated from views). The reunification rules are broadly stable but
/// re-verify wording against the Ausländerbehörde / Auswärtiges Amt periodically
/// (OQ-1).
enum ReunificationGuideCatalog {

    /// The explainer sections, in reading order.
    static let sections: [ReunificationGuideSection] = [
        ReunificationGuideSection(
            id: "who_you_can_bring",
            headingKey: "tool_reunification_guide_who_heading",
            bodyKeys: [
                "tool_reunification_guide_who_spouse_children",
                "tool_reunification_guide_who_other_relatives",
            ]),
        ReunificationGuideSection(
            id: "sponsor_requirements",
            headingKey: "tool_reunification_guide_sponsor_heading",
            bodyKeys: [
                "tool_reunification_guide_sponsor_status",
                "tool_reunification_guide_sponsor_income",
                "tool_reunification_guide_sponsor_housing",
            ]),
        ReunificationGuideSection(
            id: "family_member_requirements",
            headingKey: "tool_reunification_guide_member_heading",
            bodyKeys: [
                "tool_reunification_guide_member_german",
                "tool_reunification_guide_member_passport",
                "tool_reunification_guide_member_documents",
            ]),
        ReunificationGuideSection(
            id: "the_process",
            headingKey: "tool_reunification_guide_process_heading",
            bodyKeys: [
                "tool_reunification_guide_process_visa",
                "tool_reunification_guide_process_arrival",
                "tool_reunification_guide_process_work",
            ]),
    ]

    /// The ordered step list.
    static let steps: [ReunificationGuideStep] = [
        ReunificationGuideStep(
            id: "confirm_status",
            titleKey: "tool_reunification_guide_step_confirm"),
        ReunificationGuideStep(
            id: "gather_documents",
            titleKey: "tool_reunification_guide_step_documents"),
        ReunificationGuideStep(
            id: "a1_test",
            titleKey: "tool_reunification_guide_step_a1"),
        ReunificationGuideStep(
            id: "book_visa",
            titleKey: "tool_reunification_guide_step_visa"),
        ReunificationGuideStep(
            id: "after_arrival",
            titleKey: "tool_reunification_guide_step_arrival"),
    ]
}
