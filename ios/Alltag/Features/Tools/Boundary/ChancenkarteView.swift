import SwiftUI

/// Chancenkarte points calculator (P6-W3): answer a short set of criteria and
/// see your running points total against the year's threshold (6), plus a
/// qualifies / short-by-N verdict. Full recognition of a qualification
/// short-circuits to "qualifies directly".
///
/// The verdict comes from the pure `ChancenkarteEngine` over isolated yearly
/// values (`ChancenkartePoints`); this screen is input + presentation. Carries
/// the RDG note and reminds the user of the baseline requirements.
struct ChancenkarteView: View {
    var onOpenGuide: (String) -> Void = { _ in }

    @State private var input: ChancenkarteInput
    var embedInScrollView: Bool

    private let points = ChancenkartePoints.current

    init(
        input: ChancenkarteInput = ChancenkarteInput(),
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._input = State(initialValue: input)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var result: ChancenkarteResult {
        ChancenkarteEngine.evaluate(input, points: points)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_chancenkarte_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_ck_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            recognitionSection

            if !input.hasFullRecognition {
                criteria
            }

            meterCard

            Button { onOpenGuide("residence_permit") } label: {
                HStack(spacing: AppSpacing.xxs) {
                    Text("tool_visafit_learn_more")
                    Image(systemName: "chevron.forward").imageScale(.small)
                }
                .appText(.label)
                .foregroundStyle(AppColor.primaryDeep)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Recognition shortcut

    private var recognitionSection: some View {
        Toggle(isOn: $input.hasFullRecognition) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("tool_ck_recognition_label")
                    .appText(.bodyEmphasis)
                    .foregroundStyle(AppColor.ink)
                Text("tool_ck_recognition_hint")
                    .appText(.label)
                    .foregroundStyle(AppColor.inkSoft)
            }
        }
        .tint(AppColor.primary)
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
    }

    // MARK: - Criteria

    private var criteria: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            picker(
                "tool_ck_q_german", "tool_ck_q_german_hint",
                CKGerman.allCases, selection: input.german,
                points: { points.german[$0] ?? 0 }, select: { input.german = $0 })

            picker(
                "tool_ck_q_english", "tool_ck_q_english_hint",
                CKEnglish.allCases, selection: input.english,
                points: { points.english[$0] ?? 0 }, select: { input.english = $0 })

            picker(
                "tool_ck_q_age", "tool_ck_q_age_hint",
                CKAge.allCases, selection: input.age,
                points: { points.age[$0] ?? 0 }, select: { input.age = $0 })

            picker(
                "tool_ck_q_exp", "tool_ck_q_exp_hint",
                CKExperience.allCases, selection: input.experience,
                points: { points.experience[$0] ?? 0 }, select: { input.experience = $0 })

            yesNo(
                "tool_ck_q_shortage", "tool_ck_q_shortage_hint",
                value: $input.isShortageOccupation, points: points.shortageOccupation)
            yesNo(
                "tool_ck_q_prev", "tool_ck_q_prev_hint",
                value: $input.hadPreviousStay, points: points.previousStay)
            yesNo(
                "tool_ck_q_partner", "tool_ck_q_partner_hint",
                value: $input.partnerApplying, points: points.partnerApplying)
        }
    }

    /// A single-select criterion with a points badge per option.
    private func picker<Option: Identifiable & Equatable>(
        _ titleKey: LocalizedStringKey, _ hintKey: LocalizedStringKey,
        _ options: [Option], selection: Option,
        points: @escaping (Option) -> Int, select: @escaping (Option) -> Void
    ) -> some View where Option: CKTitled {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            question(titleKey, hintKey)
            ForEach(options) { option in
                optionRow(
                    titleKey: option.titleKey, pts: points(option),
                    isSelected: selection == option) { select(option) }
            }
        }
    }

    /// A yes/no criterion rendered as a toggle with its points value.
    private func yesNo(
        _ titleKey: LocalizedStringKey, _ hintKey: LocalizedStringKey,
        value: Binding<Bool>, points: Int
    ) -> some View {
        Toggle(isOn: value) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(titleKey)
                        .appText(.bodyEmphasis)
                        .foregroundStyle(AppColor.ink)
                    pointsBadge(points)
                }
                Text(hintKey)
                    .appText(.label)
                    .foregroundStyle(AppColor.inkSoft)
            }
        }
        .tint(AppColor.primary)
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
    }

    private func question(_ titleKey: LocalizedStringKey, _ hintKey: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(titleKey)
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            Text(hintKey)
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
        }
    }

    private func optionRow(
        titleKey: String, pts: Int, isSelected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkFaint)
                Text(LocalizedStringKey(titleKey))
                    .appText(.body)
                    .foregroundStyle(AppColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                pointsBadge(pts)
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

    private func pointsBadge(_ pts: Int) -> some View {
        Text(pts > 0 ? "+\(pts)" : "0")
            .appText(.caption)
            .foregroundStyle(pts > 0 ? AppColor.primaryDeep : AppColor.inkFaint)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background((pts > 0 ? AppColor.primary.opacity(0.14) : AppColor.line.opacity(0.4)), in: Capsule())
    }

    // MARK: - Meter / verdict

    private var meterCard: some View {
        let eligible = result.isEligible
        let tint = eligible ? AppColor.primary : AppColor.severityUrgent
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(scoreLine)
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
                Spacer()
                Label(
                    eligible ? "tool_ck_eligible" : verdictShortKey,
                    systemImage: eligible ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                    .appText(.label)
                    .foregroundStyle(tint)
            }
            ProgressView(
                value: Double(min(result.total, points.threshold)),
                total: Double(points.threshold))
                .tint(tint)
            Text(eligible ? "tool_ck_eligible_detail" : "tool_ck_below_detail")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(tint.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var scoreLine: String {
        String(format: String(localized: "tool_ck_score_fmt"), result.total, points.threshold)
    }

    /// "N more needed" — only used when below the threshold.
    private var verdictShortKey: LocalizedStringKey {
        if case let .belowThreshold(_, _, shortfall) = result {
            return LocalizedStringKey(
                String(format: String(localized: "tool_ck_more_needed_fmt"), shortfall))
        }
        return "tool_ck_eligible"
    }
}

/// Lets the generic `picker` read an option's localized title key.
protocol CKTitled { var titleKey: String { get } }
extension CKGerman: CKTitled {}
extension CKEnglish: CKTitled {}
extension CKAge: CKTitled {}
extension CKExperience: CKTitled {}

#Preview {
    NavigationStack {
        ChancenkarteView(input: ChancenkarteInput(german: .b2, age: .under35, experience: .from5))
    }
    .appFontDesign()
}
