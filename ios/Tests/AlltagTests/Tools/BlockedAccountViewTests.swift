import SwiftUI
import XCTest
@testable import Alltag

/// Blocked-account (Sperrkonto) comparison screen (P6-S2): render-smoke across
/// the trait matrix for the default ranked list and the English-support filter
/// (A-06).
@MainActor
final class BlockedAccountViewTests: XCTestCase {

    func testRendersDefault() {
        SnapshotSupport.assertRenders(
            BlockedAccountView(embedInScrollView: false), height: 2400)
    }

    func testRendersEnglishOnly() {
        SnapshotSupport.assertRenders(
            BlockedAccountView(englishOnly: true, embedInScrollView: false), height: 2400)
    }
}
