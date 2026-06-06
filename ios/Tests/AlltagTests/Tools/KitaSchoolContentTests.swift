import XCTest
@testable import Alltag

/// Tests for the Kita/school enrollment content (P6-F6).
///
/// The content is the value here, so the catalog's shape is asserted: sections
/// are present with unique ids and each carries at least one body block; the
/// practical steps are non-empty with unique ids. All keys must be non-empty.
final class KitaSchoolContentTests: XCTestCase {

    func testSectionsPopulated() {
        let sections = KitaSchoolContent.sections
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
        let steps = KitaSchoolContent.steps
        XCTAssertGreaterThanOrEqual(steps.count, 3)
        XCTAssertEqual(
            Set(steps.map(\.id)).count, steps.count,
            "step ids must be unique")
        for step in steps {
            XCTAssertFalse(step.id.isEmpty)
            XCTAssertFalse(step.titleKey.isEmpty)
        }
    }
}
