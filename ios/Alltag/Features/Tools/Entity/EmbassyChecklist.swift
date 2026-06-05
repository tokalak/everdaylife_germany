import Foundation

/// Content model for the Embassy document checklist (P6-T2).
///
/// Pure, versioned content (keys only, no literals): the documents to bring to a
/// German embassy/consulate appointment, which depend on what you are applying
/// for. The screen (`EmbassyChecklistView`) lets the user pick a visa purpose and
/// renders the resulting checklist; the engine (`EmbassyChecklistEngine`) maps a
/// purpose to its ordered documents = common + purpose-specific. **Information
/// only** (RDG / D9): requirements vary by country/consulate — always check the
/// local German mission's own site.

/// What the applicant is applying for. The required documents differ per purpose.
enum VisaPurpose: String, CaseIterable, Identifiable {
    /// Schengen short-stay visa (up to 90 days, e.g. tourism / visiting).
    case shortStay
    /// National visa for work / skilled employment.
    case work
    /// National visa for study.
    case study
    /// National visa for family reunification.
    case family

    var id: String { rawValue }
    var titleKey: String { "tool_embassy_purpose_\(rawValue)_title" }
    var subtitleKey: String { "tool_embassy_purpose_\(rawValue)_subtitle" }

    /// Long-stay (national-visa) purposes that lead into living in Germany; these
    /// offer a "learn more" into the residence-permit guide.
    var isLongStay: Bool { self != .shortStay }
}

/// One document to bring to the appointment (stable id + title key + optional
/// hint key with a short clarification).
struct ChecklistDocument: Identifiable, Equatable {
    let id: String
    let titleKey: String
    /// Optional short clarification / hint (e.g. "original + copy").
    let hintKey: String?

    init(id: String, titleKey: String, hintKey: String? = nil) {
        self.id = id
        self.titleKey = titleKey
        self.hintKey = hintKey
    }
}

/// Versioned catalog of the documents (X-06 / AGENTS: content isolated from views
/// and logic). Requirements vary by country/consulate — re-verify periodically
/// against the Auswärtiges Amt / the local German mission (OQ-1).
enum EmbassyChecklistCatalog {

    /// Documents required for every appointment, regardless of purpose.
    static let common: [ChecklistDocument] = [
        ChecklistDocument(
            id: "passport",
            titleKey: "tool_embassy_doc_passport_title",
            hintKey: "tool_embassy_doc_passport_hint"),
        ChecklistDocument(
            id: "application_form",
            titleKey: "tool_embassy_doc_application_form_title",
            hintKey: "tool_embassy_doc_application_form_hint"),
        ChecklistDocument(
            id: "photos",
            titleKey: "tool_embassy_doc_photos_title",
            hintKey: "tool_embassy_doc_photos_hint"),
        ChecklistDocument(
            id: "insurance",
            titleKey: "tool_embassy_doc_insurance_title",
            hintKey: "tool_embassy_doc_insurance_hint"),
        ChecklistDocument(
            id: "funds",
            titleKey: "tool_embassy_doc_funds_title",
            hintKey: "tool_embassy_doc_funds_hint"),
        ChecklistDocument(
            id: "appointment",
            titleKey: "tool_embassy_doc_appointment_title",
            hintKey: nil),
        ChecklistDocument(
            id: "fee",
            titleKey: "tool_embassy_doc_fee_title",
            hintKey: "tool_embassy_doc_fee_hint"),
    ]

    /// Documents specific to a Schengen short stay.
    static let shortStay: [ChecklistDocument] = [
        ChecklistDocument(
            id: "travel_itinerary",
            titleKey: "tool_embassy_doc_travel_itinerary_title",
            hintKey: "tool_embassy_doc_travel_itinerary_hint"),
        ChecklistDocument(
            id: "invitation",
            titleKey: "tool_embassy_doc_invitation_title",
            hintKey: "tool_embassy_doc_invitation_hint"),
    ]

    /// Documents specific to a national work visa.
    static let work: [ChecklistDocument] = [
        ChecklistDocument(
            id: "employment_contract",
            titleKey: "tool_embassy_doc_employment_contract_title",
            hintKey: "tool_embassy_doc_employment_contract_hint"),
        ChecklistDocument(
            id: "qualification",
            titleKey: "tool_embassy_doc_qualification_title",
            hintKey: "tool_embassy_doc_qualification_hint"),
        ChecklistDocument(
            id: "cv",
            titleKey: "tool_embassy_doc_cv_title",
            hintKey: nil),
    ]

    /// Documents specific to a national study visa.
    static let study: [ChecklistDocument] = [
        ChecklistDocument(
            id: "admission_letter",
            titleKey: "tool_embassy_doc_admission_letter_title",
            hintKey: "tool_embassy_doc_admission_letter_hint"),
        ChecklistDocument(
            id: "blocked_account",
            titleKey: "tool_embassy_doc_blocked_account_title",
            hintKey: "tool_embassy_doc_blocked_account_hint"),
    ]

    /// Documents specific to a family-reunification visa.
    static let family: [ChecklistDocument] = [
        ChecklistDocument(
            id: "civil_certificate",
            titleKey: "tool_embassy_doc_civil_certificate_title",
            hintKey: "tool_embassy_doc_civil_certificate_hint"),
        ChecklistDocument(
            id: "sponsor_residence",
            titleKey: "tool_embassy_doc_sponsor_residence_title",
            hintKey: "tool_embassy_doc_sponsor_residence_hint"),
        ChecklistDocument(
            id: "german_a1",
            titleKey: "tool_embassy_doc_german_a1_title",
            hintKey: "tool_embassy_doc_german_a1_hint"),
    ]

    /// The purpose-specific documents for a given purpose.
    static func specific(for purpose: VisaPurpose) -> [ChecklistDocument] {
        switch purpose {
        case .shortStay: return shortStay
        case .work:      return work
        case .study:     return study
        case .family:    return family
        }
    }
}
