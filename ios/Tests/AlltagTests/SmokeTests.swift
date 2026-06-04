import XCTest
@testable import Alltag

/// Foundation-phase smoke test (P0-01 / A-04).
///
/// Proves the unit-test target is wired up and the red/green TDD loop runs in
/// both Xcode and CI (P0-02). Real feature tests replace/augment this from
/// P0-03 onward, each landing test-first.
final class SmokeTests: XCTestCase {
    func testTestHarnessRuns() {
        XCTAssertEqual(2 + 2, 4)
    }

    @MainActor
    func testRootViewInstantiates() {
        _ = RootView()
    }
}
