import SwiftUI
import XCTest
@testable import Alltag

/// Visa-need screen (P6-T1): render-smoke across the trait matrix for one seeded
/// country per result kind (A-06 / X-02).
@MainActor
final class VisaNeedViewTests: XCTestCase {

    func testRendersFreeMovement() {
        SnapshotSupport.assertRenders(
            VisaNeedView(regionCode: "DE", embedInScrollView: false), height: 800)
    }

    func testRendersVisaFree() {
        SnapshotSupport.assertRenders(
            VisaNeedView(regionCode: "US", embedInScrollView: false), height: 900)
    }

    func testRendersVisaRequired() {
        SnapshotSupport.assertRenders(
            VisaNeedView(regionCode: "IN", embedInScrollView: false), height: 900)
    }
}
