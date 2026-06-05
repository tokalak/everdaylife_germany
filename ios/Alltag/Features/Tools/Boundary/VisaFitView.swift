import SwiftUI

/// Visa-fit tool (P6-W1): a two-question guided selector that suggests the most
/// fitting residence routes, each with a short rationale and an optional
/// "learn more" into the guide reader.
///
/// Recommendations come from the pure `VisaFitEngine`; this screen is selection
/// + presentation. Always carries the RDG note — it informs, never decides.
struct VisaFitView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// Seedable for previews/tests; the controls are the source of truth at runtime.
    @State private var goal: VisaGoal?
    @State private var qualification: VisaQualification?
    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    init(
        goal: VisaGoal? = nil,
        qualification: VisaQualification? = nil,
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._goal = State(initialValue: goal)
        self._qualification = State(initialValue: qualification)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var input: VisaFitInput { VisaFitInput(goal: goal, qualification: qualification) }
    private var routes: [VisaFitRoute] { VisaFitEngine.routes(for: input) }

    var body: some View {
        Group {
            if embedInScrollView {
                ScrollView { content }
            } else {
                content
            }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_visa_fit_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_visafit_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            question("tool_visafit_q_goal") {
                ForEach(VisaGoal.allCases) { g in
                    optionRow(titleKey: g.titleKey, isSelected: goal == g) {
                        goal = g
                        if !g.needsQualification { qualification = nil }
                    }
                }
            }

            if goal?.needsQualification == true {
                question("tool_visafit_q_qual") {
                    ForEach(VisaQualification.allCases) { q in
                        optionRow(titleKey: q.titleKey, isSelected: qualification == q) {
                            qualification = q
                        }
                    }
                }
            }

            if !routes.isEmpty { resultsSection }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Questions

    private func question<Content: View>(
        _ titleKey: LocalizedStringKey, @ViewBuilder options: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(titleKey)
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            options()
        }
    }

    private func optionRow(
        titleKey: String, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkFaint)
                Text(LocalizedStringKey(titleKey))
                    .appText(.body)
                    .foregroundStyle(AppColor.ink)
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

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_visafit_results_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(Array(routes.enumerated()), id: \.element.id) { index, route in
                routeCard(route, isPrimary: index == 0)
            }
        }
    }

    private func routeCard(_ route: VisaFitRoute, isPrimary: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Text(LocalizedStringKey(route.titleKey))
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
                if isPrimary {
                    Text("tool_visafit_best_match")
                        .appText(.caption)
                        .foregroundStyle(AppColor.primaryDeep)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColor.primary.opacity(0.14), in: Capsule())
                }
            }
            Text(LocalizedStringKey(route.detailKey))
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let guideId = route.guideId {
                Button { onOpenGuide(guideId) } label: {
                    HStack(spacing: AppSpacing.xxs) {
                        Text("tool_visafit_learn_more")
                        Image(systemName: "chevron.forward").imageScale(.small)
                    }
                    .appText(.label)
                    .foregroundStyle(AppColor.primaryDeep)
                }
                .buttonStyle(.plain)
                .padding(.top, AppSpacing.xxs)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (isPrimary ? AppColor.primaryWash : AppColor.card),
            in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(isPrimary ? AppColor.primary.opacity(0.3) : AppColor.line, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        VisaFitView(goal: .job, qualification: .academic)
    }
    .appFontDesign()
}
