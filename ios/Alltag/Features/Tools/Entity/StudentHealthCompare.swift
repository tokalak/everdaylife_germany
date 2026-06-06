import Foundation

/// Student health-insurance comparison catalog (P6-S3).
///
/// Health insurance is mandatory for enrolment in Germany. Most enrolled
/// university students under ~30 join a **public student health insurance (GKV
/// student tariff)** at a fixed low monthly rate (e.g. TK, AOK), which is
/// accepted for enrolment. Students who **cannot** join the GKV student tariff
/// (over 30, language-course / preparatory students, some exchange visitors)
/// instead take **private / incoming health insurance** (e.g. Mawista, Care
/// Concept, Ottonova). This is a transparently ranked list of real options
/// spanning both kinds, described factually.
///
/// Reuses the generic `ComparisonOption`/`ComparisonCatalog` from P6-W4 rather
/// than a bespoke type (DRY). The `englishSupport` flag drives the same optional
/// newcomer filter as the other comparison tools; the `monthlyFeeKey` field is
/// repurposed here as a neutral price line, and the `bestForKey` hints who each
/// option suits (enrolled <30 vs language / over-30 / preparatory students). The
/// default order is a sensible newcomer-friendly ranking (public student tariff
/// first, then private/incoming for those not eligible), presented transparently
/// — not a personalized recommendation.
///
/// **Re-verify providers, tariffs, conditions and links periodically (OQ-1).**
/// Affiliate URLs point at the providers' own pages until the affiliate programs
/// are wired up in P6-A1; they are deliberately plain https links here. Brand
/// names are proper nouns, stored verbatim.
enum StudentHealthCatalog {

    static let current = ComparisonCatalog(
        year: 2026,
        options: [
            // Public student tariffs (GKV) — for enrolled students under ~30.
            ComparisonOption(
                id: "tk",
                name: "TK – Techniker Krankenkasse",
                summaryKey: "tool_studenthealth_opt_tk_summary",
                highlightKeys: [
                    "tool_studenthealth_opt_tk_h1",
                    "tool_studenthealth_opt_tk_h2",
                    "tool_studenthealth_opt_tk_h3",
                ],
                monthlyFeeKey: "tool_studenthealth_opt_tk_fee",
                bestForKey: "tool_studenthealth_opt_tk_bestfor",
                url: URL(string: "https://www.tk.de/en"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "aok",
                name: "AOK",
                summaryKey: "tool_studenthealth_opt_aok_summary",
                highlightKeys: [
                    "tool_studenthealth_opt_aok_h1",
                    "tool_studenthealth_opt_aok_h2",
                    "tool_studenthealth_opt_aok_h3",
                ],
                monthlyFeeKey: "tool_studenthealth_opt_aok_fee",
                bestForKey: "tool_studenthealth_opt_aok_bestfor",
                url: URL(string: "https://www.aok.de"),
                isAffiliate: false,
                englishSupport: false),
            // Private / incoming — for students NOT eligible for the GKV tariff
            // (over 30, language-course / preparatory, some exchange visitors).
            ComparisonOption(
                id: "mawista",
                name: "Mawista",
                summaryKey: "tool_studenthealth_opt_mawista_summary",
                highlightKeys: [
                    "tool_studenthealth_opt_mawista_h1",
                    "tool_studenthealth_opt_mawista_h2",
                    "tool_studenthealth_opt_mawista_h3",
                ],
                monthlyFeeKey: "tool_studenthealth_opt_mawista_fee",
                bestForKey: "tool_studenthealth_opt_mawista_bestfor",
                url: URL(string: "https://www.mawista.com/en"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "care_concept",
                name: "Care Concept",
                summaryKey: "tool_studenthealth_opt_care_concept_summary",
                highlightKeys: [
                    "tool_studenthealth_opt_care_concept_h1",
                    "tool_studenthealth_opt_care_concept_h2",
                    "tool_studenthealth_opt_care_concept_h3",
                ],
                monthlyFeeKey: "tool_studenthealth_opt_care_concept_fee",
                bestForKey: "tool_studenthealth_opt_care_concept_bestfor",
                url: URL(string: "https://www.care-concept.de/en"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "ottonova",
                name: "Ottonova",
                summaryKey: "tool_studenthealth_opt_ottonova_summary",
                highlightKeys: [
                    "tool_studenthealth_opt_ottonova_h1",
                    "tool_studenthealth_opt_ottonova_h2",
                    "tool_studenthealth_opt_ottonova_h3",
                ],
                monthlyFeeKey: "tool_studenthealth_opt_ottonova_fee",
                bestForKey: "tool_studenthealth_opt_ottonova_bestfor",
                url: URL(string: "https://www.ottonova.de/en"),
                isAffiliate: true,
                englishSupport: true),
        ])
}
