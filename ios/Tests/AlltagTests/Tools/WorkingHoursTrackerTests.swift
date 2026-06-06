import XCTest
@testable import Alltag

/// Student work-allowance tracker (P6-S5). A-05 highest-risk surface — the
/// day-classification / allowance engine — so it is tested exhaustively against
/// the injected `WorkAllowance` (no global state), covering: the half/full
/// classification and its 4-hour boundary, zero/negative hours ignored, the full
/// 140 / 280 boundaries, mixed counts, the non-negative remaining floor on
/// overwork, and the empty case.
final class WorkingHoursTrackerTests: XCTestCase {

    private let cal = Calendar(identifier: .gregorian)

    /// A logged day with the given hours (date is irrelevant to the engine).
    private func day(_ hours: Double) -> WorkDay {
        WorkDay(date: Date(timeIntervalSince1970: 0), hours: hours)
    }

    private func usage(_ days: [WorkDay]) -> WorkAllowanceUsage {
        WorkingHoursTracker.usage(days: days)
    }

    // MARK: - Classification

    func testMoreThanFourHoursIsAFullDay() {
        let u = usage([day(8)])
        XCTAssertEqual(u.fullDays, 1)
        XCTAssertEqual(u.halfDays, 0)
        XCTAssertEqual(u.usedEquivalents, 1.0)
    }

    func testUpToFourHoursIsAHalfDay() {
        let u = usage([day(3)])
        XCTAssertEqual(u.fullDays, 0)
        XCTAssertEqual(u.halfDays, 1)
        XCTAssertEqual(u.usedEquivalents, 0.5)
    }

    func testExactlyFourHoursIsAHalfDayBoundary() {
        let u = usage([day(4.0)])
        XCTAssertEqual(u.halfDays, 1)
        XCTAssertEqual(u.fullDays, 0)
        XCTAssertEqual(u.usedEquivalents, 0.5)
    }

    func testJustOverFourHoursIsAFullDay() {
        let u = usage([day(4.01)])
        XCTAssertEqual(u.fullDays, 1)
        XCTAssertEqual(u.halfDays, 0)
    }

    func testZeroHoursIsIgnored() {
        let u = usage([day(0)])
        XCTAssertEqual(u.fullDays, 0)
        XCTAssertEqual(u.halfDays, 0)
        XCTAssertEqual(u.usedEquivalents, 0)
    }

    func testNegativeHoursIsIgnored() {
        let u = usage([day(-5)])
        XCTAssertEqual(u.fullDays, 0)
        XCTAssertEqual(u.halfDays, 0)
        XCTAssertEqual(u.usedEquivalents, 0)
    }

    // MARK: - Allowance boundaries (140 full / 280 half == 140 equivalents)

    func testOneHundredFortyFullDaysUsesAllAndLeavesZero() {
        let days = Array(repeating: day(8), count: 140)
        let u = usage(days)
        XCTAssertEqual(u.fullDays, 140)
        XCTAssertEqual(u.usedEquivalents, 140)
        XCTAssertEqual(u.remainingEquivalents, 0)
    }

    func testTwoHundredEightyHalfDaysUsesAllAndLeavesZero() {
        let days = Array(repeating: day(3), count: 280)
        let u = usage(days)
        XCTAssertEqual(u.halfDays, 280)
        XCTAssertEqual(u.usedEquivalents, 140)
        XCTAssertEqual(u.remainingEquivalents, 0)
    }

    func testMixedCountsAddUp() {
        // 100 full (100.0) + 40 half (20.0) = 120.0 used, 20.0 remaining.
        let days = Array(repeating: day(8), count: 100)
            + Array(repeating: day(2), count: 40)
        let u = usage(days)
        XCTAssertEqual(u.fullDays, 100)
        XCTAssertEqual(u.halfDays, 40)
        XCTAssertEqual(u.usedEquivalents, 120)
        XCTAssertEqual(u.remainingEquivalents, 20)
    }

    func testOverworkCapsRemainingAtZeroAndUsedExceedsLimit() {
        // 150 full days = 150.0 used > 140.
        let days = Array(repeating: day(8), count: 150)
        let u = usage(days)
        XCTAssertEqual(u.usedEquivalents, 150)
        XCTAssertEqual(u.remainingEquivalents, 0)
    }

    func testEmptyGivesZeroUsedAndFullRemaining() {
        let u = usage([])
        XCTAssertEqual(u.fullDays, 0)
        XCTAssertEqual(u.halfDays, 0)
        XCTAssertEqual(u.usedEquivalents, 0)
        XCTAssertEqual(u.remainingEquivalents, 140)
    }

    // MARK: - Counts for a mix, and the used = full + half/2 relation

    func testFullAndHalfDayCountsAreCorrectForAMix() {
        // 3 full (incl. ignored 0h day) + 2 half.
        let days = [day(8), day(5), day(0), day(4), day(1), day(9)]
        let u = usage(days)
        XCTAssertEqual(u.fullDays, 3)   // 8, 5, 9
        XCTAssertEqual(u.halfDays, 2)   // 4, 1  (0 ignored)
        XCTAssertEqual(u.usedEquivalents, 3.0 + 2.0 * 0.5)  // 4.0
        XCTAssertEqual(u.remainingEquivalents, 136)
    }

    // MARK: - Injected allowance (value-independent)

    func testCustomAllowanceIsHonoured() {
        // 6-hour threshold → a 5h day becomes a half day, not a full day.
        let allowance = WorkAllowance(maxFullDays: 10, halfDayMaxHours: 6.0)
        let u = WorkingHoursTracker.usage(days: [day(5), day(7)], allowance: allowance)
        XCTAssertEqual(u.halfDays, 1)  // 5h
        XCTAssertEqual(u.fullDays, 1)  // 7h
        XCTAssertEqual(u.usedEquivalents, 1.5)
        XCTAssertEqual(u.remainingEquivalents, 8.5)
    }
}
