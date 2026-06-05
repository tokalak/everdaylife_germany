import XCTest
@testable import Alltag

/// Embassy document checklist logic (P6-T2). The engine is pure content
/// assembly (A-05): every purpose returns a non-empty list = common documents +
/// purpose-specific ones; the common documents appear in every purpose; each
/// purpose carries its own characteristic documents; ids are unique within a
/// purpose; and the "learn more" guide actually ships.
final class EmbassyChecklistEngineTests: XCTestCase {

    private func documents(_ purpose: VisaPurpose) -> [ChecklistDocument] {
        EmbassyChecklistEngine.documents(for: purpose)
    }

    private func ids(_ purpose: VisaPurpose) -> Set<String> {
        Set(documents(purpose).map(\.id))
    }

    func testEveryPurposeReturnsNonEmptyList() {
        for purpose in VisaPurpose.allCases {
            XCTAssertFalse(documents(purpose).isEmpty, "\(purpose) should have documents")
        }
    }

    func testCommonDocumentsAppearInEveryPurpose() {
        let common = Set(EmbassyChecklistCatalog.common.map(\.id))
        XCTAssertFalse(common.isEmpty)
        for purpose in VisaPurpose.allCases {
            XCTAssertTrue(common.isSubset(of: ids(purpose)),
                          "\(purpose) must include every common document")
        }
    }

    func testDocumentIdsAreUniqueWithinEachPurpose() {
        for purpose in VisaPurpose.allCases {
            let list = documents(purpose).map(\.id)
            XCTAssertEqual(Set(list).count, list.count, "\(purpose) document ids must be unique")
        }
    }

    func testCommonDocumentsComeFirst() {
        let commonCount = EmbassyChecklistCatalog.common.count
        for purpose in VisaPurpose.allCases {
            let prefix = documents(purpose).prefix(commonCount).map(\.id)
            XCTAssertEqual(prefix, EmbassyChecklistCatalog.common.map(\.id),
                           "\(purpose) should list common documents first, in order")
        }
    }

    func testShortStayIncludesTravelItinerary() {
        XCTAssertTrue(ids(.shortStay).contains("travel_itinerary"))
    }

    func testWorkIncludesEmploymentContract() {
        XCTAssertTrue(ids(.work).contains("employment_contract"))
    }

    func testStudyIncludesAdmissionLetter() {
        XCTAssertTrue(ids(.study).contains("admission_letter"))
    }

    func testFamilyIncludesCivilCertificate() {
        XCTAssertTrue(ids(.family).contains("civil_certificate"))
    }

    func testPurposeSpecificDocumentsAreExclusiveToTheirPurpose() {
        // The characteristic document of each purpose must not leak into others.
        let signatures: [VisaPurpose: String] = [
            .shortStay: "travel_itinerary",
            .work: "employment_contract",
            .study: "admission_letter",
            .family: "civil_certificate",
        ]
        for (purpose, marker) in signatures {
            for other in VisaPurpose.allCases where other != purpose {
                XCTAssertFalse(ids(other).contains(marker),
                               "\(marker) should not appear in \(other)")
            }
        }
    }

    func testLongStayPurposesAreFlaggedShortStayIsNot() {
        XCTAssertFalse(VisaPurpose.shortStay.isLongStay)
        XCTAssertTrue(VisaPurpose.work.isLongStay)
        XCTAssertTrue(VisaPurpose.study.isLongStay)
        XCTAssertTrue(VisaPurpose.family.isLongStay)
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
