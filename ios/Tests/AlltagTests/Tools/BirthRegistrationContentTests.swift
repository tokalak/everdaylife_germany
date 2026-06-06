import XCTest
@testable import Alltag

/// Tests for the birth-registration (Standesamt) sub-flow content (P6-F7).
///
/// The content is the value here, so the catalog's shape is asserted: sections
/// are present with unique ids and each carries at least one body block;
/// documents and follow-up steps are non-empty with unique ids; all keys are
/// non-empty. The `residence_permit` guide the "learn more" link targets must
/// ship in `GuideLibrary`.
final class BirthRegistrationContentTests: XCTestCase {

    func testSectionsPopulated() {
        let sections = BirthRegistrationContent.sections
        XCTAssertGreaterThanOrEqual(sections.count, 1)
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

    func testDocumentsPopulated() {
        let docs = BirthRegistrationContent.documents
        XCTAssertGreaterThanOrEqual(docs.count, 1)
        XCTAssertEqual(
            Set(docs.map(\.id)).count, docs.count,
            "document ids must be unique")
        for d in docs {
            XCTAssertFalse(d.id.isEmpty)
            XCTAssertFalse(d.titleKey.isEmpty)
            if let hint = d.hintKey {
                XCTAssertFalse(hint.isEmpty)
            }
        }
    }

    func testStepsPopulated() {
        let steps = BirthRegistrationContent.steps
        XCTAssertGreaterThanOrEqual(steps.count, 1)
        XCTAssertEqual(
            Set(steps.map(\.id)).count, steps.count,
            "step ids must be unique")
        for s in steps {
            XCTAssertFalse(s.id.isEmpty)
            XCTAssertFalse(s.titleKey.isEmpty)
        }
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
