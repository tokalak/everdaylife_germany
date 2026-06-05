import Foundation

/// Inputs, threshold and result type for the GKV vs PKV decision tree (P6-W5).
///
/// A short guided questionnaire — your insurance status, and (for employees) your
/// gross annual income — that points to whether you must be in statutory cover
/// (GKV) or may choose private cover (PKV), with the trade-offs. Pure
/// content/logic; the engine (`HealthDecisionEngine`) maps inputs to a neutral,
/// **informational** recommendation (RDG / D9) and the screen renders it. It
/// presents the options and trade-offs, never "you must pick X".

/// How the person is insured / employed — the first decision-tree question.
enum HealthStatus: String, CaseIterable, Identifiable {
    case employee       // employed (compulsory cover depends on income)
    case selfEmployed   // freelancer / self-employed
    case student        // enrolled student
    case civilServant   // Beamter / Beamtin
    case other          // pensioner, job-seeking, family co-insured, etc.

    var id: String { rawValue }

    /// Whether the recommendation depends on the income answer (only employees
    /// branch on the compulsory-insurance threshold).
    var needsIncome: Bool { self == .employee }

    var titleKey: String { "tool_health_status_\(rawValue)" }
}

/// The compulsory-insurance income threshold (Jahresarbeitsentgeltgrenze) for one
/// calendar year (gross €/year). Above it, an employee may leave GKV for PKV;
/// at or below it, an employee is compulsorily insured in GKV.
///
/// This is **yearly-changing data** (X-06 / AGENTS): the figure is set annually,
/// so it is isolated here — never hard-coded in the engine or the view — and
/// **must be re-verified annually** (plan OQ-1).
struct HealthInsuranceThreshold: Equatable {
    let year: Int
    /// Jahresarbeitsentgeltgrenze — gross annual income above which an employee
    /// may opt out of statutory (GKV) into private (PKV) cover.
    let compulsoryInsuranceLimit: Double

    /// Shipping value. 2026 Jahresarbeitsentgeltgrenze (general); confirm against
    /// the official publication before each year rolls over (OQ-1).
    static let current = HealthInsuranceThreshold(year: 2026, compulsoryInsuranceLimit: 73_800)
}

/// What the user has answered so far.
struct HealthDecisionInput: Equatable {
    var status: HealthStatus?
    /// Gross annual income in € (only relevant for employees).
    var grossAnnualIncome: Double

    /// Enough answered to produce a recommendation?
    var isAnswerable: Bool { status != nil }
}

/// The neutral, informational outcome of the decision tree.
///
/// Each case is an option/trade-off statement, not personalized advice. The
/// rationale + GKV/PKV trade-off text live as localization keys derived from the
/// case id so the view stays string-free.
enum HealthRecommendation: String, Equatable {
    /// Employee at or below the threshold → compulsorily statutory (GKV).
    case mustBeGKV = "must_gkv"
    /// Employee above the threshold, or self-employed / civil servant → may
    /// choose between GKV and PKV.
    case gkvOrPkvChoice = "gkv_or_pkv"
    /// Enrolled student → the statutory student tariff (studentische
    /// Krankenversicherung) normally applies.
    case studentGKV = "student_gkv"
    /// Other situations (pensioner, job-seeking, family co-insured …) → which
    /// cover applies depends on the individual case.
    case dependsOnCase = "depends"

    var titleKey: String { "tool_health_result_\(rawValue)_title" }
    var detailKey: String { "tool_health_result_\(rawValue)_detail" }
}

/// The health-insurer comparison catalog (P6-W5).
///
/// Reuses the generic `ComparisonOption`/`ComparisonCatalog` from P6-W4 rather
/// than a bespoke type (DRY). Real funds newcomers commonly use, described
/// factually: the large statutory funds (TK, AOK, Barmer, DAK) and one private
/// (PKV) expat option (Ottonova), clearly labelled. The default order is a
/// sensible newcomer-friendly ranking (English support first, statutory before
/// private), presented transparently — not a personalized recommendation.
///
/// **Re-verify conditions, English support and links periodically (OQ-1).**
/// Affiliate URLs point at the providers' own pages until the affiliate programs
/// are wired up in P6-A1; brand names are proper nouns, stored verbatim.
enum HealthInsurerCatalog {

    static let current = ComparisonCatalog(
        year: 2026,
        options: [
            ComparisonOption(
                id: "tk",
                name: "Techniker Krankenkasse (TK)",
                summaryKey: "tool_health_opt_tk_summary",
                highlightKeys: [
                    "tool_health_opt_tk_h1",
                    "tool_health_opt_tk_h2",
                    "tool_health_opt_tk_h3",
                ],
                monthlyFeeKey: "tool_health_opt_tk_fee",
                bestForKey: "tool_health_opt_tk_bestfor",
                url: URL(string: "https://www.tk.de/en"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "aok",
                name: "AOK",
                summaryKey: "tool_health_opt_aok_summary",
                highlightKeys: [
                    "tool_health_opt_aok_h1",
                    "tool_health_opt_aok_h2",
                    "tool_health_opt_aok_h3",
                ],
                monthlyFeeKey: "tool_health_opt_aok_fee",
                bestForKey: "tool_health_opt_aok_bestfor",
                url: URL(string: "https://www.aok.de"),
                isAffiliate: false,
                englishSupport: false),
            ComparisonOption(
                id: "barmer",
                name: "Barmer",
                summaryKey: "tool_health_opt_barmer_summary",
                highlightKeys: [
                    "tool_health_opt_barmer_h1",
                    "tool_health_opt_barmer_h2",
                    "tool_health_opt_barmer_h3",
                ],
                monthlyFeeKey: "tool_health_opt_barmer_fee",
                bestForKey: "tool_health_opt_barmer_bestfor",
                url: URL(string: "https://www.barmer.de"),
                isAffiliate: false,
                englishSupport: false),
            ComparisonOption(
                id: "dak",
                name: "DAK-Gesundheit",
                summaryKey: "tool_health_opt_dak_summary",
                highlightKeys: [
                    "tool_health_opt_dak_h1",
                    "tool_health_opt_dak_h2",
                    "tool_health_opt_dak_h3",
                ],
                monthlyFeeKey: "tool_health_opt_dak_fee",
                bestForKey: "tool_health_opt_dak_bestfor",
                url: URL(string: "https://www.dak.de"),
                isAffiliate: false,
                englishSupport: false),
            ComparisonOption(
                id: "ottonova",
                name: "Ottonova",
                summaryKey: "tool_health_opt_ottonova_summary",
                highlightKeys: [
                    "tool_health_opt_ottonova_h1",
                    "tool_health_opt_ottonova_h2",
                    "tool_health_opt_ottonova_h3",
                ],
                monthlyFeeKey: "tool_health_opt_ottonova_fee",
                bestForKey: "tool_health_opt_ottonova_bestfor",
                url: URL(string: "https://www.ottonova.de/en"),
                isAffiliate: true,
                englishSupport: true),
        ])
}
