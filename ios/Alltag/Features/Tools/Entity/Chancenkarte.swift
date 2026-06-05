import Foundation

/// Inputs, versioned points configuration and result type for the Chancenkarte
/// (Opportunity Card) points calculator (P6-W3).
///
/// The Chancenkarte lets a qualified person come to Germany for up to a year to
/// look for work. Applicants who already hold **full recognition** of a foreign
/// qualification qualify directly; everyone else needs to reach the points
/// threshold on top of the baseline requirements (a recognised/comparable
/// qualification + German A1 or English B2 + proof of funds).
///
/// The criteria and point values are **yearly-changing data** (X-06 / AGENTS):
/// they are isolated in `ChancenkartePoints` so a rule change is a one-line edit,
/// never hard-coded in the engine or the view, and **must be re-verified
/// annually** (plan OQ-1). Ported from `prototype/index.html`.

// MARK: - Criterion answers

/// Strongest certified German language level.
enum CKGerman: String, CaseIterable, Identifiable {
    case none   // none / A1
    case a2
    case b1
    case b2     // B2 or higher

    var id: String { rawValue }
    var titleKey: String { "tool_ck_german_\(rawValue)" }
}

/// English language level (native or certified).
enum CKEnglish: String, CaseIterable, Identifiable {
    case belowC1
    case c1     // C1 or native

    var id: String { rawValue }
    var titleKey: String { "tool_ck_english_\(rawValue)" }
}

/// Applicant age band — younger applicants score higher.
enum CKAge: String, CaseIterable, Identifiable {
    case from40   // 40 or older
    case from35   // 35–39
    case under35

    var id: String { rawValue }
    var titleKey: String { "tool_ck_age_\(rawValue)" }
}

/// Work experience related to the qualification, in the last 7 years.
enum CKExperience: String, CaseIterable, Identifiable {
    case under2
    case from2    // 2–4 years
    case from5    // 5+ years

    var id: String { rawValue }
    var titleKey: String { "tool_ck_exp_\(rawValue)" }
}

// MARK: - Input

/// What the user has answered. The remaining yes/no criteria are booleans.
struct ChancenkarteInput: Equatable {
    /// Already holds full recognition of a foreign qualification → qualifies
    /// directly, regardless of points.
    var hasFullRecognition: Bool = false

    var german: CKGerman = .none
    var english: CKEnglish = .belowC1
    var age: CKAge = .from40
    var experience: CKExperience = .under2
    /// Job is on Germany's shortage-occupation (Engpassberufe) list.
    var isShortageOccupation: Bool = false
    /// At least 6 months in Germany in the last 5 years (not tourism).
    var hadPreviousStay: Bool = false
    /// Spouse/partner applies alongside and also meets the requirements.
    var partnerApplying: Bool = false
}

// MARK: - Versioned points configuration

/// The point values for each criterion and the qualifying threshold for one
/// year. Confirm against the official rules before each year rolls over (OQ-1).
struct ChancenkartePoints: Equatable {
    let year: Int
    /// Total points needed to be likely eligible.
    let threshold: Int

    let german: [CKGerman: Int]
    let english: [CKEnglish: Int]
    let age: [CKAge: Int]
    let experience: [CKExperience: Int]
    let shortageOccupation: Int
    let previousStay: Int
    let partnerApplying: Int

    /// Shipping values, ported from the agreed prototype. **Re-verify annually
    /// against the official Chancenkarte criteria** (OQ-1).
    static let current = ChancenkartePoints(
        year: 2026,
        threshold: 6,
        german: [.none: 0, .a2: 1, .b1: 2, .b2: 3],
        english: [.belowC1: 0, .c1: 1],
        age: [.from40: 0, .from35: 1, .under35: 2],
        experience: [.under2: 0, .from2: 2, .from5: 3],
        shortageOccupation: 1,
        previousStay: 1,
        partnerApplying: 1)
}

// MARK: - Result

/// The points verdict. Direct qualification (full recognition) short-circuits
/// the points path. (Baseline requirements are surfaced as a note on the
/// screen, not gated here.)
enum ChancenkarteResult: Equatable {
    /// Holds full recognition — qualifies directly, no points needed.
    case qualifiesDirectly
    /// Reached the threshold on points.
    case meetsThreshold(total: Int, threshold: Int)
    /// Below the threshold; `shortfall` more points are needed.
    case belowThreshold(total: Int, threshold: Int, shortfall: Int)

    var isEligible: Bool {
        switch self {
        case .qualifiesDirectly, .meetsThreshold: return true
        case .belowThreshold: return false
        }
    }

    /// Points scored from the criteria (`threshold` for the direct path, so the
    /// meter reads full).
    var total: Int {
        switch self {
        case .qualifiesDirectly: return ChancenkartePoints.current.threshold
        case let .meetsThreshold(total, _), let .belowThreshold(total, _, _): return total
        }
    }
}
