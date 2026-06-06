import Foundation

/// Content model for the Post-study transition checklist (P6-S6).
///
/// Pure, versioned content (keys only, no literals): how an international
/// graduate switches off the student residence permit onto a working / job-seeking
/// route after finishing a German degree — the 18-month job-seeker permit, the
/// switch to a work permit / EU Blue Card, self-employment, and the practical
/// changes (health insurance, Anmeldung, proof of funds) — plus an ordered
/// transition checklist.
///
/// **Information only** (RDG / D9): general orientation, not legal advice. This
/// file carries no logic, only the explainer sections and the checklist.
/// Permit durations and conditions change — re-verify periodically (OQ-1).

/// One explainer section: a heading plus one or more body/bullet blocks (each a
/// localization key).
struct PostStudySection: Identifiable, Equatable {
    let id: String
    /// Section heading.
    let headingKey: String
    /// One or more body / bullet keys, in display order.
    let bodyKeys: [String]
}

/// One ordered transition step (stable id + title key). Static, informational —
/// not wired to the persisted `ChecklistStore`.
struct PostStudyChecklistItem: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// Versioned catalog of explainer sections + the transition checklist (X-06 /
/// AGENTS: content isolated from views). The 18-month job-seeker permit, work
/// allowance and Blue Card route are stable but re-verify wording against the
/// Ausländerbehörde / Auswärtiges Amt periodically (OQ-1).
enum PostStudyCatalog {

    /// The explainer sections, in reading order.
    static let sections: [PostStudySection] = [
        PostStudySection(
            id: "job_seeker_permit",
            headingKey: "tool_post_study_jobseeker_heading",
            bodyKeys: [
                "tool_post_study_jobseeker_body",
                "tool_post_study_jobseeker_before_expiry",
            ]),
        PostStudySection(
            id: "work_during_search",
            headingKey: "tool_post_study_work_heading",
            bodyKeys: [
                "tool_post_study_work_body",
            ]),
        PostStudySection(
            id: "switch_to_work_permit",
            headingKey: "tool_post_study_switch_heading",
            bodyKeys: [
                "tool_post_study_switch_body",
                "tool_post_study_switch_settlement",
            ]),
        PostStudySection(
            id: "self_employment",
            headingKey: "tool_post_study_selfemployment_heading",
            bodyKeys: [
                "tool_post_study_selfemployment_body",
            ]),
        PostStudySection(
            id: "practical_changes",
            headingKey: "tool_post_study_practical_heading",
            bodyKeys: [
                "tool_post_study_practical_health",
                "tool_post_study_practical_anmeldung",
                "tool_post_study_practical_funds",
            ]),
    ]

    /// The ordered transition checklist.
    static let checklist: [PostStudyChecklistItem] = [
        PostStudyChecklistItem(
            id: "note_expiry",
            titleKey: "tool_post_study_check_expiry"),
        PostStudyChecklistItem(
            id: "gather_certificate",
            titleKey: "tool_post_study_check_certificate"),
        PostStudyChecklistItem(
            id: "book_appointment",
            titleKey: "tool_post_study_check_appointment"),
        PostStudyChecklistItem(
            id: "apply_jobseeker",
            titleKey: "tool_post_study_check_apply"),
        PostStudyChecklistItem(
            id: "update_health",
            titleKey: "tool_post_study_check_health"),
        PostStudyChecklistItem(
            id: "switch_permit",
            titleKey: "tool_post_study_check_switch"),
    ]
}
