import SwiftUI

/// Blocked account (Sperrkonto) comparison (P6-S2) — an affiliate/comparison
/// tool (P6-A1): a transparently ranked list of real providers students use to
/// open the blocked account a student visa requires, with factual highlights, a
/// "best for" tag and an open-link button.
///
/// The ranked list comes from the pure `BlockedAccountEngine` over the isolated,
/// versioned `BlockedAccountCatalog`; this screen is filter + presentation,
/// mirroring `BankCompareView`/`TravelInsuranceView` (KISS/DRY). It surfaces the
/// **required blocked amount** (versioned `BlockedAccountRequirement`), always
/// shows 3+ options, carries an explicit **affiliate transparency disclosure**
/// (some links may earn a commission, which never affects ranking or the price
/// you pay) and the RDG note — information only, never advice.
struct BlockedAccountView: View {
    var onOpenGuide: (String) -> Void = { _ in }

    /// Filter to providers with English-language onboarding/support.
    @State private var englishOnly: Bool
    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    private let requirement = BlockedAccountEngine.requirement()

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
        BlockedAccountEngine.rankedOptions(englishSupportOnly: englishOnly)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_blocked_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_blocked_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            requiredAmount

            affiliateDisclosure
            DisclaimerNote()

            englishFilter

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    optionCard(option, rank: index + 1)
                }
            }

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

    // MARK: - Required amount

    private var requiredAmount: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "target")
                .foregroundStyle(AppColor.primary)
            Text(requiredAmountLine)
                .appText(.label)
                .foregroundStyle(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.md)
        .background(
            AppColor.primaryWash,
            in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColor.primary.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var requiredAmountLine: String {
        String(
            format: String(localized: "tool_blocked_required_fmt"),
            requirement.year, money(requirement.annualTotal), money(requirement.monthlyAllowance))
    }

    // MARK: - Transparency

    private var affiliateDisclosure: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppColor.amber)
            Text("tool_blocked_affiliate_disclosure")
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.md)
        .background(
            AppColor.amberWash,
            in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColor.amber.opacity(0.4), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Filter

    private var englishFilter: some View {
        Toggle(isOn: $englishOnly) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("tool_blocked_filter_english")
                    .appText(.bodyEmphasis)
                    .foregroundStyle(AppColor.ink)
                Text("tool_blocked_filter_english_hint")
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
                if option.isAffiliate {
                    Text("tool_blocked_affiliate_tag")
                        .appText(.caption)
                        .foregroundStyle(AppColor.severityAction)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColor.amberWash, in: Capsule())
                }
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
                        Text("tool_blocked_open_action")
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
            Text("tool_blocked_best_for")
                .appText(.caption)
                .foregroundStyle(AppColor.inkSoft)
            Text(LocalizedStringKey(key))
                .appText(.caption)
                .foregroundStyle(AppColor.primaryDeep)
        }
    }

    private func feeLine(_ key: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Text("tool_blocked_fee_label")
                .appText(.caption)
                .foregroundStyle(AppColor.inkSoft)
            Text(LocalizedStringKey(key))
                .appText(.caption)
                .foregroundStyle(AppColor.ink)
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

#Preview {
    NavigationStack { BlockedAccountView() }
        .appFontDesign()
}
