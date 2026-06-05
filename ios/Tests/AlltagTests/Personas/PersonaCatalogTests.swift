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

    func testEveryPersonaIsPopulated() {
        // Phase 5 (P5-01…04): all five personas now ship a checklist + tools.
        for persona in Persona.allCases {
            XCTAssertGreaterThanOrEqual(
                PersonaCatalog.checklist(for: persona).count, 5,
                "\(persona) checklist should be populated")
            XCTAssertGreaterThanOrEqual(
                PersonaCatalog.tools(for: persona).count, 5,
                "\(persona) tools should be populated")
        }
    }

    func testEveryPersonaHasUniqueChecklistAndToolIds() {
        for persona in Persona.allCases {
            let checklistIds = PersonaCatalog.checklist(for: persona).map(\.id)
            XCTAssertEqual(Set(checklistIds).count, checklistIds.count,
                           "\(persona) checklist ids must be unique")
            let toolIds = PersonaCatalog.tools(for: persona).map(\.id)
            XCTAssertEqual(Set(toolIds).count, toolIds.count,
                           "\(persona) tool ids must be unique")
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

    /// Every checklist deep-link, for every persona, must resolve to a tool in
    /// that persona's own grid or to one of the cross-persona guides — no dangling
    /// references that Home can't open later (Phase 6).
    func testChecklistDeepLinksReferenceRealToolsOrGuides() {
        let guideIds = Set(PersonaCatalog.guides.map(\.id))
        for persona in Persona.allCases {
            let toolIds = Set(PersonaCatalog.tools(for: persona).map(\.id))
            for item in PersonaCatalog.checklist(for: persona) {
                switch item.link {
                case .tool(let id):
                    XCTAssertTrue(toolIds.contains(id),
                                  "dangling tool link in \(persona): \(id)")
                case .guide(let id):
                    XCTAssertTrue(guideIds.contains(id),
                                  "dangling guide link in \(persona): \(id)")
                case .tab, nil:
                    break
                }
            }
        }
    }
}
