import SwiftUI

/// GKV vs PKV decision tree (P6-W5): pick your insurance status — and, for
/// employees, your gross annual income — to see whether you must be in statutory
/// cover (GKV) or may choose private (PKV), with the trade-offs. Then a
/// transparently ranked list of real funds newcomers use.
///
/// The recommendation comes from the pure `HealthDecisionEngine` over the
/// isolated yearly threshold (`HealthInsuranceThreshold`); the ranked list from
/// the isolated `HealthInsurerCatalog`. This screen is selection + presentation.
/// It carries the RDG note, an explicit **affiliate transparency disclosure**
/// (some links may earn a commission, which never affects ranking or price) and
/// a "learn more" into the health-insurance guide — information only, never advice.
struct HealthDecisionView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void

    /// Seedable for previews/tests; the controls are the source of truth at runtime.
    @State private var status: HealthStatus?
    @State private var income: Double
    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    private let threshold = HealthInsuranceThreshold.current
    /// Guide opened from the "learn more" link.
    private let guideId = "health_insurance"

    init(
        status: HealthStatus? = nil,
        income: Double = 55_000,
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._status = State(initialValue: status)
        self._income = State(initialValue: income)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var input: HealthDecisionInput {
        HealthDecisionInput(status: status, grossAnnualIncome: income)
    }
    private var recommendation: HealthRecommendation? {
        HealthDecisionEngine.recommendation(for: input, threshold: threshold)
    }
    private var options: [ComparisonOption] {
        HealthInsurerCatalog.current.options
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_health_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_health_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            statusSection

            if status?.needsIncome == true { incomeSection }

            if let recommendation { resultCard(recommendation) }

            optionsSection
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Status question

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_health_q_status")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(HealthStatus.allCases) { s in
                optionRow(titleKey: s.titleKey, isSelected: status == s) {
                    status = s
                }
            }
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

    // MARK: - Income (employees only)

    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("tool_health_income_label")
                    .appText(.sectionHeader)
                    .foregroundStyle(AppColor.ink)
                Spacer()
                Text(money(income))
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.primaryDeep)
            }
            Slider(value: $income, in: 20_000...120_000, step: 1_000)
                .tint(AppColor.primary)
                .accessibilityLabel("tool_health_income_label")
                .accessibilityValue(money(income))
            Text(thresholdLine)
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var thresholdLine: String {
        String(
            format: String(localized: "tool_health_threshold_fmt"),
            threshold.year, money(threshold.compulsoryInsuranceLimit))
    }

    // MARK: - Result

    private func resultCard(_ recommendation: HealthRecommendation) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(
                LocalizedStringKey(recommendation.titleKey),
                systemImage: "cross.case.fill")
                .appText(.cardTitle)
                .foregroundStyle(AppColor.primaryDeep)
            Text(LocalizedStringKey(recommendation.detailKey))
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            tradeOffs

            Button { onOpenGuide(guideId) } label: {
                HStack(spacing: AppSpacing.xxs) {
                    Text("tool_health_learn_more")
                    Image(systemName: "chevron.forward").imageScale(.small)
                }
                .appText(.label)
                .foregroundStyle(AppColor.primaryDeep)
            }
            .buttonStyle(.plain)
            .padding(.top, AppSpacing.xxs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.primaryWash, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(AppColor.primary.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    /// Neutral GKV vs PKV trade-off summary shown with every result.
    private var tradeOffs: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            tradeOffColumn("tool_health_gkv_label", body: "tool_health_gkv_tradeoffs")
            tradeOffColumn("tool_health_pkv_label", body: "tool_health_pkv_tradeoffs")
        }
        .padding(.top, AppSpacing.xxs)
    }

    private func tradeOffColumn(_ titleKey: LocalizedStringKey, body bodyKey: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(titleKey)
                .appText(.bodyEmphasis)
                .foregroundStyle(AppColor.ink)
            Text(bodyKey)
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Insurer options

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_health_options_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)

            affiliateDisclosure

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    optionCard(option, rank: index + 1)
                }
            }
        }
    }

    private var affiliateDisclosure: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(AppColor.amber)
            Text("tool_health_affiliate_disclosure")
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
                    Text("tool_health_affiliate_tag")
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
                        Text("tool_health_open_action")
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
            Text("tool_health_best_for")
                .appText(.caption)
                .foregroundStyle(AppColor.inkSoft)
            Text(LocalizedStringKey(key))
                .appText(.caption)
                .foregroundStyle(AppColor.primaryDeep)
        }
    }

    private func feeLine(_ key: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Text("tool_health_fee_label")
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
    NavigationStack { HealthDecisionView(status: .employee, income: 80_000) }
        .appFontDesign()
}
