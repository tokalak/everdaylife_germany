import SwiftUI
import XCTest
@testable import Alltag

/// Working-hours tracker screen (P6-S5): render-smoke across the trait matrix for
/// a normal under-limit case and an at-/over-limit case, with seeded days so the
/// snapshot is deterministic (A-06).
@MainActor
final class WorkingHoursViewTests: XCTestCase {

    private func day(_ hours: Double) -> WorkDay {
        WorkDay(date: Date(timeIntervalSince1970: 0), hours: hours)
    }

    func testRendersNormalCase() {
        let days = [day(8), day(3), day(6)]
        SnapshotSupport.assertRenders(
            WorkingHoursView(days: days, embedInScrollView: false),
            height: 1200)
    }

    func testRendersAtLimitCase() {
        // 140 full days → 0 remaining (urgent).
        let days = Array(repeating: day(8), count: 140)
        SnapshotSupport.assertRenders(
            WorkingHoursView(days: days, embedInScrollView: false),
            height: 1200)
    }
}
