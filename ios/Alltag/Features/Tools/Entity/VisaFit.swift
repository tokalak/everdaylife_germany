import Foundation

/// Inputs and result type for the Visa-fit tool (P6-W1).
///
/// A short guided questionnaire — what you're coming to do, and your
/// qualification — that points to the most fitting residence routes. Pure
/// content/logic; the engine (`VisaFitEngine`) maps inputs to routes and the
/// screen renders them. **Information only** (RDG / D9), never a legal decision.

/// Why you want to come to Germany.
enum VisaGoal: String, CaseIterable, Identifiable {
    case job            // already have / expect a job offer
    case jobSeeking     // qualified, looking for work
    case study
    case family
    case business       // freelance / found a company
    case visit          // short stay / tourism

    var id: String { rawValue }

    /// Whether the recommendation also depends on the qualification answer
    /// (only the work routes branch on it).
    var needsQualification: Bool { self == .job || self == .jobSeeking }

    var titleKey: String { "tool_visafit_goal_\(rawValue)" }
}

/// Highest qualification the person holds.
enum VisaQualification: String, CaseIterable, Identifiable {
    case academic       // recognised university degree
    case vocational     // recognised vocational qualification
    case none           // none yet / not recognised

    var id: String { rawValue }
    var titleKey: String { "tool_visafit_qual_\(rawValue)" }
}

/// What the user has answered so far.
struct VisaFitInput: Equatable {
    var goal: VisaGoal?
    var qualification: VisaQualification?

    /// Enough answered to produce a recommendation?
    var isAnswerable: Bool {
        guard let goal else { return false }
        return goal.needsQualification ? qualification != nil : true
    }
}

/// One recommended residence route, with a short rationale and an optional
/// "learn more" guide to open in the reader.
struct VisaFitRoute: Identifiable, Equatable {
    let id: String
    var titleKey: String { "tool_visafit_route_\(id)_title" }
    var detailKey: String { "tool_visafit_route_\(id)_detail" }
    /// `GuideContent.id` to open for more detail, if any.
    var guideId: String?
}
