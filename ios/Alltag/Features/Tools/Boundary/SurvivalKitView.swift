import SwiftUI

/// Pre-arrival survival kit (P6-T6): a friendly orientation reference for
/// arriving in Germany — grouped essentials (emergencies & health, money, daily
/// life, getting around, connectivity, etiquette) followed by a "before you fly"
/// preparation checklist.
///
/// Content comes from the versioned `SurvivalKitContent`; this screen is
/// presentation only and carries the standard RDG note (orientation, not legal
/// or medical advice).
struct SurvivalKitView: View {
    /// The before-you-fly items ticked off. **Session-only by design:** a
    /// satisfying packing-list feel, not a tracker — held in `@State` and
    /// deliberately NOT persisted (no `@AppStorage`/SwiftData/file write).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    init(embedInScrollView: Bool = true) {
        self.embedInScrollView = embedInScrollView
    }

    private var categories: [SurvivalCategory] { SurvivalKitContent.categories }
    private var checklist: [SurvivalChecklistItem] { SurvivalKitContent.checklist }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_survival_kit_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_survival_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            categoriesView
            checklistSection
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tip categories

    private var categoriesView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(categories) { category in
                categoryCard(category)
            }
        }
    }

    private func categoryCard(_ category: SurvivalCategory) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(LocalizedStringKey(category.headingKey))
                .appText(.cardTitle)
                .foregroundStyle(AppColor.ink)
            ForEach(category.tipKeys, id: \.self) { tipKey in
                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Text(verbatim: "•")
                        .appText(.label)
                        .foregroundStyle(AppColor.inkFaint)
                    Text(LocalizedStringKey(tipKey))
                        .appText(.label)
                        .foregroundStyle(AppColor.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Before-you-fly checklist

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_survival_checklist_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Interactive packing-list ticks — session-only by design (see `ticked`).
            ForEach(checklist) { item in
                itemRow(item)
            }
        }
    }

    private func itemRow(_ item: SurvivalChecklistItem) -> some View {
        let isTicked = ticked.contains(item.id)
        return Button {
            if isTicked { ticked.remove(item.id) } else { ticked.insert(item.id) }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isTicked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isTicked ? AppColor.primary : AppColor.inkFaint)
                Text(LocalizedStringKey(item.titleKey))
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
                    .strikethrough(isTicked, color: AppColor.inkSoft)
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
}

#Preview {
    NavigationStack { SurvivalKitView() }
        .appFontDesign()
}
