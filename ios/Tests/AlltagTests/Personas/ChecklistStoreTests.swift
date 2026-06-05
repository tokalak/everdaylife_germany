import XCTest
import SwiftData
@testable import Alltag

/// Per-persona checklist progress (P4-01/03): toggling, counts/fractions, and the
/// central guarantee that switching mode **preserves progress** (D1).
@MainActor
final class ChecklistStoreTests: XCTestCase {
    private var persistence: PersistenceController!
    private var store: ChecklistStore!

    override func setUp() async throws {
        persistence = try CalendarTestFactory.persistence()
        store = ChecklistStore(context: persistence.container.mainContext)
    }

    func testStartsEmpty() {
        XCTAssertEqual(store.completedCount(in: .worker), 0)
        XCTAssertEqual(store.fraction(in: .worker), 0)
        XCTAssertFalse(store.isDone("anmeldung", in: .worker))
    }

    func testTogglePersists() throws {
        store.toggle("anmeldung", in: .worker)
        XCTAssertTrue(store.isDone("anmeldung", in: .worker))
        XCTAssertEqual(store.completedCount(in: .worker), 1)

        store.toggle("anmeldung", in: .worker)
        XCTAssertFalse(store.isDone("anmeldung", in: .worker))
        XCTAssertEqual(store.completedCount(in: .worker), 0)
    }

    func testProgressSurvivesAReload() throws {
        store.setDone("anmeldung", in: .worker, true)
        store.setDone("bank_account", in: .worker, true)

        // New store over the same container == app relaunch / store reopen.
        let reloaded = ChecklistStore(context: persistence.container.mainContext)
        XCTAssertTrue(reloaded.isDone("anmeldung", in: .worker))
        XCTAssertTrue(reloaded.isDone("bank_account", in: .worker))
        XCTAssertEqual(reloaded.completedCount(in: .worker), 2)
    }

    func testSwitchingPersonaPreservesEachPersonasProgress() {
        // Progress is keyed by persona, so ticks in one mode never bleed into,
        // or get cleared by, another (D1 — switch without losing progress).
        store.setDone("anmeldung", in: .worker, true)
        store.setDone("some_item", in: .student, true)

        XCTAssertTrue(store.isDone("anmeldung", in: .worker))
        XCTAssertFalse(store.isDone("anmeldung", in: .student))
        XCTAssertTrue(store.isDone("some_item", in: .student))
        XCTAssertEqual(store.completedCount(in: .worker), 1)
    }

    func testFractionTracksCatalog() {
        let total = store.totalCount(in: .worker)
        XCTAssertGreaterThan(total, 0)
        store.setDone("anmeldung", in: .worker, true)
        XCTAssertEqual(store.fraction(in: .worker), 1.0 / Double(total), accuracy: 0.0001)
    }

    func testCompletedCountIgnoresItemsNotInCatalog() {
        // A stale tick for a removed/unknown item must not inflate progress.
        store.setDone("ghost_item", in: .worker, true)
        XCTAssertEqual(store.completedCount(in: .worker), 0)
    }

    func testRemoveAllClearsEverything() {
        store.setDone("anmeldung", in: .worker, true)
        store.setDone("x", in: .student, true)
        store.removeAll()
        XCTAssertEqual(store.completedCount(in: .worker), 0)
        XCTAssertFalse(store.isDone("x", in: .student))
    }
}
