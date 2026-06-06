import SwiftUI
import XCTest
@testable import Alltag

/// Family-reunification visa checklist screen (P6-F1): render-smoke across the
/// trait matrix for a couple of family relations (A-06 / X-02).
@MainActor
final class ReunificationChecklistViewTests: XCTestCase {

    func testRendersSpouseRelation() {
        SnapshotSupport.assertRenders(
            ReunificationChecklistView(relation: .spouse, embedInScrollView: false),
            height: 1600)
    }

    func testRendersChildRelation() {
        SnapshotSupport.assertRenders(
            ReunificationChecklistView(relation: .child, embedInScrollView: false),
            height: 1600)
    }
}
