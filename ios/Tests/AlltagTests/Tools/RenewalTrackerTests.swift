import XCTest
@testable import Alltag

/// Renewal tracker engine (P6-R4). Pure date logic (A-05): exhaustively tested
/// against a fixed gregorian/UTC calendar and an injected reference date (no
/// `Date.now`), covering: documents without an expiry excluded; expired /
/// due-soon / upcoming bands; the exact window boundary; ascending sort by
/// expiry; the empty case; and name/category mapping.
final class RenewalTrackerTests: XCTestCase {

    /// Fixed gregorian/UTC calendar so day math is deterministic.
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    /// Stable reference date: 2026-06-01.
    private lazy var ref: Date = day(2026, 6, 1)

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return cal.date(from: c)!
    }

    private func offset(_ days: Int) -> Date {
        cal.date(byAdding: .day, value: days, to: ref)!
    }

    private func doc(_ name: String, category: String = "identity", expires: Date?) -> DocumentRecord {
        DocumentRecord(fileName: name, category: category, expiresAt: expires)
    }

    private func upcoming(_ docs: [DocumentRecord], window: Int = Renewal.dueSoonWindowDays) -> [Renewal] {
        RenewalTracker.upcoming(documents: docs, asOf: ref, calendar: cal, dueSoonWindowDays: window)
    }

    // MARK: - Inclusion

    func testDocumentsWithoutExpiryAreExcluded() {
        let result = upcoming([
            doc("No expiry A", expires: nil),
            doc("Has expiry", expires: offset(10)),
            doc("No expiry B", expires: nil),
        ])
        XCTAssertEqual(result.map(\.name), ["Has expiry"])
    }

    func testEmptyInputGivesEmptyOutput() {
        XCTAssertTrue(upcoming([]).isEmpty)
    }

    func testAllNilExpiriesGivesEmptyOutput() {
        XCTAssertTrue(upcoming([doc("A", expires: nil), doc("B", expires: nil)]).isEmpty)
    }

    // MARK: - Status bands

    func testExpiredDocumentHasNegativeDaysAndExpiredStatus() {
        let r = upcoming([doc("Passport", expires: offset(-3))]).first!
        XCTAssertEqual(r.daysUntil, -3)
        XCTAssertEqual(r.status, .expired)
    }

    func testDocumentWithinWindowIsDueSoon() {
        let r = upcoming([doc("Permit", expires: offset(30))]).first!
        XCTAssertEqual(r.daysUntil, 30)
        XCTAssertEqual(r.status, .dueSoon)
    }

    func testDocumentBeyondWindowIsUpcoming() {
        let r = upcoming([doc("Insurance", expires: offset(200))]).first!
        XCTAssertEqual(r.daysUntil, 200)
        XCTAssertEqual(r.status, .upcoming)
    }

    func testTodayExpiryIsDueSoon() {
        let r = upcoming([doc("Today", expires: ref)]).first!
        XCTAssertEqual(r.daysUntil, 0)
        XCTAssertEqual(r.status, .dueSoon)
    }

    // MARK: - Window boundary

    func testExactlyWindowDaysIsDueSoon() {
        let r = upcoming([doc("Edge", expires: offset(Renewal.dueSoonWindowDays))]).first!
        XCTAssertEqual(r.daysUntil, Renewal.dueSoonWindowDays)
        XCTAssertEqual(r.status, .dueSoon)
    }

    func testOneDayBeyondWindowIsUpcoming() {
        let r = upcoming([doc("Edge+1", expires: offset(Renewal.dueSoonWindowDays + 1))]).first!
        XCTAssertEqual(r.daysUntil, Renewal.dueSoonWindowDays + 1)
        XCTAssertEqual(r.status, .upcoming)
    }

    func testCustomWindowIsRespected() {
        let r = upcoming([doc("Custom", expires: offset(20))], window: 10).first!
        XCTAssertEqual(r.status, .upcoming)
    }

    // MARK: - Sort

    func testResultsSortedAscendingByExpiry() {
        let result = upcoming([
            doc("Latest", expires: offset(200)),
            doc("Overdue", expires: offset(-10)),
            doc("Soon", expires: offset(15)),
        ])
        XCTAssertEqual(result.map(\.name), ["Overdue", "Soon", "Latest"])
        XCTAssertEqual(result.map(\.expiresAt), [offset(-10), offset(15), offset(200)])
    }

    // MARK: - Mapping

    func testNameAndCategoryAndIdMappedFromDocument() {
        let source = doc("Reisepass", category: "identity", expires: offset(5))
        let r = upcoming([source]).first!
        XCTAssertEqual(r.name, "Reisepass")
        XCTAssertEqual(r.category, .identity)
        XCTAssertEqual(r.id, source.id)
        XCTAssertEqual(r.expiresAt, offset(5))
    }

    func testUnknownCategoryFallsBackToOther() {
        let r = upcoming([doc("Mystery", category: "not-a-real-category", expires: offset(5))]).first!
        XCTAssertEqual(r.category, .other)
    }
}
