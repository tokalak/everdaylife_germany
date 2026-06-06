import SwiftUI
import XCTest
@testable import Alltag

/// Post-arrival checklist screen (P6-F4): render-smoke across the trait matrix
/// (A-06 / X-02). The screen is static content + a session-only ordered
/// checklist, so a single render exercises every step row and the learn-more link.
@MainActor
final class PostArrivalViewTests: XCTestCase {

    func testRenders() {
        SnapshotSupport.assertRenders(
            PostArrivalView(embedInScrollView: false), height: 1400)
    }
}
