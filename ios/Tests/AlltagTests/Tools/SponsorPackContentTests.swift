import XCTest
@testable import Alltag

/// Tests for the Sponsor document pack content (P6-F3).
///
/// The content is the value here, so the catalog's shape is asserted: groups are
/// present with unique ids and each carries at least one document; document ids
/// are unique across the whole pack; all keys are non-empty. The
/// `residence_permit` guide the "learn more" link targets must ship in
/// `GuideLibrary`.
final class SponsorPackContentTests: XCTestCase {

    func testGroupsPopulated() {
        let groups = SponsorPackContent.groups
        XCTAssertGreaterThanOrEqual(groups.count, 4)
        XCTAssertEqual(
            Set(groups.map(\.id)).count, groups.count,
            "group ids must be unique")
        for g in groups {
            XCTAssertFalse(g.id.isEmpty)
            XCTAssertFalse(g.headingKey.isEmpty)
            XCTAssertGreaterThanOrEqual(
                g.documents.count, 1,
                "each group must have at least one document")
            for doc in g.documents {
                XCTAssertFalse(doc.id.isEmpty)
                XCTAssertFalse(doc.titleKey.isEmpty)
                if let hint = doc.hintKey {
                    XCTAssertFalse(hint.isEmpty)
                }
            }
        }
    }

    func testDocumentIdsUniqueAcrossPack() {
        let allDocs = SponsorPackContent.groups.flatMap(\.documents)
        XCTAssertGreaterThanOrEqual(allDocs.count, 4)
        XCTAssertEqual(
            Set(allDocs.map(\.id)).count, allDocs.count,
            "document ids must be unique across the whole pack")
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
