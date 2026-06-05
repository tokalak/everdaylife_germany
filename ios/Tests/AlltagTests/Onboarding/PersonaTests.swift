import XCTest
@testable import Alltag

/// Entity rules for `Persona` (D2) and persistence in `PersonaStore` (P2-02).
@MainActor
final class PersonaTests: XCTestCase {

    func testFivePersonasInBriefOrder() {
        XCTAssertEqual(
            Persona.allCases,
            [.tourist, .student, .worker, .family, .resident])
    }

    func testEachPersonaHasADistinctSymbol() {
        let symbols = Persona.allCases.map(\.systemImage)
        XCTAssertEqual(Set(symbols).count, symbols.count)
    }
}

@MainActor
final class PersonaStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "alltag.tests.persona.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testStartsWithNoSelection() {
        let store = PersonaStore(defaults: defaults)
        XCTAssertNil(store.activePersona)
        XCTAssertFalse(store.hasSelection)
    }

    func testSelectionPersistsAcrossInstances() {
        PersonaStore(defaults: defaults).select(.worker)
        let reloaded = PersonaStore(defaults: defaults)
        XCTAssertEqual(reloaded.activePersona, .worker)
        XCTAssertTrue(reloaded.hasSelection)
    }

    func testReselectingOverwrites() {
        let store = PersonaStore(defaults: defaults)
        store.select(.student)
        store.select(.family)
        XCTAssertEqual(store.activePersona, .family)
    }
}
