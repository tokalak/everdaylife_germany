import XCTest
@testable import Alltag

/// Visa-fit recommendation logic (P6-W1). Pure engine, exhaustively tested
/// (A-05): every goal/qualification combination maps to sensible routes, and
/// any route that points at a guide points at one that actually ships.
final class VisaFitEngineTests: XCTestCase {

    private func routes(_ goal: VisaGoal?, _ qual: VisaQualification? = nil) -> [VisaFitRoute] {
        VisaFitEngine.routes(for: VisaFitInput(goal: goal, qualification: qual))
    }

    func testNoGoalYieldsNoRoutes() {
        XCTAssertTrue(routes(nil).isEmpty)
    }

    func testWorkRoutesRequireQualificationBeforeRecommending() {
        // Goal needs a qualification → nothing until it's answered.
        XCTAssertTrue(routes(.job).isEmpty)
        XCTAssertTrue(routes(.jobSeeking).isEmpty)
        XCTAssertFalse(routes(.job, .academic).isEmpty)
    }

    func testNonWorkGoalsRecommendWithoutQualification() {
        for goal in [VisaGoal.study, .family, .business, .visit] {
            XCTAssertFalse(routes(goal).isEmpty, "\(goal) should recommend a route")
        }
    }

    func testAcademicJobLeadsWithBlueCard() {
        XCTAssertEqual(routes(.job, .academic).first?.id, "blue_card")
    }

    func testVocationalJobIsSkilledWorker() {
        XCTAssertEqual(routes(.job, .vocational).map(\.id), ["skilled_worker"])
    }

    func testUnqualifiedJobLeadsWithRecognition() {
        XCTAssertEqual(routes(.job, VisaQualification.none).first?.id, "recognition")
    }

    func testQualifiedJobSeekerGetsChancenkarte() {
        XCTAssertEqual(routes(.jobSeeking, .academic).first?.id, "chancenkarte")
        XCTAssertEqual(routes(.jobSeeking, .vocational).first?.id, "chancenkarte")
    }

    func testUnqualifiedJobSeekerOnlyGetsRecognition() {
        XCTAssertEqual(routes(.jobSeeking, VisaQualification.none).map(\.id), ["recognition"])
    }

    func testBusinessLinksRegisterBusinessGuide() {
        XCTAssertEqual(routes(.business).first?.guideId, "register_business")
    }

    func testShortStayHasNoGuideLink() {
        XCTAssertNil(routes(.visit).first?.guideId)
    }

    @MainActor
    func testEveryRecommendedGuideActuallyShips() {
        // No result may deep-link to a guide body that doesn't exist.
        for goal in VisaGoal.allCases {
            let quals: [VisaQualification?] = goal.needsQualification
                ? VisaQualification.allCases.map { $0 } : [nil]
            for qual in quals {
                for route in routes(goal, qual) {
                    if let guideId = route.guideId {
                        XCTAssertNotNil(GuideLibrary.content(for: guideId),
                                        "\(goal)/\(String(describing: qual)) → missing guide \(guideId)")
                    }
                }
            }
        }
    }
}
