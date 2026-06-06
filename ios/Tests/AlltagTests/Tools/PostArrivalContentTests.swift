import XCTest
@testable import Alltag

/// Tests for the Post-arrival checklist content (P6-F4).
///
/// The content is the value here, so the catalog's shape is asserted: the steps
/// are non-empty with unique ids and non-empty keys, the order leads with the
/// Anmeldung (it gates most other steps), and the `residence_permit` guide the
/// "learn more" link targets must ship in `GuideLibrary`.
final class PostArrivalContentTests: XCTestCase {

    func testStepsPopulated() {
        let steps = PostArrivalContent.steps
        XCTAssertGreaterThanOrEqual(steps.count, 3)
        XCTAssertEqual(
            Set(steps.map(\.id)).count, steps.count,
            "step ids must be unique")
        for s in steps {
            XCTAssertFalse(s.id.isEmpty)
            XCTAssertFalse(s.titleKey.isEmpty)
            if let detail = s.detailKey {
                XCTAssertFalse(detail.isEmpty, "an optional detail key, if present, must be non-empty")
            }
        }
    }

    func testAnmeldungIsFirst() {
        XCTAssertEqual(
            PostArrivalContent.steps.first?.id, "anmeldung",
            "Anmeldung must lead — it gates the tax-ID, bank account and most other steps")
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
