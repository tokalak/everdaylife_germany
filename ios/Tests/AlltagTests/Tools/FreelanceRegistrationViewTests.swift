import SwiftUI
import XCTest
@testable import Alltag

/// Freelance registration screen (P6-W7): render-smoke across the trait matrix
/// for both legal-form paths (A-06 / X-02).
@MainActor
final class FreelanceRegistrationViewTests: XCTestCase {

    func testRendersFreiberuflerPath() {
        SnapshotSupport.assertRenders(
            FreelanceRegistrationView(path: .freiberufler, embedInScrollView: false),
            height: 1500)
    }

    func testRendersGewerbePath() {
        SnapshotSupport.assertRenders(
            FreelanceRegistrationView(path: .gewerbe, embedInScrollView: false),
            height: 1500)
    }
}
