import SwiftUI

/// Freelance registration sub-flow (P6-W7): pick a legal form (Freiberufler vs
/// Gewerbe) and see the ordered, numbered steps to register it — with a non-EU
/// residence-permit caveat and a "learn more" into the register-business guide.
///
/// The steps come from the pure `FreelanceRegistrationEngine`; this screen is
/// selection + presentation. Always carries the RDG note — it informs, never
/// decides. Defaults to the Freiberufler path so steps are visible immediately.
struct FreelanceRegistrationView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// The chosen legal form. Seedable for previews/tests.
    @State private var path: FreelancePath
    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    /// Guide opened from the "learn more" link.
    private let guideId = "register_business"

    init(
        path: FreelancePath = .freiberufler,
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._path = State(initialValue: path)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var steps: [FreelanceStep] { FreelanceRegistrationEngine.steps(for: path) }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_freelance_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_freelance_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            pathSelector
            stepsSection
            caveatNote
            learnMore
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Path selector

    private var pathSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_freelance_path_question")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(FreelancePath.allCases) { p in
                pathRow(p)
            }
        }
    }

    private func pathRow(_ p: FreelancePath) -> some View {
        let isSelected = path == p
        return Button { path = p } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkFaint)
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(LocalizedStringKey(p.titleKey))
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(LocalizedStringKey(p.subtitleKey))
                        .appText(.label)
                        .foregroundStyle(AppColor.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .background(
                (isSelected ? AppColor.primaryWash : AppColor.card),
                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(isSelected ? AppColor.primary.opacity(0.5) : AppColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_freelance_steps_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                stepCard(number: index + 1, step: step)
            }
        }
    }

    private func stepCard(number: Int, step: FreelanceStep) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Text("\(number)")
                .appText(.cardTitle)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(AppColor.primary, in: Circle())
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(LocalizedStringKey(step.titleKey))
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
                Text(LocalizedStringKey(step.detailKey))
                    .appText(.body)
                    .foregroundStyle(AppColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Caveat

    private var caveatNote: some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .imageScale(.small)
                .foregroundStyle(AppColor.amber)
            Text("tool_freelance_noneu_caveat")
                .appText(.caption)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.md)
        .background(AppColor.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    // MARK: - Learn more

    private var learnMore: some View {
        Button { onOpenGuide(guideId) } label: {
            HStack(spacing: AppSpacing.xxs) {
                Text("tool_freelance_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { FreelanceRegistrationView(path: .gewerbe) }
        .appFontDesign()
}
