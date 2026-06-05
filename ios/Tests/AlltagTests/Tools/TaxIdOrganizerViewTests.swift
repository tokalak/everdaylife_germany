import SwiftUI
import XCTest
@testable import Alltag

/// Tax-ID & Steuernummer organizer screen (P6-W6): render-smoke across the trait
/// matrix for the default state and a state with a typed Steuer-ID (A-06).
@MainActor
final class TaxIdOrganizerViewTests: XCTestCase {

    func testRendersDefault() {
        SnapshotSupport.assertRenders(
            TaxIdOrganizerView(embedInScrollView: false),
            height: 2600)
    }

    func testRendersWithTypedValue() {
        SnapshotSupport.assertRenders(
            TaxIdOrganizerView(steuerIDInput: "02476291358", embedInScrollView: false),
            height: 2600)
    }
}
