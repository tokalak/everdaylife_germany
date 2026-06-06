import SwiftUI

/// Family-reunification quick guide (P6-R5): a concise orientation for a settled
/// long-term resident who wants to bring their family to Germany — explainer
/// sections (who you can bring, what the sponsor must show, what the family
/// member needs, how the process runs) followed by a short ordered step list.
///
/// Content comes from the versioned `ReunificationGuideContent`; this screen is
/// presentation only and carries the standard RDG note (orientation, not legal
/// advice — exact rules vary by case and consulate). Deliberately a *quick
/// guide*: the Family persona ships deeper tools (the reunification visa
/// checklist and sponsor document pack); this does not duplicate them. The last
/// Long-term Resident tool.
struct ReunificationGuideView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// Ids of the steps the user has ticked off. **Session-only by design:**
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

    private var sections: [ReunificationGuideSection] { ReunificationGuideContent.sections }
    private var steps: [ReunificationGuideStep] { ReunificationGuideContent.steps }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_reunification_guide_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_reunification_guide_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            sectionsView
            stepsSection
            learnMore
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Explainer sections

    private var sectionsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(sections) { section in
                sectionCard(section)
            }
        }
    }

    private func sectionCard(_ section: ReunificationGuideSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(LocalizedStringKey(section.headingKey))
                .appText(.cardTitle)
                .foregroundStyle(AppColor.ink)
            ForEach(section.bodyKeys, id: \.self) { bodyKey in
                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Text(verbatim: "•")
                        .appText(.label)
                        .foregroundStyle(AppColor.inkFaint)
                    Text(LocalizedStringKey(bodyKey))
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

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_reunification_guide_steps_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Session-only ticks (see `ticked`) — a packing-list feel, not a tracker.
            ForEach(steps) { step in
                stepRow(step)
            }
        }
    }

    private func stepRow(_ step: ReunificationGuideStep) -> some View {
        let isTicked = ticked.contains(step.id)
        return Button {
            if isTicked { ticked.remove(step.id) } else { ticked.insert(step.id) }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isTicked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isTicked ? AppColor.primary : AppColor.inkFaint)
                Text(LocalizedStringKey(step.titleKey))
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

    // MARK: - Learn more

    private var learnMore: some View {
        Button { onOpenGuide(guideId) } label: {
            HStack(spacing: AppSpacing.xxs) {
                Text("tool_reunification_guide_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { ReunificationGuideView() }
        .appFontDesign()
}
