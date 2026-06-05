import SwiftUI
import XCTest
@testable import Alltag

/// Render-smoke coverage for the Dates row across severities + done state and the
/// trait matrix (light/dark · Dynamic Type · RTL) — A-06 / X-02.
@MainActor
final class DeadlineRowRenderTests: XCTestCase {
    func testRendersAcrossSeverities() {
        for severity in Severity.allCases {
            let deadline = Deadline(
                title: "Confirm your address · Finanzamt",
                dueDate: Date().addingTimeInterval(60 * 60 * 24 * 6),
                severity: severity, source: .decoded)
            SnapshotSupport.assertRenders(DeadlineRow(deadline: deadline, onToggleDone: {}))
        }
    }

    func testRendersDoneState() {
        let deadline = Deadline(
            title: "Submit tax form", dueDate: Date(), isDone: true)
        SnapshotSupport.assertRenders(DeadlineRow(deadline: deadline, onToggleDone: {}))
    }
}
