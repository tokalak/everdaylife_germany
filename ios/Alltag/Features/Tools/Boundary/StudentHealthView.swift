import SwiftUI

/// Student health-insurance comparison (P6-S3) — an affiliate/comparison tool
/// (P6-A1): a transparently ranked list of real options students use to get the
/// mandatory health cover enrolment requires, spanning the public GKV student
/// tariff (enrolled under ~30) and private/incoming insurance (over 30, language
/// or preparatory students), with factual highlights, a "best for" hint and an
/// open-link button.
///
/// The ranked list comes from the pure `StudentHealthEngine` over the isolated,
/// versioned `StudentHealthCatalog`; this screen is filter + presentation,
/// mirroring `BlockedAccountView`/`BankCompareView` (KISS/DRY). It always shows
/// 3+ options, carries an explicit **affiliate transparency disclosure** (some
/// links may earn a commission, which never affects ranking or the price you
/// pay) and the RDG note — information only, never advice. A "learn more" action
/// deep-links the `"health_insurance"` guide.
struct StudentHealthView: View {
    var onOpenGuide: (String) -> Void = { _ in }

    /// Filter to providers with English-language onboarding/support.
    @State private var englishOnly: Bool
    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    init(
        englishOnly: Bool = false,
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._englishOnly = State(initialValue: englishOnly)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var options: [ComparisonOption] {
        StudentHealthEngine.rankedOptions(englishSupportOnly: englishOnly)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_studenthealth_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_studenthealth_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            AffiliateDisclosure()
            DisclaimerNote()

            englishFilter

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    optionCard(option, rank: index + 1)
                }
            }

            Button { onOpenGuide("health_insurance") } label: {
                HStack(spacing: AppSpacing.xxs) {
                    Text("tool_studenthealth_learn_more")
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

    // MARK: - Filter

    private var englishFilter: some View {
        Toggle(isOn: $englishOnly) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("tool_studenthealth_filter_english")
                    .appText(.bodyEmphasis)
                    .foregroundStyle(AppColor.ink)
                Text("tool_studenthealth_filter_english_hint")
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

    // MARK: - Option card

    private func optionCard(_ option: ComparisonOption, rank: Int) -> some View {
        let isPrimary = rank == 1
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Text("#\(rank)")
                    .appText(.caption)
                    .foregroundStyle(AppColor.inkSoft)
                Text(option.name)
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
                Spacer(minLength: 0)
                if option.isAffiliate { AffiliateTag() }
            }

            Text(LocalizedStringKey(option.summaryKey))
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            bestForTag(option.bestForKey)
            feeLine(option.monthlyFeeKey)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                ForEach(option.highlightKeys, id: \.self) { key in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .imageScale(.small)
                            .foregroundStyle(AppColor.primary)
                        Text(LocalizedStringKey(key))
                            .appText(.label)
                            .foregroundStyle(AppColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.top, AppSpacing.xxs)

            if let url = option.url {
                Link(destination: url) {
                    HStack(spacing: AppSpacing.xxs) {
                        Text("tool_studenthealth_open_action")
                        Image(systemName: "arrow.up.forward.square").imageScale(.small)
                    }
                    .appText(.label)
                    .foregroundStyle(AppColor.primaryDeep)
                }
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

    private func bestForTag(_ key: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Text("tool_studenthealth_best_for")
                .appText(.caption)
                .foregroundStyle(AppColor.inkSoft)
            Text(LocalizedStringKey(key))
                .appText(.caption)
                .foregroundStyle(AppColor.primaryDeep)
        }
    }

    private func feeLine(_ key: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Text("tool_studenthealth_fee_label")
                .appText(.caption)
                .foregroundStyle(AppColor.inkSoft)
            Text(LocalizedStringKey(key))
                .appText(.caption)
                .foregroundStyle(AppColor.ink)
        }
    }
}

#Preview {
    NavigationStack { StudentHealthView() }
        .appFontDesign()
}
