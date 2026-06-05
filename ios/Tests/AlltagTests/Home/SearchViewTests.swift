import SwiftUI
import XCTest
@testable import Alltag

/// Search screen (P6-G6): render-smoke across the trait matrix for the populated
/// list, an active query, and the no-results empty state (A-06 / X-02).
@MainActor
final class SearchViewTests: XCTestCase {

    private func view(query: String) -> some View {
        SearchView(
            items: HomeSearch.items(for: .worker),
            localize: { HomeSearch.resolve($0, locale: Locale(identifier: "en")) },
            query: query,
            embedInScrollView: false)
    }

    func testRendersBrowseList() {
        SnapshotSupport.assertRenders(view(query: ""), height: 1200)
    }

    func testRendersFilteredQuery() {
        SnapshotSupport.assertRenders(view(query: "card"), height: 600)
    }

    func testRendersNoResultsState() {
        SnapshotSupport.assertRenders(view(query: "zzzzz"), height: 500)
    }
}
