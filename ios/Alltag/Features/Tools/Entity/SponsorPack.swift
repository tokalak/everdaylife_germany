import Foundation

/// Content model for the Sponsor document pack (P6-F3).
///
/// The sponsor-side counterpart to the family-reunification visa checklist
/// (P6-F1): the documents the **sponsor already living in Germany** must prepare
/// to support a family member's reunification application. Grouped by category —
/// identity & status, finances, housing, and the relationship.
///
/// Pure, versioned content (keys only, no literals). **Information only**
/// (RDG / D9): general orientation, not legal advice. Exact requirements vary by
/// Ausländerbehörde / consulate — re-verify periodically (OQ-1).

/// One document item the sponsor assembles: a stable id, a title key and an
/// optional hint key. Static, informational — not wired to the persisted
/// `ChecklistStore`.
struct SponsorDoc: Identifiable, Equatable {
    let id: String
    /// Document title.
    let titleKey: String
    /// Optional clarifying hint (e.g. "legalised/apostilled").
    let hintKey: String?

    init(id: String, titleKey: String, hintKey: String? = nil) {
        self.id = id
        self.titleKey = titleKey
        self.hintKey = hintKey
    }
}

/// One category of documents: a stable id, a heading key and the document items
/// it contains, in display order.
struct SponsorDocGroup: Identifiable, Equatable {
    let id: String
    /// Group heading.
    let headingKey: String
    /// The document items in this group, in display order.
    let documents: [SponsorDoc]
}

/// Versioned catalog of the sponsor's document groups (X-06 / AGENTS: content
/// isolated from views). The categories are stable but re-verify wording against
/// the Ausländerbehörde / Auswärtiges Amt periodically (OQ-1).
enum SponsorPackCatalog {

    /// The document groups, in reading order.
    static let groups: [SponsorDocGroup] = [
        SponsorDocGroup(
            id: "identity_status",
            headingKey: "tool_sponsor_group_identity_heading",
            documents: [
                SponsorDoc(
                    id: "passport",
                    titleKey: "tool_sponsor_doc_passport"),
                SponsorDoc(
                    id: "residence_status",
                    titleKey: "tool_sponsor_doc_residence_status",
                    hintKey: "tool_sponsor_doc_residence_status_hint"),
                SponsorDoc(
                    id: "meldebescheinigung",
                    titleKey: "tool_sponsor_doc_meldebescheinigung",
                    hintKey: "tool_sponsor_doc_meldebescheinigung_hint"),
            ]),
        SponsorDocGroup(
            id: "finances",
            headingKey: "tool_sponsor_group_finances_heading",
            documents: [
                SponsorDoc(
                    id: "payslips",
                    titleKey: "tool_sponsor_doc_payslips",
                    hintKey: "tool_sponsor_doc_payslips_hint"),
                SponsorDoc(
                    id: "employment_contract",
                    titleKey: "tool_sponsor_doc_employment_contract"),
                SponsorDoc(
                    id: "self_employed_income",
                    titleKey: "tool_sponsor_doc_self_employed_income",
                    hintKey: "tool_sponsor_doc_self_employed_income_hint"),
                SponsorDoc(
                    id: "bank_statements",
                    titleKey: "tool_sponsor_doc_bank_statements"),
            ]),
        SponsorDocGroup(
            id: "housing",
            headingKey: "tool_sponsor_group_housing_heading",
            documents: [
                SponsorDoc(
                    id: "rental_contract",
                    titleKey: "tool_sponsor_doc_rental_contract"),
                SponsorDoc(
                    id: "home_size",
                    titleKey: "tool_sponsor_doc_home_size",
                    hintKey: "tool_sponsor_doc_home_size_hint"),
                SponsorDoc(
                    id: "landlord_confirmation",
                    titleKey: "tool_sponsor_doc_landlord_confirmation",
                    hintKey: "tool_sponsor_doc_landlord_confirmation_hint"),
            ]),
        SponsorDocGroup(
            id: "relationship",
            headingKey: "tool_sponsor_group_relationship_heading",
            documents: [
                SponsorDoc(
                    id: "marriage_certificate",
                    titleKey: "tool_sponsor_doc_marriage_certificate",
                    hintKey: "tool_sponsor_doc_marriage_certificate_hint"),
                SponsorDoc(
                    id: "birth_certificate",
                    titleKey: "tool_sponsor_doc_birth_certificate",
                    hintKey: "tool_sponsor_doc_birth_certificate_hint"),
                SponsorDoc(
                    id: "declaration_of_support",
                    titleKey: "tool_sponsor_doc_declaration_of_support",
                    hintKey: "tool_sponsor_doc_declaration_of_support_hint"),
            ]),
    ]
}
