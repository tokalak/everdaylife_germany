import XCTest
@testable import Alltag

/// Short-stay visa-need classification logic (P6-T1). Pure engine, exhaustively
/// tested (A-05): EU/EEA/Switzerland → free movement, Annex II → visa-free,
/// everything else (Annex I, unknown codes) → visa required; case-insensitive.
final class VisaNeedEngineTests: XCTestCase {

    private func result(_ code: String) -> VisaNeedResult {
        VisaNeedEngine.result(for: code)
    }

    func testEUMembersAreFreeMovement() {
        for code in ["DE", "FR", "IT", "ES", "PL"] {
            XCTAssertEqual(result(code), .freeMovement, "\(code) should be free movement")
        }
    }

    func testEEAAndSwitzerlandAreFreeMovement() {
        for code in ["IS", "LI", "NO", "CH"] {
            XCTAssertEqual(result(code), .freeMovement, "\(code) should be free movement")
        }
    }

    func testAnnexIICountriesAreVisaFree() {
        for code in ["US", "GB", "JP", "CA", "AU", "BR", "KR"] {
            XCTAssertEqual(result(code), .visaFreeShortStay, "\(code) should be visa-free")
        }
    }

    func testAnnexICountriesRequireVisa() {
        for code in ["IN", "CN", "NG", "TR", "RU", "EG"] {
            XCTAssertEqual(result(code), .visaRequired, "\(code) should require a visa")
        }
    }

    func testCodeHandlingIsCaseInsensitiveAndTrimmed() {
        XCTAssertEqual(result("de"), .freeMovement)
        XCTAssertEqual(result("us"), .visaFreeShortStay)
        XCTAssertEqual(result(" Jp "), .visaFreeShortStay)
    }

    func testUnknownOrGarbageCodeRequiresVisa() {
        XCTAssertEqual(result("ZZ"), .visaRequired)
        XCTAssertEqual(result(""), .visaRequired)
        XCTAssertEqual(result("???"), .visaRequired)
    }

    func testFreeMovementSetHasExpectedSize() {
        // 27 EU + the 3 EEA-non-EU states (Iceland, Liechtenstein, Norway) +
        // Switzerland (not in the EEA, free movement via a separate agreement)
        // = 31. (Switzerland is counted separately, hence 31 rather than 30.)
        XCTAssertEqual(VisaNeedData.current.freeMovement.count, 31)
    }

    func testVisaFreeSetIsNonEmptyAndUnique() {
        let visaFree = VisaNeedData.current.visaFree
        XCTAssertFalse(visaFree.isEmpty)
        // A Set is inherently unique; assert the codes are well-formed.
        for code in visaFree {
            XCTAssertEqual(code.count, 2, "\(code) is not a 2-letter code")
            XCTAssertEqual(code, code.uppercased(), "\(code) is not uppercased")
        }
    }

    func testFreeMovementAndVisaFreeDoNotOverlap() {
        let data = VisaNeedData.current
        XCTAssertTrue(data.freeMovement.isDisjoint(with: data.visaFree))
    }
}
