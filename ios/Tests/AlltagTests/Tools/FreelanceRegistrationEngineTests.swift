import XCTest
@testable import Alltag

/// Freelance registration sub-flow logic (P6-W7). The engine is pure content
/// selection (A-05): both paths return a non-empty ordered step list, ids are
/// unique within a path, the two paths genuinely differ (Gewerbe adds the
/// Gewerbeanmeldung / chamber steps Freiberufler doesn't have), and the
/// "learn more" guide actually ships.
final class FreelanceRegistrationEngineTests: XCTestCase {

    private func steps(_ path: FreelancePath) -> [FreelanceStep] {
        FreelanceRegistrationEngine.steps(for: path)
    }

    func testBothPathsReturnNonEmptyStepLists() {
        for path in FreelancePath.allCases {
            XCTAssertFalse(steps(path).isEmpty, "\(path) should have steps")
        }
    }

    func testStepIdsAreUniqueWithinAPath() {
        for path in FreelancePath.allCases {
            let ids = steps(path).map(\.id)
            XCTAssertEqual(Set(ids).count, ids.count, "\(path) step ids must be unique")
        }
    }

    func testFreiberuflerStartsByConfirmingEligibility() {
        XCTAssertEqual(steps(.freiberufler).first?.id, "confirm_freiberufler")
    }

    func testGewerbeStartsWithGewerbeanmeldung() {
        XCTAssertEqual(steps(.gewerbe).first?.id, "gewerbeanmeldung")
    }

    func testGewerbeHasGewerbeanmeldungAndChamberStepsFreiberuflerLacks() {
        let gewerbe = Set(steps(.gewerbe).map(\.id))
        let freiberufler = Set(steps(.freiberufler).map(\.id))
        XCTAssertTrue(gewerbe.contains("gewerbeanmeldung"))
        XCTAssertTrue(gewerbe.contains("chamber_membership"))
        XCTAssertFalse(freiberufler.contains("gewerbeanmeldung"))
        XCTAssertFalse(freiberufler.contains("chamber_membership"))
    }

    func testTheTwoPathsDiffer() {
        XCTAssertNotEqual(steps(.freiberufler).map(\.id), steps(.gewerbe).map(\.id))
    }

    func testFreiberuflerUsesElsterFragebogen() {
        XCTAssertTrue(steps(.freiberufler).contains { $0.id == "elster_fragebogen" })
    }

    @MainActor
    func testLearnMoreGuideShips() {
        XCTAssertNotNil(GuideLibrary.content(for: "register_business"))
    }
}
