import SwiftUI
import XCTest
@testable import Alltag

/// Embassy document checklist screen (P6-T2): render-smoke across the trait
/// matrix for a couple of visa purposes (A-06 / X-02).
@MainActor
final class EmbassyChecklistViewTests: XCTestCase {

    func testRendersShortStayPurpose() {
        SnapshotSupport.assertRenders(
            EmbassyChecklistView(purpose: .shortStay, embedInScrollView: false),
            height: 1600)
    }

    func testRendersStudyPurpose() {
        SnapshotSupport.assertRenders(
            EmbassyChecklistView(purpose: .study, embedInScrollView: false),
            height: 1600)
    }
}
