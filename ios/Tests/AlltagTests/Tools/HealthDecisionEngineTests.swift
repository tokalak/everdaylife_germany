import XCTest
@testable import Alltag

/// GKV vs PKV decision-tree logic + insurer-catalog invariants (P6-W5). Pure
/// engine, tested against an injected threshold so the rule is independent of the
/// yearly figure (A-05). Enforces the P6-A1 transparency invariants.
final class HealthDecisionEngineTests: XCTestCase {

    private let t = HealthInsuranceThreshold(year: 2026, compulsoryInsuranceLimit: 70_000)

    private func rec(_ status: HealthStatus?, income: Double = 0) -> HealthRecommendation? {
        HealthDecisionEngine.recommendation(
            for: HealthDecisionInput(status: status, grossAnnualIncome: income),
            threshold: t)
    }

    // MARK: - Decision tree

    func testNoStatusYieldsNoRecommendation() {
        XCTAssertNil(rec(nil))
    }

    func testEmployeeBelowThresholdMustBeGKV() {
        XCTAssertEqual(rec(.employee, income: 50_000), .mustBeGKV)
    }

    func testEmployeeAtThresholdMustBeGKV() {
        // Boundary: exactly at the limit is still compulsory GKV.
        XCTAssertEqual(rec(.employee, income: 70_000), .mustBeGKV)
    }

    func testEmployeeAboveThresholdMayChoose() {
        XCTAssertEqual(rec(.employee, income: 70_001), .gkvOrPkvChoice)
        XCTAssertEqual(rec(.employee, income: 90_000), .gkvOrPkvChoice)
    }

    func testSelfEmployedMayChoose() {
        XCTAssertEqual(rec(.selfEmployed), .gkvOrPkvChoice)
    }

    func testCivilServantMayChoose() {
        XCTAssertEqual(rec(.civilServant), .gkvOrPkvChoice)
    }

    func testStudentGetsStudentGKV() {
        XCTAssertEqual(rec(.student), .studentGKV)
    }

    func testOtherDependsOnCase() {
        XCTAssertEqual(rec(.other), .dependsOnCase)
    }

    func testEveryStatusProducesARecommendation() {
        for status in HealthStatus.allCases {
            XCTAssertNotNil(rec(status, income: 60_000), "\(status) produced no recommendation")
        }
    }

    func testShippingThresholdIsPlausible() {
        let c = HealthInsuranceThreshold.current
        XCTAssertGreaterThan(c.compulsoryInsuranceLimit, 50_000, "sanity: annual gross €")
        XCTAssertLessThan(c.compulsoryInsuranceLimit, 120_000)
    }

    // MARK: - Guide deep-link

    @MainActor
    func testLearnMoreGuideExists() {
        XCTAssertNotNil(
            GuideLibrary.content(for: "health_insurance"),
            "decision-tree 'learn more' deep-links a guide that must ship")
    }

    // MARK: - Insurer-catalog invariants (P6-A1)

    private let catalog = HealthInsurerCatalog.current

    func testCatalogHasAtLeastThreeOptions() {
        XCTAssertGreaterThanOrEqual(catalog.options.count, 3)
    }

    func testOptionIDsAreUnique() {
        let ids = catalog.options.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "option ids must be unique")
    }

    func testEveryURLIsHTTPS() {
        for option in catalog.options {
            guard let url = option.url else {
                return XCTFail("\(option.name) has no link")
            }
            XCTAssertEqual(url.scheme, "https", "\(option.name) link must be https")
        }
    }

    func testAffiliateOptionsHaveALink() {
        let affiliates = catalog.options.filter(\.isAffiliate)
        XCTAssertFalse(affiliates.isEmpty, "an affiliate tool should have affiliate links")
        for option in affiliates {
            XCTAssertNotNil(option.url, "\(option.name) is affiliate but has no link")
        }
    }
}
