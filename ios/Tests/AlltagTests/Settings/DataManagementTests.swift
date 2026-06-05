import XCTest
import SwiftData
@testable import Alltag

/// GDPR data controls (P3-09): export summary formatting and delete-all wiring.
@MainActor
final class DataManagementTests: XCTestCase {
    private var persistence: PersistenceController!
    private var vault: VaultStore!
    private var deadlines: DeadlineStore!
    private var controller: DataManagementController!

    override func setUp() async throws {
        persistence = try CalendarTestFactory.persistence()
        let context = persistence.container.mainContext
        let scheduler = RecordingReminderScheduler()
        deadlines = DeadlineStore(context: context, scheduler: scheduler)
        vault = VaultStore(
            context: context, fileStore: .ephemeral(),
            deadlines: deadlines, scheduler: scheduler)
        controller = DataManagementController(vault: vault, deadlines: deadlines)
    }

    func testDeleteAllClearsDocumentsAndDeadlines() throws {
        try vault.add(data: Data("a".utf8), fileName: "ID", category: .identity)
        deadlines.add(title: "Appointment", dueDate: CalendarTestFactory.date(daysFromNow: 5))

        controller.deleteAllData()

        XCTAssertTrue(vault.documents.isEmpty)
        XCTAssertTrue(deadlines.deadlines.isEmpty)
    }

    func testExportWritesSummaryAndDocumentFiles() throws {
        try vault.add(data: Data("scan".utf8), fileName: "Passport", category: .identity)
        deadlines.add(title: "Renew permit", dueDate: CalendarTestFactory.date(daysFromNow: 5))

        let urls = controller.exportItems()

        XCTAssertTrue(urls.contains { $0.lastPathComponent == "Alltag-summary.txt" })
        XCTAssertEqual(urls.filter { $0.pathExtension == "pdf" }.count, 1)
    }

    func testSummaryListsDocumentsAndDeadlines() {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let doc = DocumentRecord(fileName: "Passport", category: "identity")
        let deadline = Deadline(title: "Renew permit", dueDate: now)

        let summary = DataExport.summary(documents: [doc], deadlines: [deadline], now: now)

        XCTAssertTrue(summary.contains("Passport"))
        XCTAssertTrue(summary.contains("Renew permit"))
        XCTAssertTrue(summary.contains("Documents (1)"))
        XCTAssertTrue(summary.contains("Dates (1)"))
    }

    func testSafeFileNameStripsPathCharacters() {
        XCTAssertEqual(DataExport.safeFileName("a/b:c?"), "a-b-c-")
        XCTAssertEqual(DataExport.safeFileName("   "), "document")
        XCTAssertEqual(DataExport.safeFileName("Passport 2026"), "Passport 2026")
    }
}
