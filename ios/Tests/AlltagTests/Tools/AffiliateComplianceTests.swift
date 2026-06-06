import XCTest
@testable import Alltag

/// Central §7 affiliate-compliance guarantee (P6-A1).
///
/// Iterates EVERY catalog registered in `AffiliateCatalogs.all` and asserts the
/// brief's transparency invariants on each one, so the "always 3+ ranked
/// options, transparent" rule holds across all current *and* future comparison
/// tools that register here — not just the ones that happen to have their own
/// engine test today.
final class AffiliateComplianceTests: XCTestCase {

    /// Sanity: the registry isn't empty (otherwise the loop would assert nothing).
    func testRegistryIsNotEmpty() {
        XCTAssertFalse(AffiliateCatalogs.all.isEmpty, "no affiliate catalogs registered")
    }

    /// The core §7 rule: every comparison shows at least three ranked options.
    func testEveryCatalogHasAtLeastThreeOptions() {
        for (name, catalog) in AffiliateCatalogs.all {
            XCTAssertGreaterThanOrEqual(
                catalog.options.count, 3,
                "\(name): comparison must show at least 3 ranked options")
        }
    }

    /// Option ids are unique within each catalog (stable ranking + key stems).
    func testOptionIDsAreUniqueWithinEachCatalog() {
        for (name, catalog) in AffiliateCatalogs.all {
            let ids = catalog.options.map(\.id)
            XCTAssertEqual(
                Set(ids).count, ids.count,
                "\(name): option ids must be unique")
        }
    }

    /// Transparency: every affiliate option points at a real https URL — a marker
    /// is only honest if there's an actual link to attribute a commission to.
    func testAffiliateOptionsHaveAnHTTPSLink() {
        for (name, catalog) in AffiliateCatalogs.all {
            for option in catalog.options where option.isAffiliate {
                guard let url = option.url else {
                    XCTFail("\(name)/\(option.id): affiliate option must have a url")
                    continue
                }
                XCTAssertEqual(
                    url.scheme, "https",
                    "\(name)/\(option.id): affiliate link must be https")
            }
        }
    }

    /// Any non-affiliate link must also be https (no insecure links anywhere).
    func testEveryURLIsHTTPS() {
        for (name, catalog) in AffiliateCatalogs.all {
            for option in catalog.options {
                guard let url = option.url else { continue }
                XCTAssertEqual(
                    url.scheme, "https",
                    "\(name)/\(option.id): link must be https")
            }
        }
    }

    /// At least one affiliate option exists per catalog, so the shared affiliate
    /// disclosure shown on the screen is actually warranted.
    func testEachCatalogHasAtLeastOneAffiliateOption() {
        for (name, catalog) in AffiliateCatalogs.all {
            XCTAssertTrue(
                catalog.options.contains { $0.isAffiliate },
                "\(name): at least one affiliate option is expected (disclosure warranted)")
        }
    }

    /// Descriptive content is present: names verbatim, key stems non-empty.
    func testNamesAndKeysAreNonEmpty() {
        for (name, catalog) in AffiliateCatalogs.all {
            for option in catalog.options {
                XCTAssertFalse(
                    option.name.trimmingCharacters(in: .whitespaces).isEmpty,
                    "\(name)/\(option.id): brand name must not be empty")
                XCTAssertFalse(
                    option.summaryKey.isEmpty,
                    "\(name)/\(option.id): summaryKey must not be empty")
            }
        }
    }
}
