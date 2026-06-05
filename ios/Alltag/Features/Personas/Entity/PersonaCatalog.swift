import SwiftUI

/// Versioned content for each persona's Home: the checklist steps, the "Tools
/// for your mode" grid, and the cross-persona guides (X-06 — isolated here so
/// copy/order can change without touching views or logic; P4-03/04).
///
/// **Worker is fully populated** (Phase 4, the deepest persona). The other four
/// personas return empty checklists/tools for now and are filled in **Phase 5**;
/// the **guides are cross-persona** and already ship all five (P6-G1…G5). The
/// interactive tool engines and the guide reader are **Phase 6** — the entries
/// here render the tiles and carry deep-links, nothing more.
///
/// `@MainActor` because the content holds `LocalizedStringKey`s (not `Sendable`)
/// and is only ever read from the main actor (stores + views).
@MainActor
enum PersonaCatalog {

    /// Ordered checklist steps for a persona. Empty until the persona is built.
    static func checklist(for persona: Persona) -> [ChecklistItem] {
        switch persona {
        case .worker: return workerChecklist
        case .tourist, .student, .family, .resident: return []
        }
    }

    /// "Tools for your mode" grid for a persona. Empty until the persona is built.
    static func tools(for persona: Persona) -> [PersonaTool] {
        switch persona {
        case .worker: return workerTools
        case .tourist, .student, .family, .resident: return []
        }
    }

    /// The five cross-persona guides shown to everyone (P6-G1…G5).
    static let guides: [Guide] = [
        Guide(id: "residence_permit",
              titleKey: "guide_residence_permit_title",
              subtitleKey: "guide_residence_permit_subtitle",
              systemImage: "doc.text.fill", tint: AppColor.severityLegal),
        Guide(id: "register_business",
              titleKey: "guide_register_business_title",
              subtitleKey: "guide_register_business_subtitle",
              systemImage: "storefront.fill", tint: AppColor.primary),
        Guide(id: "how_taxes_work",
              titleKey: "guide_taxes_title",
              subtitleKey: "guide_taxes_subtitle",
              systemImage: "eurosign.circle.fill", tint: AppColor.amber),
        Guide(id: "health_insurance",
              titleKey: "guide_health_title",
              subtitleKey: "guide_health_subtitle",
              systemImage: "cross.case.fill", tint: AppColor.severityInfo),
        Guide(id: "diploma_recognition",
              titleKey: "guide_diploma_title",
              subtitleKey: "guide_diploma_subtitle",
              systemImage: "graduationcap.fill", tint: AppColor.primaryDeep),
    ]

    // MARK: - Worker (P4-03 / P4-04)

    /// Worker / freelancer "settling in" checklist. Order reflects the real
    /// sequence (you register your address before most else follows).
    private static let workerChecklist: [ChecklistItem] = [
        ChecklistItem(
            id: "anmeldung",
            titleKey: "checklist_worker_anmeldung_title",
            subtitleKey: "checklist_worker_anmeldung_subtitle"),
        ChecklistItem(
            id: "bank_account",
            titleKey: "checklist_worker_bank_title",
            subtitleKey: "checklist_worker_bank_subtitle",
            link: .tool("bank_compare")),
        ChecklistItem(
            id: "health_insurance",
            titleKey: "checklist_worker_health_title",
            subtitleKey: "checklist_worker_health_subtitle",
            link: .tool("health_decision")),
        ChecklistItem(
            id: "tax_id",
            titleKey: "checklist_worker_taxid_title",
            subtitleKey: "checklist_worker_taxid_subtitle",
            link: .tool("tax_id_organizer")),
        ChecklistItem(
            id: "freelance_registration",
            titleKey: "checklist_worker_freelance_title",
            subtitleKey: "checklist_worker_freelance_subtitle",
            link: .guide("register_business")),
        ChecklistItem(
            id: "liability_insurance",
            titleKey: "checklist_worker_liability_title",
            subtitleKey: "checklist_worker_liability_subtitle"),
        ChecklistItem(
            id: "broadcast_fee",
            titleKey: "checklist_worker_broadcast_title",
            subtitleKey: "checklist_worker_broadcast_subtitle"),
    ]

    /// Worker tool grid (prototype parity). Engines land in Phase 6 (P6-W*).
    private static let workerTools: [PersonaTool] = [
        PersonaTool(
            id: "visa_fit",
            titleKey: "tool_visa_fit_title",
            subtitleKey: "tool_visa_fit_subtitle",
            systemImage: "location.north.circle.fill",
            tint: AppColor.primary),
        PersonaTool(
            id: "blue_card",
            titleKey: "tool_blue_card_title",
            subtitleKey: "tool_blue_card_subtitle",
            systemImage: "creditcard.fill",
            tint: AppColor.severityLegal),
        PersonaTool(
            id: "chancenkarte",
            titleKey: "tool_chancenkarte_title",
            subtitleKey: "tool_chancenkarte_subtitle",
            systemImage: "target",
            tint: AppColor.primaryDeep,
            badgeKey: "tool_badge_try_it"),
        PersonaTool(
            id: "bank_compare",
            titleKey: "tool_bank_title",
            subtitleKey: "tool_bank_subtitle",
            systemImage: "building.columns.fill",
            tint: AppColor.amber),
        PersonaTool(
            id: "health_decision",
            titleKey: "tool_health_title",
            subtitleKey: "tool_health_subtitle",
            systemImage: "cross.case.fill",
            tint: AppColor.severityInfo),
        PersonaTool(
            id: "tax_id_organizer",
            titleKey: "tool_taxid_title",
            subtitleKey: "tool_taxid_subtitle",
            systemImage: "doc.plaintext.fill",
            tint: AppColor.severityUrgent),
    ]
}
