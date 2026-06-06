import Foundation

/// Partitions the standard-route settlement-permit criteria into met / missing
/// for the Niederlassungserlaubnis checker (P6-R1).
///
/// Pure, exhaustively tested logic (A-05): deterministic, order-preserving, and
/// dependent only on its inputs. Eligible iff nothing is missing. **Information
/// only** — the screen always carries the RDG note.
enum SettlementEligibilityEngine {

    /// Splits `criteria` by whether each id is in `satisfied`, preserving order.
    static func evaluate(
        satisfied: Set<String>,
        criteria: [SettlementCriterion] = SettlementRule.standardCriteria
    ) -> SettlementResult {
        var met: [SettlementCriterion] = []
        var missing: [SettlementCriterion] = []
        for criterion in criteria {
            if satisfied.contains(criterion.id) {
                met.append(criterion)
            } else {
                missing.append(criterion)
            }
        }
        return SettlementResult(met: met, missing: missing)
    }
}
