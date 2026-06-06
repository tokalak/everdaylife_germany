import SwiftUI
import XCTest
@testable import Alltag

/// Family-reunification quick guide screen (P6-R5): render-smoke across the trait
/// matrix (A-06 / X-02). The screen is static content + a session-only step list,
/// so a single render exercises every section, the steps and the learn-more link.
@MainActor
final class ReunificationGuideViewTests: XCTestCase {

    func testRenders() {
        SnapshotSupport.assertRenders(
            ReunificationGuideView(embedInScrollView: false), height: 1400)
    }
}
