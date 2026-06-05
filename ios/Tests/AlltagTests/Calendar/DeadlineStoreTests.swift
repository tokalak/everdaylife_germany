import XCTest
import SwiftData
@testable import Alltag

/// CRUD + reminder-scheduling behaviour of ``DeadlineStore`` (P3-07/08), against
/// an in-memory store and a recording scheduler.
@MainActor
final class DeadlineStoreTests: XCTestCase {
    private var scheduler: RecordingReminderScheduler!
    private var store: DeadlineStore!
    /// Retained so its ModelContainer outlives the store (see CalendarTestFactory).
    private var persistence: PersistenceController!

    override func setUp() async throws {
        scheduler = RecordingReminderScheduler()
        persistence = try CalendarTestFactory.persistence()
        store = DeadlineStore(
            context: persistence.container.mainContext, scheduler: scheduler)
    }

    /// The store schedules reminders on a detached Task; spin until the recorder
    /// reaches the expected counts (or time out).
    private func waitForScheduler(
        scheduled: Int? = nil, cancelled: Int? = nil
    ) async {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            let s = await scheduler.scheduledRequests().count
            let c = await scheduler.cancelledRequests().count
            if (scheduled == nil || s >= scheduled!) && (cancelled == nil || c >= cancelled!) {
                return
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    func testAddInsertsAndSchedulesReminders() async {
        let deadline = store.add(
            title: "Confirm address", dueDate: CalendarTestFactory.date(daysFromNow: 30),
            severity: .urgent)

        XCTAssertEqual(store.deadlines.count, 1)
        XCTAssertEqual(store.deadlines.first?.title, "Confirm address")

        await waitForScheduler(scheduled: 1)
        let requests = await scheduler.scheduledRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.id, deadline.id)
        XCTAssertEqual(requests.first?.offsetsInDays, [14, 7, 1])
        XCTAssertEqual(requests.first?.idPrefix, "deadline")
        XCTAssertEqual(requests.first?.body, "Confirm address")
    }

    func testSetDoneCancelsRemindersButKeepsRecord() async {
        let deadline = store.add(title: "x", dueDate: CalendarTestFactory.date(daysFromNow: 10))
        store.setDone(deadline, true)

        XCTAssertEqual(store.deadlines.count, 1, "done deadlines are kept")
        XCTAssertTrue(store.deadlines.first?.isDone ?? false)
        await waitForScheduler(cancelled: 1)
        let cancelledCount = await scheduler.cancelledRequests().count
        XCTAssertEqual(cancelledCount, 1)
    }

    func testReopeningDoneReschedules() async {
        let deadline = store.add(title: "x", dueDate: CalendarTestFactory.date(daysFromNow: 10))
        store.setDone(deadline, true)
        store.setDone(deadline, false)

        await waitForScheduler(scheduled: 2)
        let scheduledCount = await scheduler.scheduledRequests().count
        XCTAssertGreaterThanOrEqual(scheduledCount, 2)
        XCTAssertFalse(store.deadlines.first?.isDone ?? true)
    }

    func testRemoveDeletesAndCancels() async {
        let deadline = store.add(title: "x", dueDate: CalendarTestFactory.date(daysFromNow: 10))
        store.remove(deadline)

        XCTAssertTrue(store.deadlines.isEmpty)
        await waitForScheduler(cancelled: 1)
        let cancelledCount = await scheduler.cancelledRequests().count
        XCTAssertEqual(cancelledCount, 1)
    }

    func testUpsertUpdatesExistingBySource() async {
        let first = store.upsert(
            source: .vault, sourceId: "doc-1", title: "Passport expires",
            dueDate: CalendarTestFactory.date(daysFromNow: 60))
        let second = store.upsert(
            source: .vault, sourceId: "doc-1", title: "Passport expires (updated)",
            dueDate: CalendarTestFactory.date(daysFromNow: 90))

        XCTAssertEqual(first.id, second.id, "same source+id updates, not duplicates")
        XCTAssertEqual(store.deadlines.count, 1)
        XCTAssertEqual(store.deadlines.first?.title, "Passport expires (updated)")
    }

    func testUpsertDifferentSourceIdsCoexist() {
        store.upsert(source: .vault, sourceId: "a", title: "A",
                     dueDate: CalendarTestFactory.date(daysFromNow: 10))
        store.upsert(source: .vault, sourceId: "b", title: "B",
                     dueDate: CalendarTestFactory.date(daysFromNow: 20))
        XCTAssertEqual(store.deadlines.count, 2)
    }

    func testRemoveAllClearsEverything() {
        store.add(title: "a", dueDate: CalendarTestFactory.date(daysFromNow: 1))
        store.add(title: "b", dueDate: CalendarTestFactory.date(daysFromNow: 2))
        store.removeAll()
        XCTAssertTrue(store.deadlines.isEmpty)
    }

    func testGroupsReflectStoredDeadlines() {
        store.add(title: "overdue", dueDate: CalendarTestFactory.date(daysFromNow: -2))
        store.add(title: "soon", dueDate: CalendarTestFactory.date(daysFromNow: 3))
        let buckets = store.groups().map(\.bucket)
        XCTAssertEqual(buckets, [.overdue, .thisWeek])
    }
}
