import XCTest
@testable import Alltag

/// Tests for the Pre-arrival survival kit content (P6-T6).
///
/// The content is the value here, so the catalog's shape is asserted: categories
/// are present with unique ids and each carries at least one tip; the
/// before-you-fly checklist is non-empty with unique ids. All keys must be
/// non-empty.
final class SurvivalKitContentTests: XCTestCase {

    func testCategoriesPopulated() {
        let categories = SurvivalKitContent.categories
        XCTAssertGreaterThanOrEqual(categories.count, 3)
        XCTAssertEqual(
            Set(categories.map(\.id)).count, categories.count,
            "category ids must be unique")
        for c in categories {
            XCTAssertFalse(c.id.isEmpty)
            XCTAssertFalse(c.headingKey.isEmpty)
            XCTAssertGreaterThanOrEqual(
                c.tipKeys.count, 1,
                "each category must have at least one tip")
            for tip in c.tipKeys {
                XCTAssertFalse(tip.isEmpty)
            }
        }
    }

    func testChecklistPopulated() {
        let items = SurvivalKitContent.checklist
        XCTAssertGreaterThanOrEqual(items.count, 3)
        XCTAssertEqual(
            Set(items.map(\.id)).count, items.count,
            "checklist ids must be unique")
        for i in items {
            XCTAssertFalse(i.id.isEmpty)
            XCTAssertFalse(i.titleKey.isEmpty)
        }
    }
}
