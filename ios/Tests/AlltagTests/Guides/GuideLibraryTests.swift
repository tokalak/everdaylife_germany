import XCTest
@testable import Alltag

/// Content rules for `GuideLibrary` (P6-G1…). Guides are versioned content
/// (X-06); these guard the invariants the reader (P6-G6) and search rely on —
/// stable/unique ids, non-empty sections, and tiles that always resolve to a body.
@MainActor
final class GuideLibraryTests: XCTestCase {

    func testResidencePermitGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"),
                        "P6-G1: the residence-permit guide must ship")
    }

    func testResidencePermitMatchesItsHomeTile() {
        // The reader is opened by the Home tile's id; the body must share it.
        let tile = PersonaCatalog.guides.first { $0.id == "residence_permit" }
        XCTAssertNotNil(tile, "residence_permit tile must exist on Home")
        XCTAssertEqual(GuideLibrary.content(for: "residence_permit")?.id, tile?.id)
    }

    func testRegisterBusinessGuideShips() {
        // P6-G2: Gewerbe vs Freiberufler.
        XCTAssertNotNil(GuideLibrary.content(for: "register_business"))
    }

    func testHowTaxesWorkGuideShips() {
        // P6-G3.
        XCTAssertNotNil(GuideLibrary.content(for: "how_taxes_work"))
    }

    func testHealthInsuranceGuideShips() {
        // P6-G4.
        XCTAssertNotNil(GuideLibrary.content(for: "health_insurance"))
    }

    func testDiplomaRecognitionGuideShips() {
        // P6-G5.
        XCTAssertNotNil(GuideLibrary.content(for: "diploma_recognition"))
    }

    /// With P6-G1…G5 all shipped, every Home guide tile must resolve to a body —
    /// no tile that opens to nothing in the reader (P6-G6).
    func testEveryHomeGuideTileHasContent() {
        for tile in PersonaCatalog.guides {
            XCTAssertNotNil(GuideLibrary.content(for: tile.id),
                            "guide tile \(tile.id) has no body in GuideLibrary")
        }
    }

    func testShippedGuideIdsAreUnique() {
        let ids = GuideLibrary.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "guide ids must be unique")
    }

    func testEveryShippedGuideHasContentToRender() {
        for guide in GuideLibrary.all {
            XCTAssertFalse(guide.sections.isEmpty, "\(guide.id) has no sections")
            for section in guide.sections {
                XCTAssertFalse(section.blocks.isEmpty,
                               "\(guide.id)/\(section.id) has no blocks")
            }
        }
    }

    func testSectionIdsAreUniqueWithinEachGuide() {
        for guide in GuideLibrary.all {
            let ids = guide.sections.map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count,
                           "\(guide.id) section ids must be unique")
        }
    }

    func testSourcesUseHttpsLinks() {
        // Sources route to authoritative pages; never ship an insecure link.
        for guide in GuideLibrary.all {
            for source in guide.sources {
                XCTAssertEqual(source.url.scheme, "https",
                               "\(guide.id)/\(source.id) must be https")
            }
        }
    }

    func testResidencePermitIsLegallyConsequential() {
        // Aufenthaltstitel is legal terrain → the reader must carry the RDG note.
        XCTAssertEqual(GuideLibrary.content(for: "residence_permit")?.showsLegalDisclaimer,
                       true)
    }
}
