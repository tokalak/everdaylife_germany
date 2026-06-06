import SwiftUI
import XCTest
@testable import Alltag

/// Settlement-permit eligibility screen (P6-R1): render-smoke across the trait
/// matrix for an eligible verdict and a not-yet-eligible verdict (A-06 / X-02).
/// The satisfied set is seeded via the initializer.
@MainActor
final class SettlementEligibilityViewTests: XCTestCase {

    func testRendersNotYetEligibleState() {
        // A partial set → "you may not qualify yet" plus the missing list.
        SnapshotSupport.assertRenders(
            SettlementEligibilityView(
                satisfied: ["residence_period", "german_b1"],
                embedInScrollView: false),
            height: 1400)
    }

    func testRendersEligibleState() {
        // All criteria met → eligible verdict.
        let all = Set(SettlementRule.standardCriteria.map(\.id))
        SnapshotSupport.assertRenders(
            SettlementEligibilityView(satisfied: all, embedInScrollView: false),
            height: 1400)
    }
}
