import Foundation

/// EU Blue Card salary thresholds and checker types (P6-W2).
///
/// The thresholds are **yearly-changing data** (X-06 / AGENTS): derived from the
/// statutory contribution assessment ceiling (Beitragsbemessungsgrenze) and
/// updated every year. They are isolated here so a yearly bump is a one-line
/// edit — never hard-coded in the engine or the view — and **must be re-verified
/// annually** (plan OQ-1).

/// Salary thresholds for one calendar year (gross €/year).
struct BlueCardThresholds: Equatable {
    let year: Int
    /// General minimum gross annual salary.
    let general: Double
    /// Lower threshold for shortage occupations (Engpassberufe) and recent
    /// graduates / new entrants.
    let shortage: Double

    /// Shipping values. 2026 figures derive from the 2026 contribution
    /// assessment ceiling (general pension); confirm against the official
    /// publication before each year rolls over (OQ-1).
    static let current = BlueCardThresholds(year: 2026, general: 50_700, shortage: 45_934.20)
}

/// What the user told the checker.
struct BlueCardInput: Equatable {
    /// Gross annual salary offered, in €.
    var grossAnnualSalary: Double
    /// Whether the role is a shortage occupation or the applicant is a recent
    /// graduate / new entrant (the lower threshold applies).
    var isShortageOccupation: Bool
}

/// The salary-threshold verdict. (The Blue Card also requires a recognised
/// academic qualification — surfaced as a note on the screen, not gated here.)
enum BlueCardResult: Equatable {
    case meetsThreshold(applicable: Double)
    case belowThreshold(applicable: Double, shortfall: Double)

    var isEligible: Bool {
        if case .meetsThreshold = self { return true }
        return false
    }
}
