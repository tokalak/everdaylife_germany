import SwiftUI

/// In-app search across guides and the active mode's tools (P6-G6).
///
/// A search field over a list of results; each row opens its guide (the reader)
/// or tool via `onSelect`. Pure over its inputs — the searchable `items` and a
/// `localize` closure come from `HomeSearch`, so the view holds no catalog logic.
struct SearchView: View {
    let items: [SearchItem]
    /// Resolves a String-Catalog key to display text (injected for testability).
    let localize: (String) -> String
    var onSelect: (SearchItem) -> Void = { _ in }

    /// Seedable for previews/tests; the field is the source of truth at runtime.
    @State private var query: String
    /// Embed results in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool
    @FocusState private var focused: Bool

    init(
        items: [SearchItem],
        localize: @escaping (String) -> String,
        query: String = "",
        embedInScrollView: Bool = true,
        onSelect: @escaping (SearchItem) -> Void = { _ in }
    ) {
        self.items = items
        self.localize = localize
        self.onSelect = onSelect
        self._query = State(initialValue: query)
        self.embedInScrollView = embedInScrollView
    }

    private var results: [SearchItem] {
        HomeSearch.filter(items, query: query, localize: localize)
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            searchField
            if results.isEmpty {
                EmptyState(
                    systemImage: "magnifyingglass",
                    titleKey: "search_no_results_title",
                    messageKey: "search_no_results_message")
                    .padding(.top, AppSpacing.xl)
            } else if embedInScrollView {
                ScrollView { resultList }
            } else {
                resultList
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.paper)
        .navigationTitle("search_title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColor.inkSoft)
            TextField("home_search_placeholder", text: $query)
                .appText(.body)
                .foregroundStyle(AppColor.ink)
                .focused($focused)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColor.inkFaint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("search_clear")
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
    }

    private var resultList: some View {
        LazyVStack(spacing: AppSpacing.xs) {
            ForEach(results) { item in
                GuideRow(
                    titleKey: LocalizedStringKey(item.titleKey),
                    subtitleKey: item.subtitleKey.map { LocalizedStringKey($0) },
                    systemImage: item.systemImage,
                    tint: item.tint
                ) { onSelect(item) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(
            items: HomeSearch.items(for: .worker),
            localize: { HomeSearch.resolve($0, locale: .current) })
    }
    .appFontDesign()
}
