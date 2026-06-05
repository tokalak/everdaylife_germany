import XCTest
@testable import Alltag

/// Schengen 90/180 rolling-window counter (P6-T5). This is the A-05 highest-risk
/// surface — the day-counting engine — so it is tested exhaustively against a
/// fixed gregorian/UTC calendar and an injected reference date (no `Date.now`),
/// covering: a single in-window stay (entry & exit inclusive), the remaining =
/// 90 − used relation and its non-negative floor, stays before / straddling the
/// window start, overlapping and adjacent stays not double-counting, the exact
/// 90-day boundary, the empty case, and an invalid exit-before-entry stay.
final class SchengenCounterTests: XCTestCase {

    /// Fixed gregorian/UTC calendar so day math is deterministic.
    private let cal = SchengenCounter.fixedCalendar

    /// A stable reference date: 2026-06-01.
    private lazy var ref: Date = day(2026, 6, 1)

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return cal.date(from: c)!
    }

    private func offset(_ days: Int, from base: Date? = nil) -> Date {
        cal.date(byAdding: .day, value: days, to: base ?? ref)!
    }

    private func usage(_ stays: [SchengenStay], asOf: Date? = nil) -> SchengenUsage {
        SchengenCounter.usage(stays: stays, asOf: asOf ?? ref, calendar: cal)
    }

    // MARK: - Single stay, entry & exit inclusive

    func testSameDayEntryAndExitCountsOneDay() {
        let d = offset(-10)
        let u = usage([SchengenStay(entry: d, exit: d)])
        XCTAssertEqual(u.daysUsed, 1)
    }

    func testTenDayInclusiveRangeCountsTenDays() {
        // entry .. entry+9 inclusive == 10 days.
        let entry = offset(-30)
        let exit = offset(-21)
        let u = usage([SchengenStay(entry: entry, exit: exit)])
        XCTAssertEqual(u.daysUsed, 10)
    }

    func testTimeOfDayDoesNotAffectDayCount() {
        // Same calendar day with different times still counts as one day.
        let base = cal.startOfDay(for: offset(-5))
        let entry = cal.date(byAdding: .hour, value: 23, to: base)!
        let exit = cal.date(byAdding: .hour, value: 1, to: base)!  // earlier time, same day
        let u = usage([SchengenStay(entry: entry, exit: exit)])
        XCTAssertEqual(u.daysUsed, 1)
    }

    // MARK: - remaining = 90 − used, floored at 0

    func testRemainingIsNinetyMinusUsed() {
        let entry = offset(-30)
        let exit = offset(-21)  // 10 days
        let u = usage([SchengenStay(entry: entry, exit: exit)])
        XCTAssertEqual(u.daysRemaining, 80)
        XCTAssertEqual(u.daysRemaining, SchengenUsage.maxDays - u.daysUsed)
    }

    func testOverstayCapsRemainingAtZeroAndUsedExceedsNinety() {
        // 100 inclusive days, all inside the window.
        let entry = offset(-99)
        let exit = ref
        let u = usage([SchengenStay(entry: entry, exit: exit)])
        XCTAssertEqual(u.daysUsed, 100)
        XCTAssertEqual(u.daysRemaining, 0)
    }

    // MARK: - Window edges

    func testStayEntirelyBeforeWindowCountsZero() {
        // Window starts at ref - 179. Put a stay that ends before windowStart.
        let exit = offset(-180)
        let entry = offset(-190)
        let u = usage([SchengenStay(entry: entry, exit: exit)])
        XCTAssertEqual(u.daysUsed, 0)
        XCTAssertEqual(u.daysRemaining, 90)
    }

    func testStayStraddlingWindowStartCountsOnlyInWindowDays() {
        // windowStart = ref - 179. Stay runs ref-189 .. ref-175 (15 inclusive
        // days), of which only ref-179 .. ref-175 = 5 days are in the window.
        let entry = offset(-189)
        let exit = offset(-175)
        let u = usage([SchengenStay(entry: entry, exit: exit)])
        XCTAssertEqual(u.daysUsed, 5)
    }

    func testDayExactlyAtWindowStartIsCounted() {
        let windowStart = offset(-(SchengenUsage.windowDays - 1))  // ref - 179
        let u = usage([SchengenStay(entry: windowStart, exit: windowStart)])
        XCTAssertEqual(u.daysUsed, 1)
    }

    func testReferenceDayItselfIsCounted() {
        let u = usage([SchengenStay(entry: ref, exit: ref)])
        XCTAssertEqual(u.daysUsed, 1)
    }

    func testStayAfterReferenceDateIsNotCounted() {
        let entry = offset(5)
        let exit = offset(10)
        let u = usage([SchengenStay(entry: entry, exit: exit)])
        XCTAssertEqual(u.daysUsed, 0)
    }

    // MARK: - Overlapping / adjacent stays

    func testOverlappingStaysDoNotDoubleCount() {
        let a = SchengenStay(entry: offset(-30), exit: offset(-21))  // 10 days
        let b = SchengenStay(entry: offset(-25), exit: offset(-16))  // overlaps a, extends 5
        // Union is ref-30 .. ref-16 = 15 inclusive days.
        let u = usage([a, b])
        XCTAssertEqual(u.daysUsed, 15)
    }

    func testAdjacentStaysCountSeamlesslyWithoutGapOrDoubleCount() {
        let a = SchengenStay(entry: offset(-20), exit: offset(-11))  // 10 days
        let b = SchengenStay(entry: offset(-10), exit: offset(-1))   // next 10 days
        let u = usage([a, b])
        XCTAssertEqual(u.daysUsed, 20)
    }

    func testIdenticalStaysCountOnce() {
        let a = SchengenStay(entry: offset(-10), exit: offset(-6))  // 5 days
        let b = SchengenStay(entry: offset(-10), exit: offset(-6))  // identical
        let u = usage([a, b])
        XCTAssertEqual(u.daysUsed, 5)
    }

    // MARK: - Boundary at exactly 90

    func testExactlyNinetyDaysUsedLeavesZeroRemaining() {
        // 90 inclusive days: entry = ref - 89.
        let entry = offset(-89)
        let u = usage([SchengenStay(entry: entry, exit: ref)])
        XCTAssertEqual(u.daysUsed, 90)
        XCTAssertEqual(u.daysRemaining, 0)
    }

    func testEightyNineDaysUsedLeavesOneRemaining() {
        let entry = offset(-88)
        let u = usage([SchengenStay(entry: entry, exit: ref)])
        XCTAssertEqual(u.daysUsed, 89)
        XCTAssertEqual(u.daysRemaining, 1)
    }

    // MARK: - Empty + invalid

    func testEmptyStaysGivesZeroUsedAndFullRemaining() {
        let u = usage([])
        XCTAssertEqual(u.daysUsed, 0)
        XCTAssertEqual(u.daysRemaining, 90)
    }

    func testExitBeforeEntryStayIsIgnored() {
        let invalid = SchengenStay(entry: offset(-5), exit: offset(-10))
        let valid = SchengenStay(entry: offset(-3), exit: offset(-1))  // 3 days
        let u = usage([invalid, valid])
        XCTAssertEqual(u.daysUsed, 3)
    }

    // MARK: - Window metadata

    func testWindowStartIsHundredSeventyNineDaysBeforeReference() {
        let u = usage([])
        XCTAssertEqual(u.referenceDate, cal.startOfDay(for: ref))
        XCTAssertEqual(u.windowStart, offset(-(SchengenUsage.windowDays - 1)))
    }

    func testConstantsAreNinetyAndHundredEighty() {
        XCTAssertEqual(SchengenUsage.maxDays, 90)
        XCTAssertEqual(SchengenUsage.windowDays, 180)
    }
}
