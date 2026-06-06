import SwiftUI
import XCTest
@testable import Alltag

/// Birth-registration (Standesamt) sub-flow screen (P6-F7): render-smoke across
/// the trait matrix (A-06 / X-02). The screen is static content + a session-only
/// checklist, so a single render exercises every section, the documents, the
/// follow-up steps and the learn-more link.
@MainActor
final class BirthRegistrationViewTests: XCTestCase {

    func testRenders() {
        SnapshotSupport.assertRenders(
            BirthRegistrationView(embedInScrollView: false), height: 1600)
    }
}
