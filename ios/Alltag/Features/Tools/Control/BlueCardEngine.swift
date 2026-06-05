import Foundation

/// EU Blue Card salary-threshold check (P6-W2).
///
/// Pure, tested logic (A-05): pick the applicable threshold (lower for shortage
/// occupations / new entrants), then compare the offered salary. Thresholds are
/// injected (defaulting to the current year) so the rule is independent of the
/// yearly figures. **Information only** — the screen carries the RDG note.
enum BlueCardEngine {

    /// The threshold that applies to this input.
    static func applicableThreshold(
        for input: BlueCardInput, thresholds: BlueCardThresholds = .current
    ) -> Double {
        input.isShortageOccupation ? thresholds.shortage : thresholds.general
    }

    static func evaluate(
        _ input: BlueCardInput, thresholds: BlueCardThresholds = .current
    ) -> BlueCardResult {
        let required = applicableThreshold(for: input, thresholds: thresholds)
        if input.grossAnnualSalary >= required {
            return .meetsThreshold(applicable: required)
        }
        return .belowThreshold(applicable: required, shortfall: required - input.grossAnnualSalary)
    }
}
