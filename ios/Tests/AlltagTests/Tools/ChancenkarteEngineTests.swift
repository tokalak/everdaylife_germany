import XCTest
@testable import Alltag

/// Chancenkarte points logic (P6-W3). Pure engine, tested against injected point
/// values so the rule is independent of the yearly figures (A-05).
@MainActor
final class ChancenkarteEngineTests: XCTestCase {

    private let p = ChancenkartePoints.current

    // MARK: - Per-criterion contributions

    func testGermanLevelsContributeTheirPoints() {
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(german: .none), points: p), 0)
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(german: .a2), points: p), 1)
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(german: .b1), points: p), 2)
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(german: .b2), points: p), 3)
    }

    func testEnglishContributesItsPoints() {
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(english: .belowC1), points: p), 0)
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(english: .c1), points: p), 1)
    }

    func testAgeBandsContributeTheirPoints() {
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(age: .from40), points: p), 0)
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(age: .from35), points: p), 1)
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(age: .under35), points: p), 2)
    }

    func testExperienceContributesItsPoints() {
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(experience: .under2), points: p), 0)
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(experience: .from2), points: p), 2)
        XCTAssertEqual(ChancenkarteEngine.total(for: ChancenkarteInput(experience: .from5), points: p), 3)
    }

    func testShortageOccupationContributesOnePoint() {
        XCTAssertEqual(
            ChancenkarteEngine.total(for: ChancenkarteInput(isShortageOccupation: true), points: p), 1)
    }

    func testPreviousStayContributesOnePoint() {
        XCTAssertEqual(
            ChancenkarteEngine.total(for: ChancenkarteInput(hadPreviousStay: true), points: p), 1)
    }

    func testPartnerApplyingContributesOnePoint() {
        XCTAssertEqual(
            ChancenkarteEngine.total(for: ChancenkarteInput(partnerApplying: true), points: p), 1)
    }

    func testPointsSumAcrossCriteria() {
        // B2(3) + C1(1) + under35(2) + 5+(3) + shortage(1) + prev(1) + partner(1) = 12
        let input = ChancenkarteInput(
            german: .b2, english: .c1, age: .under35, experience: .from5,
            isShortageOccupation: true, hadPreviousStay: true, partnerApplying: true)
        XCTAssertEqual(ChancenkarteEngine.total(for: input, points: p), 12)
    }

    // MARK: - Threshold boundary

    func testExactlyThresholdQualifies() {
        // B1(2) + age under35(2) + 2–4y(2) = 6 → exactly the threshold.
        let input = ChancenkarteInput(german: .b1, age: .under35, experience: .from2)
        XCTAssertEqual(ChancenkarteEngine.total(for: input, points: p), 6)
        let result = ChancenkarteEngine.evaluate(input, points: p)
        XCTAssertTrue(result.isEligible)
        XCTAssertEqual(result, .meetsThreshold(total: 6, threshold: 6))
    }

    func testOneBelowThresholdReportsShortfall() {
        // B1(2) + age under35(2) + shortage(1) = 5 → one short.
        let input = ChancenkarteInput(german: .b1, age: .under35, isShortageOccupation: true)
        let result = ChancenkarteEngine.evaluate(input, points: p)
        XCTAssertFalse(result.isEligible)
        XCTAssertEqual(result, .belowThreshold(total: 5, threshold: 6, shortfall: 1))
    }

    func testAllZeroIsBelowThresholdByFull() {
        let result = ChancenkarteEngine.evaluate(ChancenkarteInput(), points: p)
        XCTAssertEqual(result, .belowThreshold(total: 0, threshold: 6, shortfall: 6))
    }

    // MARK: - Direct qualification path

    func testFullRecognitionQualifiesDirectlyRegardlessOfPoints() {
        // No points at all, but full recognition → qualifies directly.
        let input = ChancenkarteInput(hasFullRecognition: true)
        let result = ChancenkarteEngine.evaluate(input, points: p)
        XCTAssertEqual(result, .qualifiesDirectly)
        XCTAssertTrue(result.isEligible)
    }

    func testDirectQualificationTotalReadsAsThreshold() {
        XCTAssertEqual(ChancenkarteResult.qualifiesDirectly.total, p.threshold)
    }

    // MARK: - Shipping config

    func testShippingConfigIsPlausible() {
        let c = ChancenkartePoints.current
        XCTAssertEqual(c.threshold, 6, "agreed Chancenkarte threshold is 6 points")
        // Highest achievable score must be able to clear the threshold.
        let best = ChancenkarteInput(
            german: .b2, english: .c1, age: .under35, experience: .from5,
            isShortageOccupation: true, hadPreviousStay: true, partnerApplying: true)
        XCTAssertGreaterThanOrEqual(ChancenkarteEngine.total(for: best, points: c), c.threshold)
    }

    func testLearnMoreGuideExists() {
        // The screen's "learn more" links to this guide; it must exist (D-guard).
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
