import XCTest
@testable import Alltag

/// Tests for the Kindergeld (child benefit) guide content (P6-F5).
///
/// The content is the value here, so the catalog's shape is asserted: sections
/// are present with unique ids and each carries at least one body block;
/// documents and steps are non-empty with unique ids; all keys are non-empty.
/// The versioned monthly rate is a plausible positive figure. The
/// `how_taxes_work` guide the "learn more" link targets must ship in
/// `GuideLibrary`.
final class KindergeldContentTests: XCTestCase {

    func testSectionsPopulated() {
        let sections = KindergeldContent.sections
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
        let docs = KindergeldContent.documents
        XCTAssertGreaterThanOrEqual(docs.count, 1)
        XCTAssertEqual(
            Set(docs.map(\.id)).count, docs.count,
            "document ids must be unique")
        for d in docs {
            XCTAssertFalse(d.id.isEmpty)
            XCTAssertFalse(d.titleKey.isEmpty)
        }
    }

    func testStepsPopulated() {
        let steps = KindergeldContent.steps
        XCTAssertGreaterThanOrEqual(steps.count, 1)
        XCTAssertEqual(
            Set(steps.map(\.id)).count, steps.count,
            "step ids must be unique")
        for s in steps {
            XCTAssertFalse(s.id.isEmpty)
            XCTAssertFalse(s.titleKey.isEmpty)
        }
    }

    func testMonthlyRateIsPlausible() {
        let rate = KindergeldContent.rate
        XCTAssertGreaterThan(rate.monthlyPerChild, 0)
        // A sane band for a per-child monthly benefit; flags a typo, not policy.
        XCTAssertGreaterThan(rate.monthlyPerChild, 50)
        XCTAssertLessThan(rate.monthlyPerChild, 1_000)
        XCTAssertGreaterThan(rate.year, 2020)
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "how_taxes_work"))
    }
}
