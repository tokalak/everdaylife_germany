import SwiftUI
import XCTest
@testable import Alltag

/// Renewal tracker screen (P6-R4): render-smoke across the trait matrix for a
/// populated state (seeded documents spanning expired / due-soon / upcoming with
/// a fixed `asOf`) and the empty state, so the snapshot is deterministic (A-06).
@MainActor
final class RenewalTrackerViewTests: XCTestCase {

    private let cal = Calendar.current
    private let asOf = Date(timeIntervalSince1970: 1_780_000_000)  // fixed

    private func doc(_ name: String, category: String, dayOffset: Int) -> DocumentRecord {
        DocumentRecord(
            fileName: name,
            category: category,
            expiresAt: cal.date(byAdding: .day, value: dayOffset, to: asOf))
    }

    func testRendersPopulated() {
        let docs = [
            doc("Reisepass", category: "identity", dayOffset: -5),     // expired
            doc("Aufenthaltstitel", category: "identity", dayOffset: 30), // due soon
            doc("Haftpflicht", category: "insurance", dayOffset: 200),  // upcoming
            DocumentRecord(fileName: "Mietvertrag", category: "housing"), // no expiry, excluded
        ]
        SnapshotSupport.assertRenders(
            RenewalTrackerView(documents: docs, asOf: asOf, embedInScrollView: false),
            height: 900)
    }

    func testRendersEmpty() {
        SnapshotSupport.assertRenders(
            RenewalTrackerView(documents: [], asOf: asOf, embedInScrollView: false),
            height: 600)
    }
}
