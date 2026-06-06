import SwiftUI

/// Sponsor document pack (P6-F3): the documents the family member already living
/// in Germany must prepare to support a relative's family-reunification
/// application — grouped by category (identity & status, finances, housing, the
/// relationship). The sponsor-side counterpart to the family-reunification visa
/// checklist (P6-F1).
///
/// Content comes from the versioned `SponsorPackContent`; this screen is
/// presentation only and carries the standard RDG note (orientation, not legal
/// advice). Exact requirements vary by Ausländerbehörde / consulate.
struct SponsorPackView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// Ids of the documents the user has ticked off. **Session-only by design:**
    /// a packing-list feel, not a tracker — held in `@State` and deliberately
    /// NOT persisted (no `@AppStorage`/SwiftData/file write).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    /// Guide opened from the "learn more" link.
    private let guideId = "residence_permit"

    init(
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var groups: [SponsorDocGroup] { SponsorPackContent.groups }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_sponsor_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_sponsor_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            // Session-only ticks (see `ticked`) — a packing-list feel, not a
            // tracker; deliberately not persisted.
            ForEach(groups) { group in
                groupSection(group)
            }

            learnMore
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Groups

    private func groupSection(_ group: SponsorDocGroup) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(LocalizedStringKey(group.headingKey))
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(group.documents) { doc in
                documentRow(doc)
            }
        }
    }

    private func documentRow(_ doc: SponsorDoc) -> some View {
        let isTicked = ticked.contains(doc.id)
        return Button {
            if isTicked { ticked.remove(doc.id) } else { ticked.insert(doc.id) }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isTicked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isTicked ? AppColor.primary : AppColor.inkFaint)
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(LocalizedStringKey(doc.titleKey))
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                        .strikethrough(isTicked, color: AppColor.inkSoft)
                    if let hintKey = doc.hintKey {
                        Text(LocalizedStringKey(hintKey))
                            .appText(.label)
                            .foregroundStyle(AppColor.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(AppColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isTicked ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Learn more

    private var learnMore: some View {
        Button { onOpenGuide(guideId) } label: {
            HStack(spacing: AppSpacing.xxs) {
                Text("tool_sponsor_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { SponsorPackView() }
        .appFontDesign()
}
