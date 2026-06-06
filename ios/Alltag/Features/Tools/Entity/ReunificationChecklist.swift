import Foundation

/// Content model for the family-reunification (Familiennachzug) visa checklist
/// (P6-F1).
///
/// Pure, versioned content (keys only, no literals): the documents a family member
/// needs to apply for a national (type-D) visa to join a relative living in
/// Germany. Requirements differ by who is joining (spouse / minor child / parent
/// of a minor), so the screen (`ReunificationChecklistView`) lets the user pick the
/// relationship and renders the resulting checklist; the engine
/// (`ReunificationChecklistEngine`) maps a relation to its ordered documents =
/// common + relation-specific. **Information only** (RDG / D9): requirements vary
/// by case and by the responsible German mission — always check the local German
/// embassy/consulate's own site.

/// Who is joining the relative living in Germany. The required documents differ per
/// relation.
enum FamilyRelation: String, CaseIterable, Identifiable {
    /// A spouse joining a resident partner.
    case spouse
    /// A minor child joining parents living in Germany.
    case child
    /// A parent joining their minor child living in Germany.
    case parent

    var id: String { rawValue }
    var titleKey: String { "tool_reunification_relation_\(rawValue)_title" }
    var subtitleKey: String { "tool_reunification_relation_\(rawValue)_subtitle" }
}

/// One document needed for the reunification visa application (stable id + title
/// key + optional hint/detail key with a short clarification).
struct ReunificationDocument: Identifiable, Equatable {
    let id: String
    let titleKey: String
    /// Optional short clarification / detail (e.g. "legalised or apostilled").
    let hintKey: String?

    init(id: String, titleKey: String, hintKey: String? = nil) {
        self.id = id
        self.titleKey = titleKey
        self.hintKey = hintKey
    }
}

/// Versioned catalog of the documents (X-06 / AGENTS: content isolated from views
/// and logic). Requirements vary by case/consulate — re-verify periodically against
/// the Auswärtiges Amt / the local German mission (OQ-1).
enum ReunificationChecklistCatalog {

    /// Documents required for every reunification application, regardless of which
    /// family member is joining.
    static let common: [ReunificationDocument] = [
        ReunificationDocument(
            id: "sponsor_residence",
            titleKey: "tool_reunification_doc_sponsor_residence_title",
            hintKey: "tool_reunification_doc_sponsor_residence_hint"),
        ReunificationDocument(
            id: "passport",
            titleKey: "tool_reunification_doc_passport_title",
            hintKey: "tool_reunification_doc_passport_hint"),
        ReunificationDocument(
            id: "application_form",
            titleKey: "tool_reunification_doc_application_form_title",
            hintKey: "tool_reunification_doc_application_form_hint"),
        ReunificationDocument(
            id: "photos",
            titleKey: "tool_reunification_doc_photos_title",
            hintKey: "tool_reunification_doc_photos_hint"),
        ReunificationDocument(
            id: "income",
            titleKey: "tool_reunification_doc_income_title",
            hintKey: "tool_reunification_doc_income_hint"),
        ReunificationDocument(
            id: "housing",
            titleKey: "tool_reunification_doc_housing_title",
            hintKey: "tool_reunification_doc_housing_hint"),
        ReunificationDocument(
            id: "health_insurance",
            titleKey: "tool_reunification_doc_health_insurance_title",
            hintKey: "tool_reunification_doc_health_insurance_hint"),
    ]

    /// Documents specific to a spouse joining a resident partner.
    static let spouse: [ReunificationDocument] = [
        ReunificationDocument(
            id: "marriage_certificate",
            titleKey: "tool_reunification_doc_marriage_certificate_title",
            hintKey: "tool_reunification_doc_marriage_certificate_hint"),
        ReunificationDocument(
            id: "german_a1",
            titleKey: "tool_reunification_doc_german_a1_title",
            hintKey: "tool_reunification_doc_german_a1_hint"),
        ReunificationDocument(
            id: "age_eighteen",
            titleKey: "tool_reunification_doc_age_eighteen_title",
            hintKey: "tool_reunification_doc_age_eighteen_hint"),
    ]

    /// Documents specific to a minor child joining parents.
    static let child: [ReunificationDocument] = [
        ReunificationDocument(
            id: "birth_certificate",
            titleKey: "tool_reunification_doc_birth_certificate_title",
            hintKey: "tool_reunification_doc_birth_certificate_hint"),
        ReunificationDocument(
            id: "custody",
            titleKey: "tool_reunification_doc_custody_title",
            hintKey: "tool_reunification_doc_custody_hint"),
        ReunificationDocument(
            id: "parents_status",
            titleKey: "tool_reunification_doc_parents_status_title",
            hintKey: "tool_reunification_doc_parents_status_hint"),
    ]

    /// Documents specific to a parent joining their minor child.
    static let parent: [ReunificationDocument] = [
        ReunificationDocument(
            id: "child_is_minor",
            titleKey: "tool_reunification_doc_child_is_minor_title",
            hintKey: "tool_reunification_doc_child_is_minor_hint"),
        ReunificationDocument(
            id: "parent_custody",
            titleKey: "tool_reunification_doc_parent_custody_title",
            hintKey: "tool_reunification_doc_parent_custody_hint"),
        ReunificationDocument(
            id: "parent_restricted",
            titleKey: "tool_reunification_doc_parent_restricted_title",
            hintKey: "tool_reunification_doc_parent_restricted_hint"),
    ]

    /// The relation-specific documents for a given relation.
    static func specific(for relation: FamilyRelation) -> [ReunificationDocument] {
        switch relation {
        case .spouse: return spouse
        case .child:  return child
        case .parent: return parent
        }
    }
}
