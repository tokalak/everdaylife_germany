import Foundation

/// Reusable comparison-option model + the bank-account catalog (P6-W4).
///
/// `ComparisonOption` is the generic, transparent affiliate-comparison row used
/// by the first comparison tool (Girokonto) and reusable by the later ones
/// (travel insurance, blocked account, student health, GKV/PKV — see P6-A1). It
/// is **information only** (RDG / D9): factual highlights and a sensible default
/// order, never "the best choice for you".
///
/// The catalog (`BankCompareCatalog`) is **often-changing data** (X-06 / AGENTS):
/// providers, fees and conditions move, so the list is isolated here in a
/// versioned struct — never hard-coded in the view — and **must be re-verified
/// periodically** (plan OQ-1). Brand names (N26, DKB…) are proper nouns and are
/// stored verbatim; all descriptive text is a localization key.

/// One comparison option shown in a ranked, transparent list.
struct ComparisonOption: Identifiable, Equatable {
    /// Stable id (also the localization-key stem for descriptive text).
    let id: String
    /// Brand / product name, shown verbatim (proper noun, not localized).
    let name: String
    /// One-line factual summary (localization key).
    let summaryKey: String
    /// Short factual highlights / conditions (localization keys).
    let highlightKeys: [String]
    /// A factual fact line, e.g. the monthly account fee (localization key).
    let monthlyFeeKey: String
    /// "Best for …" tag — a neutral use-case label, not a recommendation
    /// (localization key).
    let bestForKey: String
    /// Where the open-link button goes; `nil` hides the button.
    let url: URL?
    /// Whether `url` is an affiliate link (may earn a commission). Drives the
    /// per-option transparency marker; ranking/price are unaffected.
    let isAffiliate: Bool
    /// Whether the provider offers English-language onboarding / support — the
    /// one filterable fact for newcomers (drives the engine filter).
    let englishSupport: Bool
}

/// A versioned set of comparison options for one tool.
struct ComparisonCatalog: Equatable {
    let year: Int
    /// Presented in ranking order (first = sensible default, transparently).
    let options: [ComparisonOption]
}

/// The Girokonto (current account) comparison catalog (P6-W4).
///
/// Real banks newcomers commonly use, described factually. The default order is
/// a sensible newcomer-friendly ranking (English support + smartphone onboarding
/// first), presented transparently — not a personalized recommendation.
///
/// **Re-verify fees, conditions and links periodically (OQ-1).** Affiliate URLs
/// are placeholders pointing at the providers' own pages until the affiliate
/// programs are wired up in P6-A1; they are deliberately plain https links here.
enum BankCompareCatalog {

    static let current = ComparisonCatalog(
        year: 2026,
        options: [
            ComparisonOption(
                id: "n26",
                name: "N26",
                summaryKey: "tool_bank_opt_n26_summary",
                highlightKeys: [
                    "tool_bank_opt_n26_h1",
                    "tool_bank_opt_n26_h2",
                    "tool_bank_opt_n26_h3",
                ],
                monthlyFeeKey: "tool_bank_opt_n26_fee",
                bestForKey: "tool_bank_opt_n26_bestfor",
                url: URL(string: "https://n26.com/en-de"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "dkb",
                name: "DKB",
                summaryKey: "tool_bank_opt_dkb_summary",
                highlightKeys: [
                    "tool_bank_opt_dkb_h1",
                    "tool_bank_opt_dkb_h2",
                    "tool_bank_opt_dkb_h3",
                ],
                monthlyFeeKey: "tool_bank_opt_dkb_fee",
                bestForKey: "tool_bank_opt_dkb_bestfor",
                url: URL(string: "https://www.dkb.de"),
                isAffiliate: true,
                englishSupport: false),
            ComparisonOption(
                id: "ing",
                name: "ING",
                summaryKey: "tool_bank_opt_ing_summary",
                highlightKeys: [
                    "tool_bank_opt_ing_h1",
                    "tool_bank_opt_ing_h2",
                    "tool_bank_opt_ing_h3",
                ],
                monthlyFeeKey: "tool_bank_opt_ing_fee",
                bestForKey: "tool_bank_opt_ing_bestfor",
                url: URL(string: "https://www.ing.de"),
                isAffiliate: true,
                englishSupport: false),
            ComparisonOption(
                id: "commerzbank",
                name: "Commerzbank",
                summaryKey: "tool_bank_opt_commerzbank_summary",
                highlightKeys: [
                    "tool_bank_opt_commerzbank_h1",
                    "tool_bank_opt_commerzbank_h2",
                    "tool_bank_opt_commerzbank_h3",
                ],
                monthlyFeeKey: "tool_bank_opt_commerzbank_fee",
                bestForKey: "tool_bank_opt_commerzbank_bestfor",
                url: URL(string: "https://www.commerzbank.de"),
                isAffiliate: false,
                englishSupport: true),
            ComparisonOption(
                id: "deutsche_bank",
                name: "Deutsche Bank",
                summaryKey: "tool_bank_opt_deutsche_bank_summary",
                highlightKeys: [
                    "tool_bank_opt_deutsche_bank_h1",
                    "tool_bank_opt_deutsche_bank_h2",
                    "tool_bank_opt_deutsche_bank_h3",
                ],
                monthlyFeeKey: "tool_bank_opt_deutsche_bank_fee",
                bestForKey: "tool_bank_opt_deutsche_bank_bestfor",
                url: URL(string: "https://www.deutsche-bank.de"),
                isAffiliate: false,
                englishSupport: true),
        ])
}
