import Foundation

/// Partitions the standard-route naturalisation criteria into met / missing for
/// the Einbürgerung checker (P6-R2), reflecting the June 2024 reform.
///
/// Pure, exhaustively tested logic (A-05): deterministic, order-preserving, and
/// dependent only on its inputs. Eligible iff nothing is missing. **Information
/// only** — the screen always carries the RDG note.
enum CitizenshipEligibilityEngine {

    /// Splits `criteria` by whether each id is in `satisfied`, preserving order.
    static func evaluate(
        satisfied: Set<String>,
        criteria: [CitizenshipCriterion] = CitizenshipRule.standardCriteria
    ) -> CitizenshipResult {
        var met: [CitizenshipCriterion] = []
        var missing: [CitizenshipCriterion] = []
        for criterion in criteria {
            if satisfied.contains(criterion.id) {
                met.append(criterion)
            } else {
                missing.append(criterion)
            }
        }
        return CitizenshipResult(met: met, missing: missing)
    }
}
