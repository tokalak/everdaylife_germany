import XCTest
@testable import Alltag

/// Einbürgerung (naturalisation) eligibility logic (P6-R2), reflecting the June
/// 2024 reform. Pure engine, exhaustively tested (A-05): the met/missing
/// partition is correct for the full, empty, partial and one-short cases, order
/// is preserved, unknown ids are ignored, the criteria list is well-formed, the
/// versioned rule constants are plausible, and the "learn more" guide it links
/// actually ships.
final class CitizenshipEligibilityEngineTests: XCTestCase {

    private let criteria = CitizenshipRule.standardCriteria
    private var allIds: Set<String> { Set(criteria.map(\.id)) }

    private func evaluate(_ satisfied: Set<String>) -> CitizenshipResult {
        CitizenshipEligibilityEngine.evaluate(satisfied: satisfied, criteria: criteria)
    }

    func testAllSatisfiedIsEligibleWithNothingMissing() {
        let result = evaluate(allIds)
        XCTAssertTrue(result.isEligible)
        XCTAssertTrue(result.missing.isEmpty)
        XCTAssertEqual(result.met.map(\.id), criteria.map(\.id))
    }

    func testNoneSatisfiedIsNotEligibleAndAllAreMissing() {
        let result = evaluate([])
        XCTAssertFalse(result.isEligible)
        XCTAssertTrue(result.met.isEmpty)
        XCTAssertEqual(result.missing.map(\.id), criteria.map(\.id))
    }

    func testPartialSetPartitionsCorrectly() {
        let satisfied: Set<String> = ["residence_period", "german_b1", "citizenship_test"]
        let result = evaluate(satisfied)
        XCTAssertFalse(result.isEligible)
        XCTAssertEqual(Set(result.met.map(\.id)), satisfied)
        XCTAssertEqual(Set(result.missing.map(\.id)), allIds.subtracting(satisfied))
        // Every criterion is in exactly one bucket.
        XCTAssertEqual(result.met.count + result.missing.count, criteria.count)
    }

    func testMissingExactlyOneIsNotEligibleAndThatOneIsTheOnlyMissing() {
        let dropped = "secure_livelihood"
        let result = evaluate(allIds.subtracting([dropped]))
        XCTAssertFalse(result.isEligible)
        XCTAssertEqual(result.missing.map(\.id), [dropped])
    }

    func testOrderIsPreservedInBothBuckets() {
        let result = evaluate(["settled_status", "no_serious_crime"])
        XCTAssertEqual(result.met.map(\.id), ["settled_status", "no_serious_crime"])
        XCTAssertEqual(
            result.missing.map(\.id),
            criteria.map(\.id).filter { $0 != "settled_status" && $0 != "no_serious_crime" })
    }

    func testUnknownSatisfiedIdsAreIgnored() {
        let result = evaluate(["not_a_real_criterion"])
        XCTAssertTrue(result.met.isEmpty)
        XCTAssertEqual(result.missing.count, criteria.count)
    }

    func testCriteriaListIsNonEmptyWithUniqueIds() {
        XCTAssertFalse(criteria.isEmpty)
        XCTAssertEqual(allIds.count, criteria.count, "criterion ids must be unique")
    }

    func testRuleConstantsArePlausible() {
        let rule = CitizenshipRule.standard
        XCTAssertEqual(rule.standardYears, 5)
        XCTAssertEqual(rule.fastTrackYears, 3)
        // Standard route is longer than the fast track, both positive.
        XCTAssertGreaterThan(rule.standardYears, rule.fastTrackYears)
        XCTAssertGreaterThan(rule.fastTrackYears, 0)
    }

    @MainActor
    func testResidencePermitGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
