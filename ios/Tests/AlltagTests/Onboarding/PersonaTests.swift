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

    func testEachPersonaResolvesADisplayName() {
        // displayName backs the Settings "My mode" row value (P5-05); every
        // persona's title key must resolve to non-empty, distinct copy.
        let names = Persona.allCases.map(\.displayName)
        XCTAssertTrue(names.allSatisfy { !$0.isEmpty })
        XCTAssertEqual(Set(names).count, names.count)
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

    // MARK: - Engaged / past situations (P4-01)

    func testSelectingRecordsEngagedPersona() {
        let store = PersonaStore(defaults: defaults)
        store.select(.worker)
        XCTAssertEqual(store.engagedPersonas, [.worker])
        XCTAssertTrue(store.pastPersonas.isEmpty)
    }

    func testSwitchingKeepsPriorPersonaAsPast() {
        let store = PersonaStore(defaults: defaults)
        store.select(.worker)
        store.select(.student)
        XCTAssertEqual(store.activePersona, .student)
        XCTAssertEqual(store.engagedPersonas, [.worker, .student])
        XCTAssertEqual(store.pastPersonas, [.worker])
    }

    func testReturningToAPersonaDoesNotDuplicateIt() {
        let store = PersonaStore(defaults: defaults)
        store.select(.worker)
        store.select(.student)
        store.select(.worker)
        XCTAssertEqual(store.engagedPersonas, [.worker, .student])
        XCTAssertEqual(store.pastPersonas, [.student])
    }

    func testEngagedSetPersistsAcrossInstances() {
        let store = PersonaStore(defaults: defaults)
        store.select(.worker)
        store.select(.family)
        let reloaded = PersonaStore(defaults: defaults)
        XCTAssertEqual(reloaded.engagedPersonas, [.worker, .family])
        XCTAssertEqual(reloaded.activePersona, .family)
    }
}
