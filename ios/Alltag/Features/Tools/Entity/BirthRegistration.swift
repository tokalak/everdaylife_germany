import Foundation

/// Content model for the birth-registration (Standesamt) sub-flow (P6-F7).
///
/// Pure, versioned content (keys only, no literals): a plain-language explainer of
/// what registering a newborn's birth at the *Standesamt* (registry office)
/// involves and the deadline, the documents the parents need to bring, and the
/// ordered follow-up steps that cascade after the birth is registered (health
/// insurance, Kindergeld, residence permit, Anmeldung).
///
/// **Information only** (RDG / D9): general orientation, not legal advice.
/// Exact requirements, deadlines and which documents apply depend on the city's
/// Standesamt and the family's situation, and change over time — re-verify
/// periodically (OQ-1).

/// One explainer section: a heading plus one or more body/bullet blocks (each a
/// localization key).
struct BirthRegistrationSection: Identifiable, Equatable {
    let id: String
    /// Section heading.
    let headingKey: String
    /// One or more body / bullet keys, in display order.
    let bodyKeys: [String]
}

/// One document the parents need (stable id + title key + optional hint key).
/// Static, informational — not wired to the persisted `ChecklistStore`.
struct BirthRegistrationDocument: Identifiable, Equatable {
    let id: String
    let titleKey: String
    /// Optional clarifying note (e.g. certified-translation caveats).
    let hintKey: String?

    init(id: String, titleKey: String, hintKey: String? = nil) {
        self.id = id
        self.titleKey = titleKey
        self.hintKey = hintKey
    }
}

/// One ordered follow-up step (stable id + title key). Static, informational.
struct BirthRegistrationStep: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// Versioned catalog of explainer sections, documents and follow-up steps (X-06 /
/// AGENTS: content isolated from views). Deadlines and document requirements vary
/// by city/situation and change — re-verify against the local Standesamt (OQ-1).
enum BirthRegistrationCatalog {

    /// The explainer sections, in reading order.
    static let sections: [BirthRegistrationSection] = [
        BirthRegistrationSection(
            id: "what",
            headingKey: "tool_birth_reg_what_heading",
            bodyKeys: [
                "tool_birth_reg_what_body",
                "tool_birth_reg_what_notification",
            ]),
        BirthRegistrationSection(
            id: "deadline",
            headingKey: "tool_birth_reg_deadline_heading",
            bodyKeys: [
                "tool_birth_reg_deadline_body",
                "tool_birth_reg_deadline_certificate",
            ]),
    ]

    /// The documents the parents bring to the Standesamt.
    static let documents: [BirthRegistrationDocument] = [
        BirthRegistrationDocument(
            id: "birth_notification",
            titleKey: "tool_birth_reg_doc_notification"),
        BirthRegistrationDocument(
            id: "passports",
            titleKey: "tool_birth_reg_doc_passports"),
        BirthRegistrationDocument(
            id: "marriage_or_birth_certificates",
            titleKey: "tool_birth_reg_doc_marriage",
            hintKey: "tool_birth_reg_doc_marriage_hint"),
        BirthRegistrationDocument(
            id: "meldebescheinigung",
            titleKey: "tool_birth_reg_doc_meldebescheinigung"),
        BirthRegistrationDocument(
            id: "paternity_acknowledgement",
            titleKey: "tool_birth_reg_doc_paternity",
            hintKey: "tool_birth_reg_doc_paternity_hint"),
    ]

    /// The ordered follow-up steps that cascade after the birth.
    static let steps: [BirthRegistrationStep] = [
        BirthRegistrationStep(
            id: "get_notification",
            titleKey: "tool_birth_reg_step_notification"),
        BirthRegistrationStep(
            id: "register_birth",
            titleKey: "tool_birth_reg_step_register"),
        BirthRegistrationStep(
            id: "collect_certificate",
            titleKey: "tool_birth_reg_step_certificate"),
        BirthRegistrationStep(
            id: "health_insurance",
            titleKey: "tool_birth_reg_step_health"),
        BirthRegistrationStep(
            id: "kindergeld",
            titleKey: "tool_birth_reg_step_kindergeld"),
        BirthRegistrationStep(
            id: "residence_permit",
            titleKey: "tool_birth_reg_step_residence"),
        BirthRegistrationStep(
            id: "anmeldung",
            titleKey: "tool_birth_reg_step_anmeldung"),
    ]
}
