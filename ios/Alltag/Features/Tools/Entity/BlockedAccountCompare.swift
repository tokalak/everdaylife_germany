import Foundation

/// Blocked account (Sperrkonto) comparison catalog + the versioned required
/// amount (P6-S2).
///
/// International students normally must prove funds for a student visa via a
/// **blocked account (Sperrkonto)** holding the required annual amount, from
/// which they may withdraw a fixed sum per month. This is a transparently ranked
/// list of real providers students commonly use, described factually.
///
/// Reuses the generic `ComparisonOption`/`ComparisonCatalog` from P6-W4 rather
/// than a bespoke type (DRY). The `englishSupport` flag drives the same optional
/// newcomer filter as the other comparison tools; the `monthlyFeeKey` field is
/// repurposed here as a neutral "setup / monthly fee" fact line. The default
/// order is a sensible newcomer-friendly ranking (fast online opening + English
/// support + bundled insurance first), presented transparently — not a
/// personalized recommendation.
///
/// **Re-verify providers, fees, conditions and links periodically (OQ-1).**
/// Affiliate URLs point at the providers' own pages until the affiliate programs
/// are wired up in P6-A1; they are deliberately plain https links here. Brand
/// names are proper nouns, stored verbatim.
enum BlockedAccountCatalog {

    static let current = ComparisonCatalog(
        year: 2026,
        options: [
            ComparisonOption(
                id: "fintiba",
                name: "Fintiba",
                summaryKey: "tool_blocked_opt_fintiba_summary",
                highlightKeys: [
                    "tool_blocked_opt_fintiba_h1",
                    "tool_blocked_opt_fintiba_h2",
                    "tool_blocked_opt_fintiba_h3",
                ],
                monthlyFeeKey: "tool_blocked_opt_fintiba_fee",
                bestForKey: "tool_blocked_opt_fintiba_bestfor",
                url: URL(string: "https://www.fintiba.com/en"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "expatrio",
                name: "Expatrio",
                summaryKey: "tool_blocked_opt_expatrio_summary",
                highlightKeys: [
                    "tool_blocked_opt_expatrio_h1",
                    "tool_blocked_opt_expatrio_h2",
                    "tool_blocked_opt_expatrio_h3",
                ],
                monthlyFeeKey: "tool_blocked_opt_expatrio_fee",
                bestForKey: "tool_blocked_opt_expatrio_bestfor",
                url: URL(string: "https://www.expatrio.com"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "coracle",
                name: "Coracle",
                summaryKey: "tool_blocked_opt_coracle_summary",
                highlightKeys: [
                    "tool_blocked_opt_coracle_h1",
                    "tool_blocked_opt_coracle_h2",
                    "tool_blocked_opt_coracle_h3",
                ],
                monthlyFeeKey: "tool_blocked_opt_coracle_fee",
                bestForKey: "tool_blocked_opt_coracle_bestfor",
                url: URL(string: "https://www.coracle.de/en"),
                isAffiliate: true,
                englishSupport: true),
            ComparisonOption(
                id: "deutsche_bank",
                name: "Deutsche Bank",
                summaryKey: "tool_blocked_opt_deutsche_bank_summary",
                highlightKeys: [
                    "tool_blocked_opt_deutsche_bank_h1",
                    "tool_blocked_opt_deutsche_bank_h2",
                    "tool_blocked_opt_deutsche_bank_h3",
                ],
                monthlyFeeKey: "tool_blocked_opt_deutsche_bank_fee",
                bestForKey: "tool_blocked_opt_deutsche_bank_bestfor",
                url: URL(string: "https://www.deutsche-bank.de"),
                isAffiliate: false,
                englishSupport: false),
        ])
}

/// The required blocked-account amount for a student visa, isolated as yearly
/// data (X-06 / AGENTS), mirroring `BlueCardThresholds`.
///
/// The figure is set by the Auswärtiges Amt / Foreign Office (≈ the BAföG
/// maximum). It is shown on the screen so students know the target they must
/// block. **This figure changes annually and MUST be re-verified against the
/// Auswärtiges Amt each year (OQ-1).**
struct BlockedAccountRequirement: Equatable {
    let year: Int
    /// Total amount that must be blocked for the year, in EUR.
    let annualTotal: Double

    /// The fixed monthly withdrawal allowance (annual total / 12).
    var monthlyAllowance: Double { annualTotal / 12 }

    /// Current (2026) figure: ~€11,904/year (~€992/month). Re-verify yearly.
    static let current = BlockedAccountRequirement(year: 2026, annualTotal: 11_904)
}
