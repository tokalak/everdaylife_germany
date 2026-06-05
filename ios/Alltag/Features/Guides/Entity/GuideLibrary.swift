import SwiftUI

/// Versioned body content for the cross-persona guides (X-06 — isolated here so
/// copy/order changes without touching the reader; P6-G1…G5).
///
/// The Home tiles live in `PersonaCatalog.guides`; the full `GuideContent` is
/// looked up here by the same stable `id`, so every shipped tile must have
/// matching content (asserted in tests as guides land).
///
/// `@MainActor` because the content holds `LocalizedStringKey`s (not `Sendable`)
/// and is only ever read from the main actor (reader + search).
@MainActor
enum GuideLibrary {

    /// All guide bodies that have shipped, in display order.
    static let all: [GuideContent] = [
        residencePermit,
        registerBusiness,
        howTaxesWork,
        healthInsurance,
        diplomaRecognition,
    ]

    /// The full body for a guide id, or `nil` if its content hasn't shipped yet
    /// (the reader then falls back to a "coming soon" affordance).
    static func content(for id: String) -> GuideContent? {
        all.first { $0.id == id }
    }

    // MARK: - P6-G1 · Residence permit (Aufenthaltstitel)

    private static let residencePermit = GuideContent(
        id: "residence_permit",
        titleKey: "guide_residence_permit_title",
        summaryKey: "guidedoc_rp_summary",
        sections: [
            GuideSection(
                id: "what",
                headingKey: "guidedoc_rp_s1_heading",
                blocks: [
                    .paragraph("guidedoc_rp_s1_p1"),
                    .paragraph("guidedoc_rp_s1_p2"),
                ]),
            GuideSection(
                id: "who",
                headingKey: "guidedoc_rp_s2_heading",
                blocks: [
                    .bullet("guidedoc_rp_s2_b1"),
                    .bullet("guidedoc_rp_s2_b2"),
                    .bullet("guidedoc_rp_s2_b3"),
                ]),
            GuideSection(
                id: "types",
                headingKey: "guidedoc_rp_s3_heading",
                blocks: [
                    .bullet("guidedoc_rp_s3_b1"),
                    .bullet("guidedoc_rp_s3_b2"),
                    .bullet("guidedoc_rp_s3_b3"),
                    .bullet("guidedoc_rp_s3_b4"),
                    .bullet("guidedoc_rp_s3_b5"),
                    .bullet("guidedoc_rp_s3_b6"),
                ]),
            GuideSection(
                id: "apply",
                headingKey: "guidedoc_rp_s4_heading",
                blocks: [
                    .bullet("guidedoc_rp_s4_b1"),
                    .bullet("guidedoc_rp_s4_b2"),
                    .bullet("guidedoc_rp_s4_b3"),
                    .bullet("guidedoc_rp_s4_b4"),
                    .bullet("guidedoc_rp_s4_b5"),
                    .bullet("guidedoc_rp_s4_b6"),
                ]),
            GuideSection(
                id: "documents",
                headingKey: "guidedoc_rp_s5_heading",
                blocks: [
                    .bullet("guidedoc_rp_s5_b1"),
                    .bullet("guidedoc_rp_s5_b2"),
                    .bullet("guidedoc_rp_s5_b3"),
                    .bullet("guidedoc_rp_s5_b4"),
                    .bullet("guidedoc_rp_s5_b5"),
                    .bullet("guidedoc_rp_s5_b6"),
                ]),
            GuideSection(
                id: "after",
                headingKey: "guidedoc_rp_s6_heading",
                blocks: [
                    .paragraph("guidedoc_rp_s6_p1"),
                    .paragraph("guidedoc_rp_s6_p2"),
                ]),
            GuideSection(
                id: "tips",
                headingKey: "guidedoc_rp_s7_heading",
                blocks: [
                    .bullet("guidedoc_rp_s7_b1"),
                    .bullet("guidedoc_rp_s7_b2"),
                    .bullet("guidedoc_rp_s7_b3"),
                ]),
        ],
        sources: [
            GuideSource(
                id: "miig",
                titleKey: "guidedoc_rp_source_miig",
                url: URL(string: "https://www.make-it-in-germany.com/en/visa-residence")!),
            GuideSource(
                id: "bamf",
                titleKey: "guidedoc_rp_source_bamf",
                url: URL(string: "https://www.bamf.de/EN/Themen/MigrationAufenthalt/migrationaufenthalt-node.html")!),
        ])

    // MARK: - P6-G2 · Registering a business (Gewerbe vs Freiberufler)

    private static let registerBusiness = GuideContent(
        id: "register_business",
        titleKey: "guide_register_business_title",
        summaryKey: "guidedoc_rb_summary",
        sections: [
            GuideSection(
                id: "two_paths",
                headingKey: "guidedoc_rb_s1_heading",
                blocks: [
                    .paragraph("guidedoc_rb_s1_p1"),
                    .paragraph("guidedoc_rb_s1_p2"),
                ]),
            GuideSection(
                id: "freiberufler",
                headingKey: "guidedoc_rb_s2_heading",
                blocks: [
                    .paragraph("guidedoc_rb_s2_p1"),
                    .bullet("guidedoc_rb_s2_b1"),
                    .bullet("guidedoc_rb_s2_b2"),
                    .bullet("guidedoc_rb_s2_b3"),
                    .bullet("guidedoc_rb_s2_b4"),
                ]),
            GuideSection(
                id: "gewerbe",
                headingKey: "guidedoc_rb_s3_heading",
                blocks: [
                    .paragraph("guidedoc_rb_s3_p1"),
                    .bullet("guidedoc_rb_s3_b1"),
                    .bullet("guidedoc_rb_s3_b2"),
                    .bullet("guidedoc_rb_s3_b3"),
                ]),
            GuideSection(
                id: "register_gewerbe",
                headingKey: "guidedoc_rb_s4_heading",
                blocks: [
                    .bullet("guidedoc_rb_s4_b1"),
                    .bullet("guidedoc_rb_s4_b2"),
                    .bullet("guidedoc_rb_s4_b3"),
                    .bullet("guidedoc_rb_s4_b4"),
                ]),
            GuideSection(
                id: "register_freiberufler",
                headingKey: "guidedoc_rb_s5_heading",
                blocks: [
                    .bullet("guidedoc_rb_s5_b1"),
                    .bullet("guidedoc_rb_s5_b2"),
                    .bullet("guidedoc_rb_s5_b3"),
                ]),
            GuideSection(
                id: "taxes",
                headingKey: "guidedoc_rb_s6_heading",
                blocks: [
                    .bullet("guidedoc_rb_s6_b1"),
                    .bullet("guidedoc_rb_s6_b2"),
                    .bullet("guidedoc_rb_s6_b3"),
                    .bullet("guidedoc_rb_s6_b4"),
                ]),
            GuideSection(
                id: "tips",
                headingKey: "guidedoc_rb_s7_heading",
                blocks: [
                    .bullet("guidedoc_rb_s7_b1"),
                    .bullet("guidedoc_rb_s7_b2"),
                    .bullet("guidedoc_rb_s7_b3"),
                ]),
        ],
        sources: [
            GuideSource(
                id: "miig",
                titleKey: "guidedoc_rb_source_miig",
                url: URL(string: "https://www.make-it-in-germany.com/en/working-in-germany/self-employment")!),
            GuideSource(
                id: "existenzgruender",
                titleKey: "guidedoc_rb_source_existenzgruender",
                url: URL(string: "https://www.existenzgruender.de/")!),
        ])

    // MARK: - P6-G3 · How taxes work

    private static let howTaxesWork = GuideContent(
        id: "how_taxes_work",
        titleKey: "guide_taxes_title",
        summaryKey: "guidedoc_tx_summary",
        sections: [
            GuideSection(
                id: "basics",
                headingKey: "guidedoc_tx_s1_heading",
                blocks: [
                    .paragraph("guidedoc_tx_s1_p1"),
                    .paragraph("guidedoc_tx_s1_p2"),
                ]),
            GuideSection(
                id: "id_vs_number",
                headingKey: "guidedoc_tx_s2_heading",
                blocks: [
                    .bullet("guidedoc_tx_s2_b1"),
                    .bullet("guidedoc_tx_s2_b2"),
                    .bullet("guidedoc_tx_s2_b3"),
                ]),
            GuideSection(
                id: "income_tax",
                headingKey: "guidedoc_tx_s3_heading",
                blocks: [
                    .paragraph("guidedoc_tx_s3_p1"),
                    .bullet("guidedoc_tx_s3_b1"),
                    .bullet("guidedoc_tx_s3_b2"),
                ]),
            GuideSection(
                id: "tax_classes",
                headingKey: "guidedoc_tx_s4_heading",
                blocks: [
                    .paragraph("guidedoc_tx_s4_p1"),
                    .bullet("guidedoc_tx_s4_b1"),
                    .bullet("guidedoc_tx_s4_b2"),
                    .bullet("guidedoc_tx_s4_b3"),
                ]),
            GuideSection(
                id: "deductions",
                headingKey: "guidedoc_tx_s5_heading",
                blocks: [
                    .bullet("guidedoc_tx_s5_b1"),
                    .bullet("guidedoc_tx_s5_b2"),
                    .bullet("guidedoc_tx_s5_b3"),
                    .bullet("guidedoc_tx_s5_b4"),
                ]),
            GuideSection(
                id: "return",
                headingKey: "guidedoc_tx_s6_heading",
                blocks: [
                    .bullet("guidedoc_tx_s6_b1"),
                    .bullet("guidedoc_tx_s6_b2"),
                    .bullet("guidedoc_tx_s6_b3"),
                    .bullet("guidedoc_tx_s6_b4"),
                ]),
            GuideSection(
                id: "tips",
                headingKey: "guidedoc_tx_s7_heading",
                blocks: [
                    .bullet("guidedoc_tx_s7_b1"),
                    .bullet("guidedoc_tx_s7_b2"),
                    .bullet("guidedoc_tx_s7_b3"),
                ]),
        ],
        sources: [
            GuideSource(
                id: "miig",
                titleKey: "guidedoc_tx_source_miig",
                url: URL(string: "https://www.make-it-in-germany.com/en/living-in-germany/money-banking/taxes")!),
            GuideSource(
                id: "elster",
                titleKey: "guidedoc_tx_source_elster",
                url: URL(string: "https://www.elster.de/")!),
        ])

    // MARK: - P6-G4 · Getting health insurance

    private static let healthInsurance = GuideContent(
        id: "health_insurance",
        titleKey: "guide_health_title",
        summaryKey: "guidedoc_hi_summary",
        sections: [
            GuideSection(
                id: "mandatory",
                headingKey: "guidedoc_hi_s1_heading",
                blocks: [
                    .paragraph("guidedoc_hi_s1_p1"),
                    .paragraph("guidedoc_hi_s1_p2"),
                ]),
            GuideSection(
                id: "gkv_vs_pkv",
                headingKey: "guidedoc_hi_s2_heading",
                blocks: [
                    .paragraph("guidedoc_hi_s2_p1"),
                    .bullet("guidedoc_hi_s2_b1"),
                    .bullet("guidedoc_hi_s2_b2"),
                ]),
            GuideSection(
                id: "who_chooses",
                headingKey: "guidedoc_hi_s3_heading",
                blocks: [
                    .bullet("guidedoc_hi_s3_b1"),
                    .bullet("guidedoc_hi_s3_b2"),
                    .bullet("guidedoc_hi_s3_b3"),
                ]),
            GuideSection(
                id: "gkv_covers",
                headingKey: "guidedoc_hi_s4_heading",
                blocks: [
                    .bullet("guidedoc_hi_s4_b1"),
                    .bullet("guidedoc_hi_s4_b2"),
                    .bullet("guidedoc_hi_s4_b3"),
                ]),
            GuideSection(
                id: "sign_up",
                headingKey: "guidedoc_hi_s5_heading",
                blocks: [
                    .bullet("guidedoc_hi_s5_b1"),
                    .bullet("guidedoc_hi_s5_b2"),
                    .bullet("guidedoc_hi_s5_b3"),
                ]),
            GuideSection(
                id: "special",
                headingKey: "guidedoc_hi_s6_heading",
                blocks: [
                    .bullet("guidedoc_hi_s6_b1"),
                    .bullet("guidedoc_hi_s6_b2"),
                    .bullet("guidedoc_hi_s6_b3"),
                ]),
            GuideSection(
                id: "tips",
                headingKey: "guidedoc_hi_s7_heading",
                blocks: [
                    .bullet("guidedoc_hi_s7_b1"),
                    .bullet("guidedoc_hi_s7_b2"),
                ]),
        ],
        sources: [
            GuideSource(
                id: "miig",
                titleKey: "guidedoc_hi_source_miig",
                url: URL(string: "https://www.make-it-in-germany.com/en/living-in-germany/health-insurance")!),
            GuideSource(
                id: "gkv",
                titleKey: "guidedoc_hi_source_gkv",
                url: URL(string: "https://www.gkv-spitzenverband.de/english/english.jsp")!),
        ])

    // MARK: - P6-G5 · Recognising a foreign diploma (Anerkennung)

    private static let diplomaRecognition = GuideContent(
        id: "diploma_recognition",
        titleKey: "guide_diploma_title",
        summaryKey: "guidedoc_dr_summary",
        sections: [
            GuideSection(
                id: "what",
                headingKey: "guidedoc_dr_s1_heading",
                blocks: [
                    .paragraph("guidedoc_dr_s1_p1"),
                    .paragraph("guidedoc_dr_s1_p2"),
                ]),
            GuideSection(
                id: "when",
                headingKey: "guidedoc_dr_s2_heading",
                blocks: [
                    .bullet("guidedoc_dr_s2_b1"),
                    .bullet("guidedoc_dr_s2_b2"),
                    .bullet("guidedoc_dr_s2_b3"),
                ]),
            GuideSection(
                id: "regulated",
                headingKey: "guidedoc_dr_s3_heading",
                blocks: [
                    .paragraph("guidedoc_dr_s3_p1"),
                    .bullet("guidedoc_dr_s3_b1"),
                    .bullet("guidedoc_dr_s3_b2"),
                    .bullet("guidedoc_dr_s3_b3"),
                ]),
            GuideSection(
                id: "how",
                headingKey: "guidedoc_dr_s4_heading",
                blocks: [
                    .bullet("guidedoc_dr_s4_b1"),
                    .bullet("guidedoc_dr_s4_b2"),
                    .bullet("guidedoc_dr_s4_b3"),
                ]),
            GuideSection(
                id: "documents",
                headingKey: "guidedoc_dr_s5_heading",
                blocks: [
                    .bullet("guidedoc_dr_s5_b1"),
                    .bullet("guidedoc_dr_s5_b2"),
                    .bullet("guidedoc_dr_s5_b3"),
                    .bullet("guidedoc_dr_s5_b4"),
                ]),
            GuideSection(
                id: "outcome",
                headingKey: "guidedoc_dr_s6_heading",
                blocks: [
                    .bullet("guidedoc_dr_s6_b1"),
                    .bullet("guidedoc_dr_s6_b2"),
                ]),
            GuideSection(
                id: "tips",
                headingKey: "guidedoc_dr_s7_heading",
                blocks: [
                    .bullet("guidedoc_dr_s7_b1"),
                    .bullet("guidedoc_dr_s7_b2"),
                    .bullet("guidedoc_dr_s7_b3"),
                ]),
        ],
        sources: [
            GuideSource(
                id: "aid",
                titleKey: "guidedoc_dr_source_aid",
                url: URL(string: "https://www.anerkennung-in-deutschland.de/en/")!),
            GuideSource(
                id: "miig",
                titleKey: "guidedoc_dr_source_miig",
                url: URL(string: "https://www.make-it-in-germany.com/en/working-in-germany/recognition-of-qualifications")!),
        ])
}
