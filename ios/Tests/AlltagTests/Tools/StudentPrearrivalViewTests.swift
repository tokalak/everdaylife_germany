import SwiftUI
import XCTest
@testable import Alltag

/// Pre-arrival-by-nationality screen (P6-S1): render-smoke across the trait
/// matrix for one seeded nationality per entry route (A-06 / X-02).
@MainActor
final class StudentPrearrivalViewTests: XCTestCase {

    func testRendersFreeMovement() {
        SnapshotSupport.assertRenders(
            StudentPrearrivalView(regionCode: "DE", embedInScrollView: false), height: 1000)
    }

    func testRendersVisaFreeEntryThenPermit() {
        SnapshotSupport.assertRenders(
            StudentPrearrivalView(regionCode: "US", embedInScrollView: false), height: 1100)
    }

    func testRendersNationalVisaRequired() {
        SnapshotSupport.assertRenders(
            StudentPrearrivalView(regionCode: "IN", embedInScrollView: false), height: 1100)
    }
}
