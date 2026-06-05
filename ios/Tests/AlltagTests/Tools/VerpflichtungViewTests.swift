import SwiftUI
import XCTest
@testable import Alltag

/// Verpflichtungserklärung explainer screen (P6-T3): render-smoke across the
/// trait matrix (A-06).
@MainActor
final class VerpflichtungViewTests: XCTestCase {

    func testRendersDefault() {
        SnapshotSupport.assertRenders(
            VerpflichtungView(embedInScrollView: false),
            height: 2200)
    }
}
