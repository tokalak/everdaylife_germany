import XCTest
@testable import Alltag

/// Content rules for `PersonaCatalog` (P4-03/04). The catalog is versioned
/// content (X-06); these guard the invariants the rest of the app relies on —
/// stable, unique ids and the worker persona being fully populated.
@MainActor
final class PersonaCatalogTests: XCTestCase {

    func testWorkerChecklistIsPopulated() {
        XCTAssertGreaterThanOrEqual(PersonaCatalog.checklist(for: .worker).count, 5)
    }

    func testWorkerChecklistIdsAreUnique() {
        let ids = PersonaCatalog.checklist(for: .worker).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "checklist item ids must be unique")
    }

    func testWorkerChecklistStartsWithAnmeldung() {
        // Anmeldung gates almost everything else, so it leads the list.
        XCTAssertEqual(PersonaCatalog.checklist(for: .worker).first?.id, "anmeldung")
    }

    func testOtherPersonasHaveNoChecklistYet() {
        // Filled in Phase 5; today they are intentionally empty.
        for persona in [Persona.tourist, .student, .family, .resident] {
            XCTAssertTrue(PersonaCatalog.checklist(for: persona).isEmpty)
            XCTAssertTrue(PersonaCatalog.tools(for: persona).isEmpty)
        }
    }

    func testWorkerToolsArePopulatedAndUnique() {
        let ids = PersonaCatalog.tools(for: .worker).map(\.id)
        XCTAssertGreaterThanOrEqual(ids.count, 5)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testFiveCrossPersonaGuidesShipWithUniqueIds() {
        let ids = PersonaCatalog.guides.map(\.id)
        XCTAssertEqual(ids.count, 5, "all five guides ship in V1 (P6-G1…G5)")
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testChecklistDeepLinksReferenceRealToolsOrGuides() {
        let toolIds = Set(PersonaCatalog.tools(for: .worker).map(\.id))
        let guideIds = Set(PersonaCatalog.guides.map(\.id))
        for item in PersonaCatalog.checklist(for: .worker) {
            switch item.link {
            case .tool(let id):
                XCTAssertTrue(toolIds.contains(id), "dangling tool link: \(id)")
            case .guide(let id):
                XCTAssertTrue(guideIds.contains(id), "dangling guide link: \(id)")
            case .tab, nil:
                break
            }
        }
    }
}
