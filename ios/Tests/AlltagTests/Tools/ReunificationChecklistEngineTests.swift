import XCTest
@testable import Alltag

/// Family-reunification visa checklist logic (P6-F1). The engine is pure content
/// assembly (A-05): every relation returns a non-empty list = common documents +
/// relation-specific ones; the common documents appear in (and lead) every
/// relation; each relation carries its own characteristic documents; ids are
/// unique within a relation; and the "learn more" guide actually ships.
final class ReunificationChecklistEngineTests: XCTestCase {

    private func documents(_ relation: FamilyRelation) -> [ReunificationDocument] {
        ReunificationChecklistEngine.documents(for: relation)
    }

    private func ids(_ relation: FamilyRelation) -> Set<String> {
        Set(documents(relation).map(\.id))
    }

    func testEveryRelationReturnsNonEmptyList() {
        for relation in FamilyRelation.allCases {
            XCTAssertFalse(documents(relation).isEmpty, "\(relation) should have documents")
        }
    }

    func testCommonDocumentsAppearInEveryRelation() {
        let common = Set(ReunificationChecklistCatalog.common.map(\.id))
        XCTAssertFalse(common.isEmpty)
        for relation in FamilyRelation.allCases {
            XCTAssertTrue(common.isSubset(of: ids(relation)),
                          "\(relation) must include every common document")
        }
    }

    func testCommonDocumentsComeFirst() {
        let commonCount = ReunificationChecklistCatalog.common.count
        for relation in FamilyRelation.allCases {
            let prefix = documents(relation).prefix(commonCount).map(\.id)
            XCTAssertEqual(prefix, ReunificationChecklistCatalog.common.map(\.id),
                           "\(relation) should list common documents first, in order")
        }
    }

    func testDocumentIdsAreUniqueWithinEachRelation() {
        for relation in FamilyRelation.allCases {
            let list = documents(relation).map(\.id)
            XCTAssertEqual(Set(list).count, list.count, "\(relation) document ids must be unique")
        }
    }

    func testSpouseIncludesA1AndMarriageCertificate() {
        XCTAssertTrue(ids(.spouse).contains("german_a1"))
        XCTAssertTrue(ids(.spouse).contains("marriage_certificate"))
    }

    func testChildIncludesBirthCertificate() {
        XCTAssertTrue(ids(.child).contains("birth_certificate"))
    }

    func testParentIncludesMinorAndCustodyProof() {
        XCTAssertTrue(ids(.parent).contains("child_is_minor"))
        XCTAssertTrue(ids(.parent).contains("parent_custody"))
    }

    func testRelationSpecificDocumentsAreExclusiveToTheirRelation() {
        // The characteristic document of each relation must not leak into others.
        let signatures: [FamilyRelation: String] = [
            .spouse: "marriage_certificate",
            .child: "birth_certificate",
            .parent: "child_is_minor",
        ]
        for (relation, marker) in signatures {
            for other in FamilyRelation.allCases where other != relation {
                XCTAssertFalse(ids(other).contains(marker),
                               "\(marker) should not appear in \(other)")
            }
        }
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
