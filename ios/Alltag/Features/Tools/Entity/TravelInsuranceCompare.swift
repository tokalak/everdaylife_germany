import Foundation

/// Travel / visa health-insurance comparison catalog (P6-T4).
///
/// A Schengen visa requires **travel health insurance** covering at least
/// **€30,000**, valid across the whole Schengen area for the entire stay. This is
/// a transparently ranked list of real providers newcomers and visa applicants
/// commonly use, described factually.
///
/// Reuses the generic `ComparisonOption`/`ComparisonCatalog` from P6-W4 rather
/// than a bespoke type (DRY). The `englishSupport` flag drives the same optional
/// newcomer filter as the other comparison tools; the `monthlyFeeKey` field is
/// repurposed here as a neutral "cover / price" fact line (e.g. "≥ €30,000 cover,
/// from ~€1/day"). The default order is a sensible newcomer-friendly ranking
/// (English support + instant online certificate first), presented transparently
/// — not a personalized recommendation.
///
/// **Re-verify cover figures, conditions and links periodically (OQ-1).**
/// Affiliate URLs point at the providers' own pages until the affiliate programs
/// are wired up in P6-A1; they are deliberately plain https links here. Brand
/// names are proper nouns, stored verbatim.
enum TravelInsuranceCatalog {

    static let current = ComparisonCatalog(
        year: 2026,
        options: [
            ComparisonOption(
                id: "hanse_merkur",
                name: "HanseMerkur",
                summaryKey: "tool_travel_opt_hanse_merkur_summary",
                highlightKeys: [
                    "tool_travel_opt_hanse_merkur_h1",
                    "tool_travel_opt_hanse_merkur_h2",
                    "tool_travel_opt_hanse_merkur_h3",
                ],
                monthlyFeeKey: "tool_travel_opt_hanse_merkur_fee",
                bestForKey: "tool_travel_opt_hanse_merkur_bestfor",
                url: URL(string: "https://www.hansemerkur.de"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "dr_walter",
                name: "DR-WALTER (Educare24)",
                summaryKey: "tool_travel_opt_dr_walter_summary",
                highlightKeys: [
                    "tool_travel_opt_dr_walter_h1",
                    "tool_travel_opt_dr_walter_h2",
                    "tool_travel_opt_dr_walter_h3",
                ],
                monthlyFeeKey: "tool_travel_opt_dr_walter_fee",
                bestForKey: "tool_travel_opt_dr_walter_bestfor",
                url: URL(string: "https://www.dr-walter.com/en"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "care_concept",
                name: "Care Concept",
                summaryKey: "tool_travel_opt_care_concept_summary",
                highlightKeys: [
                    "tool_travel_opt_care_concept_h1",
                    "tool_travel_opt_care_concept_h2",
                    "tool_travel_opt_care_concept_h3",
                ],
                monthlyFeeKey: "tool_travel_opt_care_concept_fee",
                bestForKey: "tool_travel_opt_care_concept_bestfor",
                url: URL(string: "https://www.care-concept.de/en"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "mawista",
                name: "MAWISTA",
                summaryKey: "tool_travel_opt_mawista_summary",
                highlightKeys: [
                    "tool_travel_opt_mawista_h1",
                    "tool_travel_opt_mawista_h2",
                    "tool_travel_opt_mawista_h3",
                ],
                monthlyFeeKey: "tool_travel_opt_mawista_fee",
                bestForKey: "tool_travel_opt_mawista_bestfor",
                url: URL(string: "https://www.mawista.com/en"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "allianz_travel",
                name: "Allianz Travel",
                summaryKey: "tool_travel_opt_allianz_travel_summary",
                highlightKeys: [
                    "tool_travel_opt_allianz_travel_h1",
                    "tool_travel_opt_allianz_travel_h2",
                    "tool_travel_opt_allianz_travel_h3",
                ],
                monthlyFeeKey: "tool_travel_opt_allianz_travel_fee",
                bestForKey: "tool_travel_opt_allianz_travel_bestfor",
                url: URL(string: "https://www.allianz-reiseversicherung.de"),
                isAffiliate: false,
                englishSupport: false),
        ])
}
