import XCTest
@testable import Alltag

/// Pure date math for the agenda (P3-07): day countdowns, bucketing, grouping.
final class DeadlineUrgencyTests: XCTestCase {
    private let cal = Calendar.current
    private lazy var now: Date = cal.date(
        from: DateComponents(year: 2026, month: 6, day: 5, hour: 15))!

    private func at(_ day: Int, hour: Int = 9) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 6, day: day, hour: hour))!
    }

    func testDaysUntilIsDayFloored() {
        // Later the same day → 0, even though clock time differs.
        XCTAssertEqual(DeadlineUrgency.daysUntil(at(5, hour: 23), from: now, calendar: cal), 0)
        XCTAssertEqual(DeadlineUrgency.daysUntil(at(6), from: now, calendar: cal), 1)
        XCTAssertEqual(DeadlineUrgency.daysUntil(at(12), from: now, calendar: cal), 7)
        XCTAssertEqual(DeadlineUrgency.daysUntil(at(4), from: now, calendar: cal), -1)
    }

    func testBuckets() {
        func bucket(day: Int, done: Bool = false) -> DeadlineBucket {
            DeadlineUrgency.bucket(
                for: Deadline(title: "x", dueDate: at(day), isDone: done),
                now: now, calendar: cal)
        }
        XCTAssertEqual(bucket(day: 4), .overdue)
        XCTAssertEqual(bucket(day: 5), .today)
        XCTAssertEqual(bucket(day: 8), .thisWeek)   // 3 days out
        XCTAssertEqual(bucket(day: 12), .thisWeek)  // exactly 7 days
        XCTAssertEqual(bucket(day: 13), .later)     // 8 days out
        XCTAssertEqual(bucket(day: 5, done: true), .done, "done sinks to .done")
    }

    func testGroupingOrdersBucketsAndSortsWithin() {
        let deadlines = [
            Deadline(title: "later-b", dueDate: at(20)),
            Deadline(title: "today", dueDate: at(5)),
            Deadline(title: "later-a", dueDate: at(15)),
            Deadline(title: "overdue", dueDate: at(1)),
            Deadline(title: "done", dueDate: at(6), isDone: true),
        ]
        let groups = DeadlineUrgency.grouped(deadlines, now: now, calendar: cal)

        XCTAssertEqual(groups.map(\.bucket), [.overdue, .today, .later, .done])
        // Within "later", soonest first.
        XCTAssertEqual(groups[2].deadlines.map(\.title), ["later-a", "later-b"])
    }

    func testEmptyBucketsOmitted() {
        let groups = DeadlineUrgency.grouped(
            [Deadline(title: "t", dueDate: at(5))], now: now, calendar: cal)
        XCTAssertEqual(groups.map(\.bucket), [.today])
    }
}
