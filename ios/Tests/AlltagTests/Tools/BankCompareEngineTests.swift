import XCTest
@testable import Alltag

/// Bank-account comparison logic + catalog invariants (P6-W4). Pure engine,
/// tested against the injected catalog so ranking/filtering is independent of the
/// shipping list (A-05). Enforces the P6-A1 transparency invariants.
final class BankCompareEngineTests: XCTestCase {

    private let catalog = BankCompareCatalog.current

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

    func testAffiliateOptionsHaveALink() {
        // An affiliate marker is only meaningful if there's a link to attribute.
        for option in catalog.options where option.isAffiliate {
            XCTAssertNotNil(option.url, "\(option.name) is affiliate but has no link")
        }
    }

    // MARK: - Ranking / filtering

    func testRankedOptionsPreservesCatalogOrder() {
        XCTAssertEqual(
            BankCompareEngine.rankedOptions(from: catalog).map(\.id),
            catalog.options.map(\.id))
    }

    func testAlwaysReturnsAtLeastMinimumOptions() {
        // P6-A1 invariant: always 3+ ranked options, unfiltered and filtered.
        XCTAssertGreaterThanOrEqual(
            BankCompareEngine.rankedOptions(from: catalog).count,
            BankCompareEngine.minimumOptions)
        XCTAssertGreaterThanOrEqual(
            BankCompareEngine.rankedOptions(from: catalog, englishSupportOnly: true).count,
            BankCompareEngine.minimumOptions)
    }

    func testEnglishFilterKeepsOnlyEnglishWhenEnoughRemain() {
        let many = ComparisonCatalog(year: 2026, options: [
            opt("a", english: true), opt("b", english: true),
            opt("c", english: true), opt("d", english: false),
        ])
        let result = BankCompareEngine.rankedOptions(from: many, englishSupportOnly: true)
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
        let result = BankCompareEngine.rankedOptions(from: few, englishSupportOnly: true)
        XCTAssertEqual(result.map(\.id), ["a", "b", "c", "d"])
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
