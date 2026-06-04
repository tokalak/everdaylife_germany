import SwiftUI
import XCTest
@testable import Alltag

/// P0-06: the DI container wires its foundations and the root view mounts.
@MainActor
final class AppEnvironmentTests: XCTestCase {
    func testEnvironmentBuildsWithInMemoryPersistence() throws {
        let env = AppEnvironment(persistence: try PersistenceController(inMemory: true))
        XCTAssertEqual(env.theme.theme, .system)
        XCTAssertEqual(env.language.language, .de)
    }

    func testLiveEnvironmentInstantiates() {
        _ = AppEnvironment.live()
    }

    func testRootViewInstantiatesWithEnvironment() throws {
        let env = AppEnvironment(persistence: try PersistenceController(inMemory: true))
        _ = RootView().environment(env)
    }
}
