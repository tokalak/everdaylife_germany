import SwiftUI
import XCTest
@testable import Alltag

/// Blue Card checker screen (P6-W2): render-smoke across the trait matrix for a
/// passing salary, a failing salary, and the shortage-occupation case (A-06).
@MainActor
final class BlueCardViewTests: XCTestCase {

    func testRendersEligible() {
        SnapshotSupport.assertRenders(
            BlueCardView(salary: 60_000, embedInScrollView: false), height: 1000)
    }

    func testRendersBelowThreshold() {
        SnapshotSupport.assertRenders(
            BlueCardView(salary: 30_000, embedInScrollView: false), height: 1000)
    }

    func testRendersShortageCase() {
        SnapshotSupport.assertRenders(
            BlueCardView(salary: 46_000, isShortage: true, embedInScrollView: false),
            height: 1000)
    }
}
