import SwiftUI

/// Reads a cross-persona guide (P6-G6): title + summary, the RDG "information,
/// not legal advice" note for consequential topics, the guide's sections
/// (headings, paragraphs, bullet points), and links to the official sources.
///
/// Content comes entirely from `GuideContent` (versioned, X-06) — the reader is
/// pure presentation. Opened from Home (and from search) by pushing the guide id
/// onto the navigation stack.
struct GuideReaderView: View {
    let content: GuideContent

    /// Embed in a `ScrollView` (the shipping default). The snapshot harness sets
    /// this `false` — `ImageRenderer` renders `ScrollView` content blank, so tests
    /// exercise the layout directly across the trait matrix (mirrors `HomeView`).
    var embedInScrollView = true

    var body: some View {
        Group {
            if embedInScrollView {
                ScrollView { readerContent }
            } else {
                readerContent
            }
        }
        .background(AppColor.paper)
        .navigationTitle(content.titleKey)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var readerContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            header
            if content.showsLegalDisclaimer { DisclaimerNote() }
            ForEach(content.sections) { sectionView($0) }
            if !content.sources.isEmpty { sourcesView }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(content.titleKey)
                .appText(.display)
                .foregroundStyle(AppColor.ink)
            if let summaryKey = content.summaryKey {
                Text(summaryKey)
                    .appText(.body)
                    .foregroundStyle(AppColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Section

    private func sectionView(_ section: GuideSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(section.headingKey)
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: GuideBlock) -> some View {
        switch block {
        case .paragraph(let key):
            Text(key)
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .bullet(let key):
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 5))
                    .foregroundStyle(AppColor.primary)
                    .padding(.top, AppSpacing.xs)
                Text(key)
                    .appText(.body)
                    .foregroundStyle(AppColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Sources

    private var sourcesView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("guide_sources_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(content.sources) { source in
                Link(destination: source.url) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "link")
                            .foregroundStyle(AppColor.primary)
                        Text(source.titleKey)
                            .appText(.bodyEmphasis)
                            .foregroundStyle(AppColor.primaryDeep)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "arrow.up.right")
                            .appText(.label)
                            .foregroundStyle(AppColor.inkFaint)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .strokeBorder(AppColor.line, lineWidth: 1))
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isLink)
            }
        }
    }
}

#Preview {
    NavigationStack {
        GuideReaderView(content: GuideLibrary.content(for: "residence_permit")!)
    }
    .appFontDesign()
}
