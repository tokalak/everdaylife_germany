import XCTest
@testable import Alltag

/// Student health-insurance comparison logic + catalog invariants (P6-S3).
/// Pure engine, tested against the injected catalog so ranking/filtering is
/// independent of the shipping list (A-05). Enforces the P6-A1 transparency
/// invariants and checks the linked guide ships.
final class StudentHealthEngineTests: XCTestCase {

    private let catalog = StudentHealthCatalog.current

    // MARK: - Catalog invariants

    func testCatalogHasAtLeastThreeOptions() {
        XCTAssertGreaterThanOrEqual(catalog.options.count, 3)
    }

    func testOptionIDsAreUnique() {
        let ids = catalog.options.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "option ids must be unique")
    }

    func testEveryURLIsHTTPS() {
        for option in catalog.options {
            guard let url = option.url else { continue }
            XCTAssertEqual(url.scheme, "https", "\(option.name) link must be https")
        }
    }

    func testAffiliateLinksArePresent() {
        // At least one affiliate option, and every affiliate option has a link
        // (an affiliate marker is only meaningful if there's a link to attribute).
        let affiliates = catalog.options.filter(\.isAffiliate)
        XCTAssertFalse(affiliates.isEmpty, "expected at least one affiliate option")
        for option in affiliates {
            XCTAssertNotNil(option.url, "\(option.name) is affiliate but has no link")
        }
    }

    // MARK: - Ranking / filtering

    func testRankedOptionsPreservesCatalogOrder() {
        XCTAssertEqual(
            StudentHealthEngine.rankedOptions(from: catalog).map(\.id),
            catalog.options.map(\.id))
    }

    func testAlwaysReturnsAtLeastMinimumOptions() {
        // P6-A1 invariant: always 3+ ranked options, unfiltered and filtered.
        XCTAssertGreaterThanOrEqual(
            StudentHealthEngine.rankedOptions(from: catalog).count,
            StudentHealthEngine.minimumOptions)
        XCTAssertGreaterThanOrEqual(
            StudentHealthEngine.rankedOptions(from: catalog, englishSupportOnly: true).count,
            StudentHealthEngine.minimumOptions)
    }

    func testEnglishFilterKeepsOnlyEnglishWhenEnoughRemain() {
        let many = ComparisonCatalog(year: 2026, options: [
            opt("a", english: true), opt("b", english: true),
            opt("c", english: true), opt("d", english: false),
        ])
        let result = StudentHealthEngine.rankedOptions(from: many, englishSupportOnly: true)
        XCTAssertEqual(result.map(\.id), ["a", "b", "c"])
        XCTAssertTrue(result.allSatisfy(\.englishSupport))
    }

    func testEnglishFilterIgnoredWhenItWouldDropBelowMinimum() {
        // Only 2 English options → filtering would break the invariant, so the
        // full ranked list is returned instead.
        let few = ComparisonCatalog(year: 2026, options: [
            opt("a", english: true), opt("b", english: true),
            opt("c", english: false), opt("d", english: false),
        ])
        let result = StudentHealthEngine.rankedOptions(from: few, englishSupportOnly: true)
        XCTAssertEqual(result.map(\.id), ["a", "b", "c", "d"])
    }

    // MARK: - Linked guide ships

    @MainActor
    func testLearnMoreGuideExists() {
        XCTAssertNotNil(GuideLibrary.content(for: "health_insurance"))
    }

    // MARK: - Helpers

    private func opt(_ id: String, english: Bool) -> ComparisonOption {
        ComparisonOption(
            id: id, name: id.uppercased(),
            summaryKey: "k", highlightKeys: ["k"], monthlyFeeKey: "k", bestForKey: "k",
            url: URL(string: "https://example.com"), isAffiliate: false,
            englishSupport: english)
    }
}
