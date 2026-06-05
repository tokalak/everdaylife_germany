import SwiftUI
import XCTest
@testable import Alltag

/// Visa-fit screen (P6-W1): render-smoke across the trait matrix for the initial
/// state, the qualification follow-up, and a populated result (A-06 / X-02).
@MainActor
final class VisaFitViewTests: XCTestCase {

    func testRendersInitialState() {
        SnapshotSupport.assertRenders(
            VisaFitView(embedInScrollView: false), height: 900)
    }

    func testRendersWorkFollowUpAndResult() {
        // Goal + qualification answered → the result cards render.
        SnapshotSupport.assertRenders(
            VisaFitView(goal: .job, qualification: .academic, embedInScrollView: false),
            height: 1400)
    }

    func testRendersNonWorkResult() {
        SnapshotSupport.assertRenders(
            VisaFitView(goal: .business, embedInScrollView: false), height: 1100)
    }
}
