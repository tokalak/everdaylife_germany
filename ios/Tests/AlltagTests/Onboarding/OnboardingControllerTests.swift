import XCTest
@testable import Alltag

/// Navigation + completion rules for onboarding (P2-04).
@MainActor
final class OnboardingControllerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "alltag.tests.onboarding.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testStepsAreLanguageThenPersonaThenNotifications() {
        XCTAssertEqual(
            OnboardingStep.allCases, [.language, .persona, .notifications])
        XCTAssertEqual(OnboardingStep.language.ordinal, 1)
        XCTAssertEqual(OnboardingStep.notifications.ordinal, OnboardingStep.count)
    }

    func testStartsIncompleteOnLanguageStep() {
        let c = OnboardingController(defaults: defaults)
        XCTAssertFalse(c.hasCompleted)
        XCTAssertEqual(c.step, .language)
        XCTAssertTrue(c.isFirstStep)
    }

    func testAdvanceAndBackWalkTheSteps() {
        let c = OnboardingController(defaults: defaults)
        c.advance()
        XCTAssertEqual(c.step, .persona)
        c.advance()
        XCTAssertEqual(c.step, .notifications)
        XCTAssertTrue(c.isLastStep)
        c.advance()  // no-op past the end
        XCTAssertEqual(c.step, .notifications)
        c.back()
        XCTAssertEqual(c.step, .persona)
    }

    func testBackOnFirstStepIsNoOp() {
        let c = OnboardingController(defaults: defaults)
        c.back()
        XCTAssertEqual(c.step, .language)
    }

    func testCompletePersistsAcrossInstances() {
        OnboardingController(defaults: defaults).complete()
        XCTAssertTrue(OnboardingController(defaults: defaults).hasCompleted)
    }
}
