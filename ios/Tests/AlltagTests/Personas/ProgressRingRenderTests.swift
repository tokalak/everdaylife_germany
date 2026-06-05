import SwiftUI
import XCTest
@testable import Alltag

/// Render-smoke coverage for the Home progress ring (P4-02) across fractions and
/// the trait matrix (light/dark · Dynamic Type accessibility · RTL) — A-06 / X-02.
@MainActor
final class ProgressRingRenderTests: XCTestCase {
    func testRendersAcrossFractions() {
        for fraction in [0.0, 0.36, 1.0] {
            SnapshotSupport.assertRenders(ProgressRing(fraction: fraction))
        }
    }

    func testClampsOutOfRangeFractions() {
        // Out-of-range values must not crash the trim/percent maths.
        SnapshotSupport.assertRenders(ProgressRing(fraction: -0.5))
        SnapshotSupport.assertRenders(ProgressRing(fraction: 1.8))
    }
}
