import SwiftUI

/// Versioned content for each persona's Home: the checklist steps, the "Tools
/// for your mode" grid, and the cross-persona guides (X-06 — isolated here so
/// copy/order can change without touching views or logic; P4-03/04).
///
/// All five personas are populated (Worker in Phase 4 — the deepest — and
/// Tourist/Student/Family/Resident in **Phase 5**, P5-01…04). The **guides are
/// cross-persona** and ship all five (P6-G1…G5). The interactive tool engines and
/// the guide reader are **Phase 6** — the entries here render the tiles and carry
/// deep-links, nothing more.
///
/// `@MainActor` because the content holds `LocalizedStringKey`s (not `Sendable`)
/// and is only ever read from the main actor (stores + views).
@MainActor
enum PersonaCatalog {

    /// Ordered checklist steps for a persona.
    static func checklist(for persona: Persona) -> [ChecklistItem] {
        switch persona {
        case .worker:   return workerChecklist
        case .tourist:  return touristChecklist
        case .student:  return studentChecklist
        case .family:   return familyChecklist
        case .resident: return residentChecklist
        }
    }

    /// "Tools for your mode" grid for a persona.
    static func tools(for persona: Persona) -> [PersonaTool] {
        switch persona {
        case .worker:   return workerTools
        case .tourist:  return touristTools
        case .student:  return studentTools
        case .family:   return familyTools
        case .resident: return residentTools
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
            link: .tool("freelance_registration")),
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
        PersonaTool(
            id: "freelance_registration",
            titleKey: "tool_freelance_title",
            subtitleKey: "tool_freelance_subtitle",
            systemImage: "doc.badge.plus",
            tint: AppColor.primaryDeep),
    ]

    // MARK: - Tourist (P5-01)

    /// Short visit / Schengen-stay flow: visa → documents → insurance → keep
    /// inside the 90-in-180 limit.
    private static let touristChecklist: [ChecklistItem] = [
        ChecklistItem(
            id: "tourist_visa_check",
            titleKey: "checklist_tourist_visa_title",
            subtitleKey: "checklist_tourist_visa_subtitle",
            link: .tool("visa_need")),
        ChecklistItem(
            id: "tourist_documents",
            titleKey: "checklist_tourist_documents_title",
            subtitleKey: "checklist_tourist_documents_subtitle",
            link: .tool("embassy_checklist")),
        ChecklistItem(
            id: "tourist_insurance",
            titleKey: "checklist_tourist_insurance_title",
            subtitleKey: "checklist_tourist_insurance_subtitle",
            link: .tool("travel_insurance")),
        ChecklistItem(
            id: "tourist_schengen",
            titleKey: "checklist_tourist_schengen_title",
            subtitleKey: "checklist_tourist_schengen_subtitle",
            link: .tool("schengen_counter")),
        ChecklistItem(
            id: "tourist_survival_kit",
            titleKey: "checklist_tourist_kit_title",
            subtitleKey: "checklist_tourist_kit_subtitle",
            link: .tool("survival_kit")),
        ChecklistItem(
            id: "tourist_emergency",
            titleKey: "checklist_tourist_emergency_title",
            subtitleKey: "checklist_tourist_emergency_subtitle"),
    ]

    private static let touristTools: [PersonaTool] = [
        PersonaTool(
            id: "visa_need",
            titleKey: "tool_visa_need_title",
            subtitleKey: "tool_visa_need_subtitle",
            systemImage: "airplane.circle.fill",
            tint: AppColor.primary),
        PersonaTool(
            id: "embassy_checklist",
            titleKey: "tool_embassy_title",
            subtitleKey: "tool_embassy_subtitle",
            systemImage: "building.2.fill",
            tint: AppColor.severityLegal),
        PersonaTool(
            id: "verpflichtungserklaerung",
            titleKey: "tool_verpflichtung_title",
            subtitleKey: "tool_verpflichtung_subtitle",
            systemImage: "signature",
            tint: AppColor.primaryDeep),
        PersonaTool(
            id: "travel_insurance",
            titleKey: "tool_travel_insurance_title",
            subtitleKey: "tool_travel_insurance_subtitle",
            systemImage: "cross.case.fill",
            tint: AppColor.severityInfo),
        PersonaTool(
            id: "schengen_counter",
            titleKey: "tool_schengen_title",
            subtitleKey: "tool_schengen_subtitle",
            systemImage: "calendar.badge.clock",
            tint: AppColor.amber),
        PersonaTool(
            id: "survival_kit",
            titleKey: "tool_survival_kit_title",
            subtitleKey: "tool_survival_kit_subtitle",
            systemImage: "backpack.fill",
            tint: AppColor.severityUrgent),
    ]

    // MARK: - Student (P5-02)

    /// Study flow: blocked account + health cover gate the visa; then register,
    /// enrol, get the residence permit and stay within the work-hours limit.
    private static let studentChecklist: [ChecklistItem] = [
        ChecklistItem(
            id: "student_blocked_account",
            titleKey: "checklist_student_blocked_title",
            subtitleKey: "checklist_student_blocked_subtitle",
            link: .tool("blocked_account")),
        ChecklistItem(
            id: "student_health",
            titleKey: "checklist_student_health_title",
            subtitleKey: "checklist_student_health_subtitle",
            link: .tool("student_health")),
        ChecklistItem(
            id: "student_anmeldung",
            titleKey: "checklist_student_anmeldung_title",
            subtitleKey: "checklist_student_anmeldung_subtitle",
            link: .tool("anmeldung_guide")),
        ChecklistItem(
            id: "student_enroll",
            titleKey: "checklist_student_enroll_title",
            subtitleKey: "checklist_student_enroll_subtitle"),
        ChecklistItem(
            id: "student_residence_permit",
            titleKey: "checklist_student_permit_title",
            subtitleKey: "checklist_student_permit_subtitle",
            link: .guide("residence_permit")),
        ChecklistItem(
            id: "student_working_hours",
            titleKey: "checklist_student_hours_title",
            subtitleKey: "checklist_student_hours_subtitle",
            link: .tool("working_hours")),
    ]

    private static let studentTools: [PersonaTool] = [
        PersonaTool(
            id: "prearrival_nationality",
            titleKey: "tool_prearrival_title",
            subtitleKey: "tool_prearrival_subtitle",
            systemImage: "globe.europe.africa.fill",
            tint: AppColor.primary),
        PersonaTool(
            id: "blocked_account",
            titleKey: "tool_blocked_title",
            subtitleKey: "tool_blocked_subtitle",
            systemImage: "lock.fill",
            tint: AppColor.amber),
        PersonaTool(
            id: "student_health",
            titleKey: "tool_student_health_title",
            subtitleKey: "tool_student_health_subtitle",
            systemImage: "cross.case.fill",
            tint: AppColor.severityInfo),
        PersonaTool(
            id: "anmeldung_guide",
            titleKey: "tool_anmeldung_title",
            subtitleKey: "tool_anmeldung_subtitle",
            systemImage: "house.fill",
            tint: AppColor.primaryDeep),
        PersonaTool(
            id: "working_hours",
            titleKey: "tool_working_hours_title",
            subtitleKey: "tool_working_hours_subtitle",
            systemImage: "clock.fill",
            tint: AppColor.severityLegal),
        PersonaTool(
            id: "post_study",
            titleKey: "tool_post_study_title",
            subtitleKey: "tool_post_study_subtitle",
            systemImage: "arrow.up.forward.circle.fill",
            tint: AppColor.severityUrgent),
    ]

    // MARK: - Family (P5-03)

    /// Family-reunification flow: visa + A1 + sponsor pack abroad, then register
    /// and set up child benefits / childcare after arrival.
    private static let familyChecklist: [ChecklistItem] = [
        ChecklistItem(
            id: "family_visa",
            titleKey: "checklist_family_visa_title",
            subtitleKey: "checklist_family_visa_subtitle",
            link: .tool("reunification_visa")),
        ChecklistItem(
            id: "family_a1",
            titleKey: "checklist_family_a1_title",
            subtitleKey: "checklist_family_a1_subtitle",
            link: .tool("a1_test")),
        ChecklistItem(
            id: "family_sponsor",
            titleKey: "checklist_family_sponsor_title",
            subtitleKey: "checklist_family_sponsor_subtitle",
            link: .tool("sponsor_pack")),
        ChecklistItem(
            id: "family_anmeldung",
            titleKey: "checklist_family_anmeldung_title",
            subtitleKey: "checklist_family_anmeldung_subtitle"),
        ChecklistItem(
            id: "family_kindergeld",
            titleKey: "checklist_family_kindergeld_title",
            subtitleKey: "checklist_family_kindergeld_subtitle",
            link: .tool("kindergeld")),
        ChecklistItem(
            id: "family_kita",
            titleKey: "checklist_family_kita_title",
            subtitleKey: "checklist_family_kita_subtitle",
            link: .tool("kita_school")),
    ]

    private static let familyTools: [PersonaTool] = [
        PersonaTool(
            id: "reunification_visa",
            titleKey: "tool_reunification_title",
            subtitleKey: "tool_reunification_subtitle",
            systemImage: "person.2.fill",
            tint: AppColor.primary),
        PersonaTool(
            id: "a1_test",
            titleKey: "tool_a1_test_title",
            subtitleKey: "tool_a1_test_subtitle",
            systemImage: "character.book.closed.fill",
            tint: AppColor.severityLegal),
        PersonaTool(
            id: "sponsor_pack",
            titleKey: "tool_sponsor_title",
            subtitleKey: "tool_sponsor_subtitle",
            systemImage: "folder.fill",
            tint: AppColor.primaryDeep),
        PersonaTool(
            id: "post_arrival",
            titleKey: "tool_post_arrival_title",
            subtitleKey: "tool_post_arrival_subtitle",
            systemImage: "checklist",
            tint: AppColor.severityInfo),
        PersonaTool(
            id: "kindergeld",
            titleKey: "tool_kindergeld_title",
            subtitleKey: "tool_kindergeld_subtitle",
            systemImage: "eurosign.circle.fill",
            tint: AppColor.amber),
        PersonaTool(
            id: "kita_school",
            titleKey: "tool_kita_title",
            subtitleKey: "tool_kita_subtitle",
            systemImage: "studentdesk",
            tint: AppColor.severityUrgent),
        PersonaTool(
            id: "birth_registration",
            titleKey: "tool_birth_title",
            subtitleKey: "tool_birth_subtitle",
            systemImage: "figure.child.circle.fill",
            tint: AppColor.primary),
    ]

    // MARK: - Long-term Resident (P5-04)

    /// Settling-permanently flow: settlement permit / citizenship eligibility,
    /// the citizenship test, and keeping documents renewed.
    private static let residentChecklist: [ChecklistItem] = [
        ChecklistItem(
            id: "resident_niederlassung",
            titleKey: "checklist_resident_niederlassung_title",
            subtitleKey: "checklist_resident_niederlassung_subtitle",
            link: .tool("niederlassung")),
        ChecklistItem(
            id: "resident_einbuergerung",
            titleKey: "checklist_resident_einbuergerung_title",
            subtitleKey: "checklist_resident_einbuergerung_subtitle",
            link: .tool("einbuergerung")),
        ChecklistItem(
            id: "resident_test",
            titleKey: "checklist_resident_test_title",
            subtitleKey: "checklist_resident_test_subtitle",
            link: .tool("einbuergerungstest")),
        ChecklistItem(
            id: "resident_renewals",
            titleKey: "checklist_resident_renewals_title",
            subtitleKey: "checklist_resident_renewals_subtitle",
            link: .tool("renewal_tracker")),
        ChecklistItem(
            id: "resident_anmeldung",
            titleKey: "checklist_resident_anmeldung_title",
            subtitleKey: "checklist_resident_anmeldung_subtitle"),
    ]

    private static let residentTools: [PersonaTool] = [
        PersonaTool(
            id: "niederlassung",
            titleKey: "tool_niederlassung_title",
            subtitleKey: "tool_niederlassung_subtitle",
            systemImage: "house.lodge.fill",
            tint: AppColor.primary),
        PersonaTool(
            id: "einbuergerung",
            titleKey: "tool_einbuergerung_title",
            subtitleKey: "tool_einbuergerung_subtitle",
            systemImage: "flag.fill",
            tint: AppColor.severityLegal),
        PersonaTool(
            id: "einbuergerungstest",
            titleKey: "tool_einbuergerungstest_title",
            subtitleKey: "tool_einbuergerungstest_subtitle",
            systemImage: "questionmark.app.fill",
            tint: AppColor.primaryDeep,
            badgeKey: "tool_badge_try_it"),
        PersonaTool(
            id: "renewal_tracker",
            titleKey: "tool_renewal_title",
            subtitleKey: "tool_renewal_subtitle",
            systemImage: "arrow.clockwise.circle.fill",
            tint: AppColor.amber),
        PersonaTool(
            id: "reunification_guide",
            titleKey: "tool_reunification_guide_title",
            subtitleKey: "tool_reunification_guide_subtitle",
            systemImage: "person.2.fill",
            tint: AppColor.severityInfo),
    ]
}
