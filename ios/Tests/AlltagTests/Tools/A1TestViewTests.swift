import SwiftUI
import XCTest
@testable import Alltag

/// A1 German test guide screen (P6-F2): render-smoke across the trait matrix
/// (A-06 / X-02). The screen is static content + a session-only checklist, so a
/// single render exercises every section, the booking steps and the learn-more
/// link.
@MainActor
final class A1TestViewTests: XCTestCase {

    func testRenders() {
        SnapshotSupport.assertRenders(
            A1TestView(embedInScrollView: false), height: 1500)
    }
}
