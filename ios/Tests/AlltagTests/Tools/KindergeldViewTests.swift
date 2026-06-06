import SwiftUI
import XCTest
@testable import Alltag

/// Kindergeld application guide screen (P6-F5): render-smoke across the trait
/// matrix (A-06 / X-02). The screen is static content + a session-only checklist,
/// so a single render exercises the amount callout, every section, the documents,
/// the steps and the learn-more link.
@MainActor
final class KindergeldViewTests: XCTestCase {

    func testRenders() {
        SnapshotSupport.assertRenders(
            KindergeldView(embedInScrollView: false), height: 1600)
    }
}
