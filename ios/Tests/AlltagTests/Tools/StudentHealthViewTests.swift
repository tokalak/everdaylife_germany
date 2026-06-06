import SwiftUI
import XCTest
@testable import Alltag

/// Student health-insurance comparison screen (P6-S3): render-smoke across the
/// trait matrix for the default ranked list and the English-support filter
/// (A-06).
@MainActor
final class StudentHealthViewTests: XCTestCase {

    func testRendersDefault() {
        SnapshotSupport.assertRenders(
            StudentHealthView(embedInScrollView: false), height: 2600)
    }

    func testRendersEnglishOnly() {
        SnapshotSupport.assertRenders(
            StudentHealthView(englishOnly: true, embedInScrollView: false), height: 2600)
    }
}
