import SwiftUI

/// Einbürgerung (German naturalisation) eligibility checker (P6-R2): tick the
/// standard-route conditions you meet under the **June 2024 reform** and see
/// whether you may qualify — and exactly what's still missing if not.
///
/// The verdict comes from the pure `CitizenshipEligibilityEngine` over the
/// versioned `CitizenshipRule`; this screen is input + presentation. Carries the
/// RDG note, explains the reform (5-year route, 3-year fast track, dual
/// citizenship now generally allowed), and deep-links the residence-permit guide
/// via "learn more".
struct CitizenshipEligibilityView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// Ids of the criteria the user has ticked. **Session-only by design:** a
    /// self-assessment, not a tracker — held in `@State` and deliberately NOT
    /// persisted (no `@AppStorage`/SwiftData/file write).
    @State private var satisfied: Set<String>

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    private let rule = CitizenshipRule.standard
    private let criteria = CitizenshipRule.standardCriteria
    private let guideId = "residence_permit"

    init(
        satisfied: Set<String> = [],
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._satisfied = State(initialValue: satisfied)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var result: CitizenshipResult {
        CitizenshipEligibilityEngine.evaluate(satisfied: satisfied, criteria: criteria)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_einbuergerung_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(introText)
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Text("tool_citizenship_dual_note")
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            criteriaSection
            resultCard
            learnMore
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var introText: String {
        String(
            format: String(localized: "tool_citizenship_intro_fmt"),
            rule.standardYears, rule.fastTrackYears)
    }

    // MARK: - Criteria

    private var criteriaSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_citizenship_criteria_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Session-only ticks (see `satisfied`) — a self-assessment, not a tracker.
            ForEach(criteria) { criterion in
                criterionRow(criterion)
            }
        }
    }

    private func criterionRow(_ criterion: CitizenshipCriterion) -> some View {
        let isOn = satisfied.contains(criterion.id)
        return Button {
            if isOn { satisfied.remove(criterion.id) } else { satisfied.insert(criterion.id) }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn ? AppColor.primary : AppColor.inkFaint)
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(LocalizedStringKey(criterion.labelKey))
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(detailText(for: criterion))
                        .appText(.label)
                        .foregroundStyle(AppColor.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .background(
                (isOn ? AppColor.primaryWash : AppColor.card),
                in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(isOn ? AppColor.primary.opacity(0.5) : AppColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }

    /// The residence-period criterion carries the versioned year counts; the rest
    /// are plain detail keys. `String(format:)` ignores absent placeholders.
    private func detailText(for criterion: CitizenshipCriterion) -> String {
        let template = String(localized: String.LocalizationValue(criterion.detailKey))
        switch criterion.id {
        case "residence_period": return String(format: template, rule.standardYears, rule.fastTrackYears)
        default:                 return template
        }
    }

    // MARK: - Result

    private var resultCard: some View {
        let eligible = result.isEligible
        let tint = eligible ? AppColor.primary : AppColor.severityUrgent
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label(
                eligible ? "tool_citizenship_eligible" : "tool_citizenship_not_yet",
                systemImage: eligible ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .appText(.cardTitle)
                .foregroundStyle(tint)
            Text(eligible ? "tool_citizenship_eligible_detail" : "tool_citizenship_not_yet_detail")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            if !result.missing.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    ForEach(result.missing) { criterion in
                        HStack(alignment: .top, spacing: AppSpacing.xs) {
                            Image(systemName: "circle")
                                .imageScale(.small)
                                .foregroundStyle(tint)
                            Text(LocalizedStringKey(criterion.labelKey))
                                .appText(.body)
                                .foregroundStyle(AppColor.ink)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.top, AppSpacing.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(tint.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Learn more

    private var learnMore: some View {
        Button { onOpenGuide(guideId) } label: {
            HStack(spacing: AppSpacing.xxs) {
                Text("tool_citizenship_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CitizenshipEligibilityView(satisfied: ["residence_period", "german_b1"])
    }
    .appFontDesign()
}
