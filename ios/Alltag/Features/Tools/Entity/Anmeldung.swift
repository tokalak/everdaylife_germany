import Foundation

/// Content model for the Anmeldung (address registration) guide (P6-S4, shared
/// with the Worker persona).
///
/// Pure, versioned content (keys only, no literals) explaining the German
/// *Anmeldung* — registering your home address at the local Bürgeramt /
/// Einwohnermeldeamt. The Anmeldung is the gateway formality: the resulting
/// *Meldebescheinigung* is needed to get a tax-ID, open many bank accounts, sign
/// contracts and obtain a residence permit.
///
/// **Information only** (RDG / D9): this file carries no logic, only the ordered
/// explainer sections, the documents checklist and the step list. Deadlines,
/// fees and local procedures vary by city — re-verify periodically (OQ-1).

/// One explainer section: a heading plus one or more body/bullet blocks (each a
/// localization key).
struct AnmeldungSection: Identifiable, Equatable {
    let id: String
    /// Section heading.
    let headingKey: String
    /// One or more body / bullet keys, in display order.
    let bodyKeys: [String]
}

/// One document to bring to the appointment (stable id + title + optional hint).
/// Static, informational — not wired to the persisted `ChecklistStore`.
struct AnmeldungDocument: Identifiable, Equatable {
    let id: String
    let titleKey: String
    /// Optional supporting hint (e.g. "this is essential").
    let hintKey: String?

    init(id: String, titleKey: String, hintKey: String? = nil) {
        self.id = id
        self.titleKey = titleKey
        self.hintKey = hintKey
    }
}

/// One ordered step in the how-to (stable id + title key). Static, informational.
struct AnmeldungStep: Identifiable, Equatable {
    let id: String
    let titleKey: String
}

/// Versioned catalog of explainer sections, documents and steps (X-06 / AGENTS:
/// content isolated from views). The 14-day deadline, fees and per-city
/// procedures change — re-verify against the local Bürgeramt (OQ-1).
enum AnmeldungCatalog {

    /// The explainer sections, in reading order.
    static let sections: [AnmeldungSection] = [
        AnmeldungSection(
            id: "what",
            headingKey: "tool_anmeldung_what_heading",
            bodyKeys: [
                "tool_anmeldung_what_body",
                "tool_anmeldung_what_why",
            ]),
        AnmeldungSection(
            id: "deadline",
            headingKey: "tool_anmeldung_deadline_heading",
            bodyKeys: [
                "tool_anmeldung_deadline_body",
            ]),
        AnmeldungSection(
            id: "where",
            headingKey: "tool_anmeldung_where_heading",
            bodyKeys: [
                "tool_anmeldung_where_body",
            ]),
        AnmeldungSection(
            id: "result",
            headingKey: "tool_anmeldung_result_heading",
            bodyKeys: [
                "tool_anmeldung_result_body",
            ]),
    ]

    /// What to bring to the appointment (static checklist). The
    /// Wohnungsgeberbestätigung is the one document people most often forget — it
    /// is flagged as essential.
    static let documents: [AnmeldungDocument] = [
        AnmeldungDocument(
            id: "passport",
            titleKey: "tool_anmeldung_doc_passport"),
        AnmeldungDocument(
            id: "wohnungsgeber",
            titleKey: "tool_anmeldung_doc_wohnungsgeber",
            hintKey: "tool_anmeldung_doc_wohnungsgeber_hint"),
        AnmeldungDocument(
            id: "form",
            titleKey: "tool_anmeldung_doc_form"),
        AnmeldungDocument(
            id: "certificates",
            titleKey: "tool_anmeldung_doc_certificates",
            hintKey: "tool_anmeldung_doc_certificates_hint"),
    ]

    /// The ordered how-to steps.
    static let steps: [AnmeldungStep] = [
        AnmeldungStep(
            id: "book",
            titleKey: "tool_anmeldung_step_book"),
        AnmeldungStep(
            id: "wohnungsgeber",
            titleKey: "tool_anmeldung_step_wohnungsgeber"),
        AnmeldungStep(
            id: "form",
            titleKey: "tool_anmeldung_step_form"),
        AnmeldungStep(
            id: "attend",
            titleKey: "tool_anmeldung_step_attend"),
        AnmeldungStep(
            id: "receive",
            titleKey: "tool_anmeldung_step_receive"),
    ]
}
