import SwiftUI
import XCTest
@testable import Alltag

/// Kita/school enrollment screen (P6-F6): render-smoke across the trait matrix
/// (A-06 / X-02). The screen is static content + a session-only step list, so a
/// single render exercises every section and step.
@MainActor
final class KitaSchoolViewTests: XCTestCase {

    func testRenders() {
        SnapshotSupport.assertRenders(
            KitaSchoolView(embedInScrollView: false), height: 1400)
    }
}
