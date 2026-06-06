import Foundation

/// Inputs, criteria and result type for the Niederlassungserlaubnis (permanent
/// settlement permit) eligibility checker (P6-R1).
///
/// The settlement permit's **standard route** generally requires meeting ALL of
/// a fixed set of conditions. This self-assessment lets the user tick the ones
/// they meet and lists what's still missing. Pure content/logic; the engine
/// (`SettlementEligibilityEngine`) partitions criteria into met/missing and the
/// screen renders the verdict. **Information only** (RDG / D9), never a legal
/// decision — faster tracks exist (see `SettlementRule`) and are noted in copy.

/// One condition on the standard route to a settlement permit.
struct SettlementCriterion: Identifiable, Equatable {
    /// Stable id (used as the toggle key and to partition met/missing).
    let id: String
    var labelKey: String { "tool_settlement_criterion_\(id)_label" }
    var detailKey: String { "tool_settlement_criterion_\(id)_detail" }
}

/// Versioned rule constants for the standard route.
///
/// These thresholds are **changeable rule data** (X-06 / AGENTS): isolated here
/// so a change is a one-line edit, never hard-coded in the engine or the view,
/// and **must be re-verified against the current Aufenthaltsgesetz (§9 AufenthG)**
/// (plan OQ-1). Faster tracks exist and are mentioned in the screen copy (OQ-1):
/// EU Blue Card holders (~21–33 months), skilled workers (reduced period),
/// spouses of a German citizen, and university graduates.
struct SettlementRule: Equatable {
    /// Years of prior residence permit required on the standard route.
    let qualifyingYears: Int
    /// Months of statutory pension contributions required (or equivalent).
    let pensionMonths: Int

    /// Shipping values for the standard §9 route; re-verify annually (OQ-1).
    static let standard = SettlementRule(qualifyingYears: 5, pensionMonths: 60)

    /// The standard-route criteria, in the order shown. Keys-only; the constants
    /// above are substituted into the localized strings at render time.
    static let standardCriteria: [SettlementCriterion] = [
        SettlementCriterion(id: "residence_period"),
        SettlementCriterion(id: "secure_livelihood"),
        SettlementCriterion(id: "pension_contributions"),
        SettlementCriterion(id: "german_b1"),
        SettlementCriterion(id: "legal_social_order"),
        SettlementCriterion(id: "adequate_housing"),
        SettlementCriterion(id: "no_serious_crime"),
    ]
}

/// The eligibility verdict: which criteria are met, which are still missing, and
/// whether the user qualifies (eligible iff nothing is missing).
struct SettlementResult: Equatable {
    let met: [SettlementCriterion]
    let missing: [SettlementCriterion]

    var isEligible: Bool { missing.isEmpty }
}
