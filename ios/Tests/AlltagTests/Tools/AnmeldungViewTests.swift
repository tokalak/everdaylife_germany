import SwiftUI
import XCTest
@testable import Alltag

/// Anmeldung guide screen (P6-S4, shared with Worker): render-smoke across the
/// trait matrix (A-06).
@MainActor
final class AnmeldungViewTests: XCTestCase {

    func testRendersDefault() {
        SnapshotSupport.assertRenders(
            AnmeldungView(embedInScrollView: false),
            height: 2200)
    }
}
