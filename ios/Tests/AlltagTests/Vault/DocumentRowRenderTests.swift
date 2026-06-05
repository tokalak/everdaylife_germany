import SwiftUI
import XCTest
@testable import Alltag

/// Render-smoke coverage for the Vault row across categories + expiry states and
/// the trait matrix (light/dark · Dynamic Type · RTL) — A-06 / X-02.
@MainActor
final class DocumentRowRenderTests: XCTestCase {
    func testRendersAcrossCategories() {
        for category in DocumentCategory.allCases {
            let doc = DocumentRecord(fileName: "Important paper", category: category.rawValue)
            SnapshotSupport.assertRenders(DocumentRow(document: doc))
        }
    }

    func testRendersExpiryStates() {
        let soon = DocumentRecord(
            fileName: "Residence permit", category: DocumentCategory.identity.rawValue,
            expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 10))
        let expired = DocumentRecord(
            fileName: "Old passport", category: DocumentCategory.identity.rawValue,
            expiresAt: Date().addingTimeInterval(-60 * 60 * 24 * 10))
        SnapshotSupport.assertRenders(DocumentRow(document: soon))
        SnapshotSupport.assertRenders(DocumentRow(document: expired))
    }
}
