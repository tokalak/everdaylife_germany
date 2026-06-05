import SwiftUI
import XCTest
@testable import Alltag

/// Bank-account comparison screen (P6-W4): render-smoke across the trait matrix
/// for the default ranked list and the English-support filter (A-06).
@MainActor
final class BankCompareViewTests: XCTestCase {

    func testRendersDefault() {
        SnapshotSupport.assertRenders(
            BankCompareView(embedInScrollView: false), height: 2200)
    }

    func testRendersEnglishOnly() {
        SnapshotSupport.assertRenders(
            BankCompareView(englishOnly: true, embedInScrollView: false), height: 2200)
    }
}
