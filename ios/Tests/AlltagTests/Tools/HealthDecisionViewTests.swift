import SwiftUI
import XCTest
@testable import Alltag

/// GKV vs PKV decision-tree screen (P6-W5): render-smoke across the trait matrix
/// for a couple of states — employee-below (income shown) and self-employed-choice
/// (income hidden) (A-06).
@MainActor
final class HealthDecisionViewTests: XCTestCase {

    func testRendersEmployeeBelow() {
        SnapshotSupport.assertRenders(
            HealthDecisionView(status: .employee, income: 45_000, embedInScrollView: false),
            height: 2600)
    }

    func testRendersSelfEmployedChoice() {
        SnapshotSupport.assertRenders(
            HealthDecisionView(status: .selfEmployed, embedInScrollView: false),
            height: 2600)
    }
}
