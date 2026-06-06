import XCTest
@testable import Alltag

/// Pre-arrival-by-nationality classification logic (P6-S1). Pure engine,
/// exhaustively tested (A-05): EU/EEA/Switzerland → free movement; the §41
/// AufenthV privileged set → visa-free entry then permit; everything else
/// (including unknown codes) → national visa required; case-insensitive. Each
/// route's checklist is non-empty with unique step ids; the privileged set has
/// exactly 8 members; the "learn more" guide ships.
final class StudentPrearrivalEngineTests: XCTestCase {

    private func route(_ code: String) -> StudentEntryRoute {
        StudentPrearrivalEngine.route(for: code)
    }

    func testEUAndEEACountriesAreFreeMovement() {
        for code in ["DE", "FR", "IT", "ES", "PL", "IS", "NO", "CH"] {
            XCTAssertEqual(route(code), .freeMovement, "\(code) should be free movement")
        }
    }

    func testPrivilegedCountriesEnterVisaFreeThenPermit() {
        for code in ["US", "GB", "JP", "CA", "AU", "KR", "NZ", "IL"] {
            XCTAssertEqual(route(code), .visaFreeEntryThenPermit, "\(code) should be visa-free entry then permit")
        }
    }

    func testOtherCountriesRequireNationalVisa() {
        for code in ["IN", "CN", "NG", "TR", "RU", "EG"] {
            XCTAssertEqual(route(code), .nationalVisaRequired, "\(code) should require a national visa")
        }
    }

    func testRouteIsCaseInsensitiveAndTrimmed() {
        XCTAssertEqual(route("de"), .freeMovement)
        XCTAssertEqual(route("us"), .visaFreeEntryThenPermit)
        XCTAssertEqual(route(" Jp "), .visaFreeEntryThenPermit)
        XCTAssertEqual(route("in"), .nationalVisaRequired)
    }

    func testUnknownOrGarbageCodeRequiresNationalVisa() {
        XCTAssertEqual(route("ZZ"), .nationalVisaRequired)
        XCTAssertEqual(route(""), .nationalVisaRequired)
        XCTAssertEqual(route("???"), .nationalVisaRequired)
    }

    func testPrivilegedSetHasExactlyEightMembers() {
        XCTAssertEqual(StudentPrearrivalData.current.privileged.count, 8)
    }

    func testPrivilegedSetContainsExactlyTheExpectedNationalities() {
        XCTAssertEqual(
            StudentPrearrivalData.current.privileged,
            ["AU", "IL", "JP", "CA", "KR", "NZ", "GB", "US"])
    }

    func testFreeMovementReusesVisaNeedSet() {
        XCTAssertEqual(
            StudentPrearrivalData.current.freeMovement,
            VisaNeedData.current.freeMovement)
    }

    func testFreeMovementAndPrivilegedDoNotOverlap() {
        let data = StudentPrearrivalData.current
        XCTAssertTrue(data.freeMovement.isDisjoint(with: data.privileged))
    }

    func testEveryRouteHasANonEmptyChecklistWithUniqueIds() {
        for route in StudentEntryRoute.allCases {
            let steps = StudentPrearrivalEngine.steps(for: route)
            XCTAssertFalse(steps.isEmpty, "\(route) should have steps")
            let ids = steps.map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count, "\(route) step ids must be unique")
        }
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "residence_permit"))
    }
}
