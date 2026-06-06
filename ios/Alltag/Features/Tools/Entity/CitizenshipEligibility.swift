import Foundation

/// Inputs, criteria and result type for the Einbürgerung (German naturalisation)
/// eligibility checker (P6-R2), reflecting the **June 2024 reform (StARModG)**.
///
/// The reform cut the standard residence requirement from 8 to **5 years**, added
/// a **3-year fast track** for special integration achievements, and now
/// **generally allows dual citizenship** (you usually no longer have to give up
/// your old nationality — a benefit, not a criterion). This self-assessment lets
/// the user tick the standard-route conditions they meet and lists what's still
/// missing. Pure content/logic; the engine (`CitizenshipEligibilityEngine`)
/// partitions criteria into met/missing and the screen renders the verdict.
/// **Information only** (RDG / D9), never a legal decision.

/// One condition on the standard route to German citizenship.
struct CitizenshipCriterion: Identifiable, Equatable {
    /// Stable id (used as the toggle key and to partition met/missing).
    let id: String
    var labelKey: String { "tool_citizenship_criterion_\(id)_label" }
    var detailKey: String { "tool_citizenship_criterion_\(id)_detail" }
}

/// Versioned rule constants for naturalisation under the 2024 reform.
///
/// These thresholds are **changeable rule data** (X-06 / AGENTS): isolated here
/// so a change is a one-line edit, never hard-coded in the engine or the view,
/// and **must be re-verified against the current Staatsangehörigkeitsgesetz
/// (§10 StAG, as amended by StARModG)** (plan OQ-1). The 3-year fast track
/// requires special integration achievements and German at **C1** (vs B1 on the
/// standard route); the reform now generally permits dual citizenship.
struct CitizenshipRule: Equatable {
    /// Years of lawful habitual residence required on the standard route.
    let standardYears: Int
    /// Years of residence required on the special-integration fast track.
    let fastTrackYears: Int

    /// Shipping values under the 2024 reform; re-verify annually (OQ-1).
    static let standard = CitizenshipRule(standardYears: 5, fastTrackYears: 3)

    /// The standard-route criteria, in the order shown. Keys-only; the constants
    /// above are substituted into the localized strings at render time.
    static let standardCriteria: [CitizenshipCriterion] = [
        CitizenshipCriterion(id: "residence_period"),
        CitizenshipCriterion(id: "settled_status"),
        CitizenshipCriterion(id: "german_b1"),
        CitizenshipCriterion(id: "citizenship_test"),
        CitizenshipCriterion(id: "secure_livelihood"),
        CitizenshipCriterion(id: "democratic_commitment"),
        CitizenshipCriterion(id: "no_serious_crime"),
    ]
}

/// The eligibility verdict: which criteria are met, which are still missing, and
/// whether the user qualifies (eligible iff nothing is missing).
struct CitizenshipResult: Equatable {
    let met: [CitizenshipCriterion]
    let missing: [CitizenshipCriterion]

    var isEligible: Bool { missing.isEmpty }
}
