import SwiftUI
import XCTest
@testable import Alltag

/// Schengen 90/180 counter screen (P6-T5): render-smoke across the trait matrix
/// for a normal under-limit case and an at-/over-limit case, with seeded stays
/// and a fixed reference date so the snapshot is deterministic (A-06).
@MainActor
final class SchengenCounterViewTests: XCTestCase {

    private let cal = SchengenCounter.fixedCalendar

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d
        return cal.date(from: c)!
    }

    private func offset(_ days: Int, from base: Date) -> Date {
        cal.date(byAdding: .day, value: days, to: base)!
    }

    func testRendersNormalCase() {
        let ref = day(2026, 6, 1)
        let stays = [
            SchengenStay(entry: offset(-120, from: ref), exit: offset(-110, from: ref)),
            SchengenStay(entry: offset(-40, from: ref), exit: offset(-26, from: ref)),
        ]
        SnapshotSupport.assertRenders(
            SchengenCounterView(stays: stays, referenceDate: ref, embedInScrollView: false),
            height: 1200)
    }

    func testRendersAtLimitCase() {
        let ref = day(2026, 6, 1)
        // 90 inclusive days ending on the reference date → 0 remaining.
        let stays = [SchengenStay(entry: offset(-89, from: ref), exit: ref)]
        SnapshotSupport.assertRenders(
            SchengenCounterView(stays: stays, referenceDate: ref, embedInScrollView: false),
            height: 1200)
    }
}
