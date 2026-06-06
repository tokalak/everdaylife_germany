import XCTest
@testable import Alltag

/// Tests for the Family-reunification quick guide content (P6-R5).
///
/// The content is the value here, so the catalog's shape is asserted: sections
/// are present with unique ids and each carries at least one body block; the
/// step list is non-empty with unique ids. All keys must be non-empty. The
/// `residence_permit` guide the "learn more" link targets must ship in
/// `GuideLibrary`.
final class ReunificationGuideContentTests: XCTestCase {

    func testSectionsPopulated() {
        let sections = ReunificationGuideContent.sections
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

    func testStepsPopulated() {
        let steps = ReunificationGuideContent.steps
        XCTAssertGreaterThanOrEqual(steps.count, 3)
        XCTAssertEqual(
            Set(steps.map(\.id)).count, steps.count,
            "step ids must be unique")
        for step in steps {
            XCTAssertFalse(step.id.isEmpty)
            XCTAssertFalse(step.titleKey.isEmpty)
        }
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
