import SwiftUI
import XCTest
@testable import Alltag

/// In-app search (P6-G6). The matcher is pure given an injected `localize`, so
/// these exercise it deterministically without the string catalog or a locale.
@MainActor
final class HomeSearchTests: XCTestCase {

    /// Localize keys to a stub display string so matching is predictable: the
    /// "title" of `tool_visa_fit_title` is "visa fit", a guide is "residence …".
    private func stub(_ key: String) -> String {
        switch key {
        case "tool_visa_fit_title": return "Visa-fit tool"
        case "tool_blue_card_title": return "Blue Card check"
        case "guide_residence_permit_title": return "Getting a residence permit"
        case "guide_taxes_title": return "How taxes work"
        default: return key
        }
    }

    private let items: [SearchItem] = [
        SearchItem(kind: .guide, targetId: "residence_permit",
                   titleKey: "guide_residence_permit_title", subtitleKey: nil, systemImage: "doc"),
        SearchItem(kind: .guide, targetId: "how_taxes_work",
                   titleKey: "guide_taxes_title", subtitleKey: nil, systemImage: "eurosign"),
        SearchItem(kind: .tool, targetId: "visa_fit",
                   titleKey: "tool_visa_fit_title", subtitleKey: nil, systemImage: "location"),
        SearchItem(kind: .tool, targetId: "blue_card",
                   titleKey: "tool_blue_card_title", subtitleKey: nil, systemImage: "creditcard"),
    ]

    func testBlankQueryReturnsEverything() {
        XCTAssertEqual(HomeSearch.filter(items, query: "  ", localize: stub).count, items.count)
    }

    func testMatchesAcrossGuidesAndTools() {
        // "card" hits the Blue Card tool; "taxes" hits the guide.
        let card = HomeSearch.filter(items, query: "card", localize: stub)
        XCTAssertEqual(card.map(\.targetId), ["blue_card"])
        let taxes = HomeSearch.filter(items, query: "taxes", localize: stub)
        XCTAssertEqual(taxes.map(\.targetId), ["how_taxes_work"])
    }

    func testMatchingIsCaseAndDiacriticInsensitive() {
        XCTAssertEqual(
            HomeSearch.filter(items, query: "VISA", localize: stub).map(\.targetId),
            ["visa_fit"])
        // diacritic-insensitive: "résidence" still finds "residence".
        XCTAssertEqual(
            HomeSearch.filter(items, query: "résidence", localize: stub).map(\.targetId),
            ["residence_permit"])
    }

    func testNoMatchReturnsEmpty() {
        XCTAssertTrue(HomeSearch.filter(items, query: "zzz", localize: stub).isEmpty)
    }

    func testItemsForPersonaCoverGuidesPlusTools() {
        let items = HomeSearch.items(for: .worker)
        XCTAssertEqual(items.filter { $0.kind == .guide }.count, PersonaCatalog.guides.count)
        XCTAssertEqual(items.filter { $0.kind == .tool }.count,
                       PersonaCatalog.tools(for: .worker).count)
    }

    func testItemsWithoutPersonaStillSearchGuides() {
        let items = HomeSearch.items(for: nil)
        XCTAssertEqual(items.count, PersonaCatalog.guides.count)
        XCTAssertTrue(items.allSatisfy { $0.kind == .guide })
    }

    func testItemIdsAreUnique() {
        let ids = HomeSearch.items(for: .worker).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }
}
