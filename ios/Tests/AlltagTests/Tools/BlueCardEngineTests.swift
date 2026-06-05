import XCTest
@testable import Alltag

/// EU Blue Card salary-threshold logic (P6-W2). Pure engine, tested against
/// injected thresholds so the rule is independent of the yearly figures (A-05).
final class BlueCardEngineTests: XCTestCase {

    private let t = BlueCardThresholds(year: 2026, general: 50_000, shortage: 45_000)

    private func eval(_ salary: Double, shortage: Bool) -> BlueCardResult {
        BlueCardEngine.evaluate(
            BlueCardInput(grossAnnualSalary: salary, isShortageOccupation: shortage),
            thresholds: t)
    }

    func testGeneralThresholdAppliesWhenNotShortage() {
        XCTAssertEqual(
            BlueCardEngine.applicableThreshold(
                for: BlueCardInput(grossAnnualSalary: 0, isShortageOccupation: false),
                thresholds: t),
            50_000)
    }

    func testShortageUsesLowerThreshold() {
        XCTAssertEqual(
            BlueCardEngine.applicableThreshold(
                for: BlueCardInput(grossAnnualSalary: 0, isShortageOccupation: true),
                thresholds: t),
            45_000)
    }

    func testSalaryAtThresholdIsEligible() {
        // Boundary: exactly the threshold qualifies.
        XCTAssertTrue(eval(50_000, shortage: false).isEligible)
        XCTAssertTrue(eval(45_000, shortage: true).isEligible)
    }

    func testSalaryAboveThresholdIsEligible() {
        XCTAssertTrue(eval(60_000, shortage: false).isEligible)
    }

    func testBelowGeneralButAboveShortageOnlyEligibleAsShortage() {
        XCTAssertFalse(eval(47_000, shortage: false).isEligible)
        XCTAssertTrue(eval(47_000, shortage: true).isEligible)
    }

    func testShortfallIsReported() {
        guard case let .belowThreshold(applicable, shortfall) = eval(42_000, shortage: false) else {
            return XCTFail("expected belowThreshold")
        }
        XCTAssertEqual(applicable, 50_000)
        XCTAssertEqual(shortfall, 8_000, accuracy: 0.001)
    }

    func testShippingThresholdsAreOrderedAndPlausible() {
        let c = BlueCardThresholds.current
        XCTAssertGreaterThan(c.general, c.shortage, "general threshold is the higher one")
        XCTAssertGreaterThan(c.shortage, 30_000, "sanity: thresholds are annual gross €")
    }
}
