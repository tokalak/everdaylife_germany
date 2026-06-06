import SwiftUI
import XCTest
@testable import Alltag

/// Pre-arrival survival kit screen (P6-T6): render-smoke across the trait matrix
/// (A-06).
@MainActor
final class SurvivalKitViewTests: XCTestCase {

    func testRendersDefault() {
        SnapshotSupport.assertRenders(
            SurvivalKitView(embedInScrollView: false),
            height: 2600)
    }
}
