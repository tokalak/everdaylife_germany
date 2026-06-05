import SwiftUI
import XCTest
@testable import Alltag

/// Travel/visa health-insurance comparison screen (P6-T4): render-smoke across
/// the trait matrix for the default ranked list and the English-support filter
/// (A-06).
@MainActor
final class TravelInsuranceViewTests: XCTestCase {

    func testRendersDefault() {
        SnapshotSupport.assertRenders(
            TravelInsuranceView(embedInScrollView: false), height: 2400)
    }

    func testRendersEnglishOnly() {
        SnapshotSupport.assertRenders(
            TravelInsuranceView(englishOnly: true, embedInScrollView: false), height: 2400)
    }
}
