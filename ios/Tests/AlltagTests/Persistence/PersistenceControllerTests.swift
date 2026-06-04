import Foundation
import SwiftData
import XCTest
@testable import Alltag

/// A-07 / A-10: the SwiftData stack persists, and data survives a "bundle
/// replacement" (app update) when the on-disk store is reopened.
@MainActor
final class PersistenceControllerTests: XCTestCase {
    func testInMemoryStoreInsertsAndFetches() throws {
        let controller = try PersistenceController(inMemory: true)
        let context = controller.container.mainContext

        context.insert(DocumentRecord(fileName: "Anmeldung"))
        try context.save()

        let all = try context.fetch(FetchDescriptor<DocumentRecord>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.fileName, "Anmeldung")
    }

    /// A-10: write → simulate the app bundle being replaced (a fresh controller
    /// over the *same on-disk store URL*) → read. Data must still be there.
    func testDataSurvivesStoreReopen() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).store")
        defer { cleanUpStore(at: storeURL) }

        let recordID = UUID()
        // First "install": write and let the container deallocate.
        do {
            let controller = try PersistenceController(storeURL: storeURL)
            let context = controller.container.mainContext
            context.insert(DocumentRecord(id: recordID, fileName: "Mietvertrag"))
            try context.save()
        }

        // Second "install" over the same store: the record is still present.
        let reopened = try PersistenceController(storeURL: storeURL)
        let all = try reopened.container.mainContext.fetch(
            FetchDescriptor<DocumentRecord>())
        let match = all.first { $0.id == recordID }
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(match?.fileName, "Mietvertrag")
    }

    private func cleanUpStore(at url: URL) {
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            try? fm.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }
}
