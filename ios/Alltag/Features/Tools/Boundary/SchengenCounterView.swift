import SwiftUI

/// Schengen 90/180-day counter (P6-T5): enter your past/planned stays and an
/// "as of" date, and see how many of the 90 allowed days you have used in the
/// trailing 180-day window — and how many remain.
///
/// All the arithmetic lives in the pure `SchengenCounter` engine; this screen is
/// input + presentation. Carries the RDG note — it estimates, the binding
/// calculation is the official EU one.
struct SchengenCounterView: View {

    /// The stays the traveller has entered. **Session-only by design:** this is a
    /// quick what-if estimator, not a tracker — held in `@State` and deliberately
    /// NOT persisted (no `@AppStorage`/SwiftData/file). Travel dates are sensitive
    /// and the rule is recomputed fresh each visit (KISS, D4 privacy).
    @State private var stays: [SchengenStay]

    /// The "as of" date the trailing window ends on. Defaults to today at runtime
    /// but is injectable so snapshot tests pass a fixed date.
    @State private var referenceDate: Date

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    init(
        stays: [SchengenStay]? = nil,
        referenceDate: Date = .now,
        embedInScrollView: Bool = true
    ) {
        // Seed a couple of plausible stays so previews/tests show a populated list.
        let seeded = stays ?? Self.seededStays(asOf: referenceDate)
        self._stays = State(initialValue: seeded)
        self._referenceDate = State(initialValue: referenceDate)
        self.embedInScrollView = embedInScrollView
    }

    /// Two example stays ending shortly before the reference date.
    private static func seededStays(asOf ref: Date) -> [SchengenStay] {
        let cal = SchengenCounter.fixedCalendar
        func day(_ offset: Int) -> Date {
            cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: ref))!
        }
        return [
            SchengenStay(entry: day(-120), exit: day(-110)),
            SchengenStay(entry: day(-40), exit: day(-26)),
        ]
    }

    private var usage: SchengenUsage {
        SchengenCounter.usage(stays: stays, asOf: referenceDate)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_schengen_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_schengen_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            referenceSection
            staysSection
            resultCard

            Text("tool_schengen_official_note")
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Reference date

    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_schengen_asof_label")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            DatePicker(
                "tool_schengen_asof_label",
                selection: $referenceDate,
                displayedComponents: .date)
                .labelsHidden()
                .tint(AppColor.primary)
        }
    }

    // MARK: - Stays

    private var staysSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_schengen_stays_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Editable, session-only list (see `stays`).
            ForEach($stays) { $stay in
                stayRow($stay)
            }
            Button {
                stays.append(newStay())
            } label: {
                Label("tool_schengen_add_stay", systemImage: "plus.circle.fill")
                    .appText(.label)
                    .foregroundStyle(AppColor.primaryDeep)
            }
            .buttonStyle(.plain)
        }
    }

    private func stayRow(_ stay: Binding<SchengenStay>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                DatePicker(
                    "tool_schengen_entry_label",
                    selection: stay.entry,
                    displayedComponents: .date)
                    .tint(AppColor.primary)
                Button {
                    stays.removeAll { $0.id == stay.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AppColor.severityUrgent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("tool_schengen_delete_stay")
            }
            DatePicker(
                "tool_schengen_exit_label",
                selection: stay.exit,
                displayedComponents: .date)
                .tint(AppColor.primary)
        }
        .appText(.body)
        .foregroundStyle(AppColor.ink)
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
    }

    /// A fresh 1-day stay on the reference date for the user to adjust.
    private func newStay() -> SchengenStay {
        let day = SchengenCounter.fixedCalendar.startOfDay(for: referenceDate)
        return SchengenStay(entry: day, exit: day)
    }

    // MARK: - Result

    private var resultCard: some View {
        let u = usage
        let tint = resultTint(for: u)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(usedLine(u), systemImage: "calendar")
                .appText(.cardTitle)
                .foregroundStyle(tint)
            Text(remainingLine(u))
                .appText(.bodyEmphasis)
                .foregroundStyle(tint)
            if u.daysRemaining == 0 {
                Text("tool_schengen_at_limit")
                    .appText(.body)
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
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

    /// Green with headroom, amber when few days left, urgent at/over the limit.
    private func resultTint(for u: SchengenUsage) -> Color {
        if u.daysRemaining == 0 { return AppColor.severityUrgent }
        if u.daysRemaining <= 14 { return AppColor.amber }
        return AppColor.primary
    }

    private func usedLine(_ u: SchengenUsage) -> String {
        String(
            format: String(localized: "tool_schengen_used_fmt"),
            u.daysUsed, SchengenUsage.maxDays)
    }

    private func remainingLine(_ u: SchengenUsage) -> String {
        String(format: String(localized: "tool_schengen_remaining_fmt"), u.daysRemaining)
    }
}

#Preview {
    NavigationStack { SchengenCounterView() }
        .appFontDesign()
}
