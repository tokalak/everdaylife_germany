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
}
