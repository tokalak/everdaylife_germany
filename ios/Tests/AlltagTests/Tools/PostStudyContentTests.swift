import XCTest
@testable import Alltag

/// Tests for the Post-study transition content (P6-S6).
///
/// The content is the value here, so the catalog's shape is asserted: sections
/// are present with unique ids and each carries at least one body block; the
/// transition checklist is non-empty with unique ids. All keys must be
/// non-empty. The `residence_permit` guide the "learn more" link targets must
/// ship in `GuideLibrary`.
final class PostStudyContentTests: XCTestCase {

    func testSectionsPopulated() {
        let sections = PostStudyContent.sections
        XCTAssertGreaterThanOrEqual(sections.count, 3)
        XCTAssertEqual(
            Set(sections.map(\.id)).count, sections.count,
            "section ids must be unique")
        for s in sections {
            XCTAssertFalse(s.id.isEmpty)
            XCTAssertFalse(s.headingKey.isEmpty)
            XCTAssertGreaterThanOrEqual(
                s.bodyKeys.count, 1,
                "each section must have at least one body block")
            for body in s.bodyKeys {
                XCTAssertFalse(body.isEmpty)
            }
        }
    }

    func testChecklistPopulated() {
        let items = PostStudyContent.checklist
        XCTAssertGreaterThanOrEqual(items.count, 3)
        XCTAssertEqual(
            Set(items.map(\.id)).count, items.count,
            "checklist ids must be unique")
        for i in items {
            XCTAssertFalse(i.id.isEmpty)
            XCTAssertFalse(i.titleKey.isEmpty)
        }
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
