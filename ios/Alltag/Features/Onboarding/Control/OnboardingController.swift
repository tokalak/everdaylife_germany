import Foundation
import Observation

/// The three onboarding steps (D1's single onboarding flow), in order.
enum OnboardingStep: Int, CaseIterable, Identifiable, Sendable {
    case language    // P2-01
    case persona     // P2-02
    case notifications // P2-03

    var id: Int { rawValue }

    /// 1-based position, for the progress indicator.
    var ordinal: Int { rawValue + 1 }
    static var count: Int { allCases.count }
}

/// Drives onboarding navigation and records completion (P2-04).
///
/// `hasCompleted` is the persisted gate the app routes on: while `false` the
/// onboarding flow is shown; once `true` the user lands on Home and never sees
/// onboarding again. The current `step` is in-memory navigation state (a fresh
/// launch mid-onboarding simply restarts the short flow).
@MainActor
@Observable
final class OnboardingController {
    private static let storageKey = "alltag.onboardingComplete"

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var hasCompleted: Bool
    var step: OnboardingStep = .language

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompleted = defaults.bool(forKey: Self.storageKey)
    }

    var isFirstStep: Bool { step == OnboardingStep.allCases.first }
    var isLastStep: Bool { step == OnboardingStep.allCases.last }

    /// Advances to the next step, or no-ops on the last (use `complete()`).
    func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    /// Returns to the previous step, or no-ops on the first.
    func back() {
        guard let prev = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = prev
    }

    /// Marks onboarding finished and persists it (P2-04).
    func complete() {
        hasCompleted = true
        defaults.set(true, forKey: Self.storageKey)
    }
}
