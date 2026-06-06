import XCTest
@testable import Alltag

/// Tests for the Anmeldung guide content (P6-S4, shared with Worker).
///
/// The content is the value here, so the catalog's shape is asserted: sections
/// are present with unique ids and each carries at least one body block; the
/// documents and steps are non-empty with unique ids. All keys must be non-empty.
final class AnmeldungContentTests: XCTestCase {

    func testSectionsPopulated() {
        let sections = AnmeldungContent.sections
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

    func testDocumentsPopulated() {
        let documents = AnmeldungContent.documents
        XCTAssertGreaterThanOrEqual(documents.count, 3)
        XCTAssertEqual(
            Set(documents.map(\.id)).count, documents.count,
            "document ids must be unique")
        for d in documents {
            XCTAssertFalse(d.id.isEmpty)
            XCTAssertFalse(d.titleKey.isEmpty)
            if let hint = d.hintKey {
                XCTAssertFalse(hint.isEmpty)
            }
        }
    }

    func testStepsPopulated() {
        let steps = AnmeldungContent.steps
        XCTAssertGreaterThanOrEqual(steps.count, 3)
        XCTAssertEqual(
            Set(steps.map(\.id)).count, steps.count,
            "step ids must be unique")
        for s in steps {
            XCTAssertFalse(s.id.isEmpty)
            XCTAssertFalse(s.titleKey.isEmpty)
        }
    }
}
