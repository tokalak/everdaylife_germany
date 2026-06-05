import SwiftUI

/// EU Blue Card threshold checker (P6-W2): set the offered gross salary and
/// whether it's a shortage occupation / new-entrant role, and see whether it
/// clears the year's threshold — and by how much if not.
///
/// The verdict comes from the pure `BlueCardEngine` over isolated yearly figures
/// (`BlueCardThresholds`); this screen is input + presentation. Carries the RDG
/// note and reminds the user a recognised degree is also required.
struct BlueCardView: View {
    var onOpenGuide: (String) -> Void = { _ in }

    @State private var salary: Double
    @State private var isShortage: Bool
    var embedInScrollView: Bool

    private let thresholds = BlueCardThresholds.current

    init(
        salary: Double = 45_000,
        isShortage: Bool = false,
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._salary = State(initialValue: salary)
        self._isShortage = State(initialValue: isShortage)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var result: BlueCardResult {
        BlueCardEngine.evaluate(
            BlueCardInput(grossAnnualSalary: salary, isShortageOccupation: isShortage),
            thresholds: thresholds)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_blue_card_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_bluecard_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            salarySection
            shortageSection
            resultCard

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

    // MARK: - Inputs

    private var salarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("tool_bluecard_salary_label")
                    .appText(.sectionHeader)
                    .foregroundStyle(AppColor.ink)
                Spacer()
                Text(money(salary))
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.primaryDeep)
            }
            Slider(value: $salary, in: 20_000...120_000, step: 1_000)
                .tint(AppColor.primary)
                .accessibilityLabel("tool_bluecard_salary_label")
                .accessibilityValue(money(salary))
        }
    }

    private var shortageSection: some View {
        Toggle(isOn: $isShortage) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("tool_bluecard_shortage_label")
                    .appText(.bodyEmphasis)
                    .foregroundStyle(AppColor.ink)
                Text("tool_bluecard_shortage_hint")
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

    // MARK: - Result

    private var resultCard: some View {
        let eligible = result.isEligible
        let tint = eligible ? AppColor.primary : AppColor.severityUrgent
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(
                eligible ? "tool_bluecard_meets" : "tool_bluecard_below",
                systemImage: eligible ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .appText(.cardTitle)
                .foregroundStyle(tint)
            Text(thresholdLine)
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            if case let .belowThreshold(_, shortfall) = result {
                Text(shortfallLine(shortfall))
                    .appText(.bodyEmphasis)
                    .foregroundStyle(tint)
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

    private var thresholdLine: String {
        let applicable: Double = {
            switch result {
            case let .meetsThreshold(a), let .belowThreshold(a, _): return a
            }
        }()
        return String(
            format: String(localized: "tool_bluecard_threshold_fmt"),
            thresholds.year, money(applicable))
    }

    private func shortfallLine(_ shortfall: Double) -> String {
        String(format: String(localized: "tool_bluecard_shortfall_fmt"), money(shortfall))
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

#Preview {
    NavigationStack { BlueCardView(salary: 52_000) }
        .appFontDesign()
}
