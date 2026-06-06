import SwiftUI
import XCTest
@testable import Alltag

/// Post-study transition screen (P6-S6): render-smoke across the trait matrix
/// (A-06 / X-02). The screen is static content + a session-only checklist, so a
/// single render exercises every section, the checklist and the learn-more link.
@MainActor
final class PostStudyViewTests: XCTestCase {

    func testRenders() {
        SnapshotSupport.assertRenders(
            PostStudyView(embedInScrollView: false), height: 1400)
    }
}
