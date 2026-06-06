import SwiftUI

/// Kita/school enrollment basics (P6-F6): orients newcomer parents to German
/// childcare (Krippe / Kindergarten / Kita) and schooling (Schulpflicht,
/// Grundschule, secondary school types, Willkommensklassen) — explainer sections
/// followed by an ordered practical-steps list.
///
/// Content comes from the versioned `KitaSchoolContent`; this screen is
/// presentation only and carries the standard RDG note (orientation, not legal
/// advice — details vary by Bundesland and municipality).
struct KitaSchoolView: View {
    /// Ids of the steps the user has ticked off. **Session-only by design:**
    /// a packing-list feel, not a tracker — held in `@State` and deliberately
    /// NOT persisted (no `@AppStorage`/SwiftData/file write).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    init(embedInScrollView: Bool = true) {
        self.embedInScrollView = embedInScrollView
    }

    private var sections: [KitaSchoolSection] { KitaSchoolContent.sections }
    private var steps: [KitaSchoolStep] { KitaSchoolContent.steps }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_kita_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_kita_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            sectionsView
            stepsSection
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

    private func sectionCard(_ section: KitaSchoolSection) -> some View {
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

    // MARK: - Practical steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_kita_steps_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Session-only ticks (see `ticked`) — a packing-list feel, not a tracker.
            ForEach(steps) { step in
                stepRow(step)
            }
        }
    }

    private func stepRow(_ step: KitaSchoolStep) -> some View {
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
}

#Preview {
    NavigationStack { KitaSchoolView() }
        .appFontDesign()
}
