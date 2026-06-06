import XCTest
@testable import Alltag

/// Niederlassungserlaubnis eligibility logic (P6-R1). Pure engine, exhaustively
/// tested (A-05): the met/missing partition is correct for the full, empty,
/// partial and one-short cases, the criteria list is well-formed, and the
/// "learn more" guide it links actually ships.
final class SettlementEligibilityEngineTests: XCTestCase {

    private let criteria = SettlementRule.standardCriteria
    private var allIds: Set<String> { Set(criteria.map(\.id)) }

    private func evaluate(_ satisfied: Set<String>) -> SettlementResult {
        SettlementEligibilityEngine.evaluate(satisfied: satisfied, criteria: criteria)
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
        let satisfied: Set<String> = ["residence_period", "german_b1", "adequate_housing"]
        let result = evaluate(satisfied)
        XCTAssertFalse(result.isEligible)
        XCTAssertEqual(Set(result.met.map(\.id)), satisfied)
        XCTAssertEqual(Set(result.missing.map(\.id)), allIds.subtracting(satisfied))
        // Every criterion is in exactly one bucket.
        XCTAssertEqual(result.met.count + result.missing.count, criteria.count)
    }

    func testMissingExactlyOneIsNotEligibleAndThatOneIsTheOnlyMissing() {
        let dropped = "pension_contributions"
        let result = evaluate(allIds.subtracting([dropped]))
        XCTAssertFalse(result.isEligible)
        XCTAssertEqual(result.missing.map(\.id), [dropped])
    }

    func testOrderIsPreservedInBothBuckets() {
        let result = evaluate(["secure_livelihood", "no_serious_crime"])
        XCTAssertEqual(result.met.map(\.id), ["secure_livelihood", "no_serious_crime"])
        XCTAssertEqual(
            result.missing.map(\.id),
            criteria.map(\.id).filter { $0 != "secure_livelihood" && $0 != "no_serious_crime" })
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
        XCTAssertEqual(SettlementRule.standard.qualifyingYears, 5)
        XCTAssertEqual(SettlementRule.standard.pensionMonths, 60)
    }

    @MainActor
    func testResidencePermitGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
