import XCTest
import SwiftData
@testable import Alltag

/// CRUD + encryption + expiry behaviour of ``VaultStore`` (P3-05/06), against an
/// in-memory store, a temp encrypted file store, and a recording scheduler.
@MainActor
final class VaultStoreTests: XCTestCase {
    private var persistence: PersistenceController!
    private var fileStore: EncryptedFileStore!
    private var scheduler: RecordingReminderScheduler!
    private var deadlines: DeadlineStore!
    private var vault: VaultStore!

    override func setUp() async throws {
        persistence = try CalendarTestFactory.persistence()
        let context = persistence.container.mainContext
        fileStore = EncryptedFileStore.ephemeral()
        scheduler = RecordingReminderScheduler()
        deadlines = DeadlineStore(context: context, scheduler: scheduler)
        vault = VaultStore(
            context: context, fileStore: fileStore, deadlines: deadlines, scheduler: scheduler)
    }

    private func waitForScheduled(_ count: Int) async {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if await scheduler.scheduledRequests().count >= count { return }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    func testAddStoresEncryptedBytesAndIndexes() throws {
        let payload = Data("a passport scan".utf8)
        let record = try vault.add(
            data: payload, fileName: "Passport", category: .identity)

        XCTAssertEqual(vault.documents.count, 1)
        XCTAssertEqual(record.categoryValue, .identity)
        // Round-trips through encryption.
        XCTAssertEqual(vault.data(for: record), payload)
    }

    func testGroupingByCategory() throws {
        try vault.add(data: Data("a".utf8), fileName: "ID", category: .identity)
        try vault.add(data: Data("b".utf8), fileName: "Letter", category: .official)
        try vault.add(data: Data("c".utf8), fileName: "Passport", category: .identity)

        let groups = vault.grouped()
        XCTAssertEqual(groups.map(\.category), [.identity, .official])
        XCTAssertEqual(groups.first?.documents.count, 2)
    }

    func testExpiryPopulatesAgendaAndSchedulesReminders() async throws {
        let expiry = CalendarTestFactory.date(daysFromNow: 90)
        try vault.add(
            data: Data("x".utf8), fileName: "Residence permit",
            category: .identity, expiresAt: expiry)

        // Surfaces in the Dates agenda as a .vault deadline.
        XCTAssertEqual(deadlines.deadlines.count, 1)
        XCTAssertEqual(deadlines.deadlines.first?.source, .vault)

        // Schedules expiry reminders at 60/30/7, namespaced "expiry".
        await waitForScheduled(1)
        let requests = await scheduler.scheduledRequests()
        let expiryReq = requests.first { $0.idPrefix == "expiry" }
        XCTAssertNotNil(expiryReq)
        XCTAssertEqual(expiryReq?.offsetsInDays, [60, 30, 7])
    }

    func testVaultDeadlineDoesNotGetDeadlineReminders() async throws {
        // .vault deadlines are visible in the agenda but their reminders are owned
        // by the Vault (60/30/7), not the deadline cadence (14/7/1).
        try vault.add(
            data: Data("x".utf8), fileName: "Permit", category: .identity,
            expiresAt: CalendarTestFactory.date(daysFromNow: 90))
        await waitForScheduled(1)
        let prefixes = await scheduler.scheduledRequests().map(\.idPrefix)
        XCTAssertFalse(prefixes.contains("deadline"), "no 14/7/1 deadline reminders for vault docs")
    }

    func testRemoveDeletesBlobIndexAndAgendaEntry() async throws {
        let record = try vault.add(
            data: Data("x".utf8), fileName: "Permit", category: .identity,
            expiresAt: CalendarTestFactory.date(daysFromNow: 90))
        let id = record.id.uuidString

        vault.remove(record)

        XCTAssertTrue(vault.documents.isEmpty)
        XCTAssertFalse(fileStore.exists(id: id), "encrypted blob deleted")
        XCTAssertTrue(deadlines.deadlines.isEmpty, "agenda entry removed")
    }

    func testRemoveAllClearsEverything() throws {
        try vault.add(data: Data("a".utf8), fileName: "A", category: .identity)
        try vault.add(data: Data("b".utf8), fileName: "B", category: .finance)
        vault.removeAll()
        XCTAssertTrue(vault.documents.isEmpty)
    }
}
