import SwiftUI
import XCTest
@testable import Alltag

/// Sponsor document pack screen (P6-F3): render-smoke across the trait matrix
/// (A-06 / X-02). The screen is static grouped content + a session-only
/// checklist, so a single render exercises every group, document row, hint and
/// the learn-more link.
@MainActor
final class SponsorPackViewTests: XCTestCase {

    func testRenders() {
        SnapshotSupport.assertRenders(
            SponsorPackView(embedInScrollView: false), height: 1600)
    }
}
