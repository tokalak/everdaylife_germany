import SwiftUI

/// Student work-allowance tracker (P6-S5): log your work days and see how much of
/// the annual **140 full / 280 half** day allowance (a permit condition) you have
/// used and what remains.
///
/// All the arithmetic lives in the pure `WorkingHoursTracker` engine; this screen
/// is input + presentation. Carries the RDG note — it estimates the allowance use;
/// the binding limit is set by the Ausländerbehörde on the permit.
struct WorkingHoursView: View {

    /// The logged work days. **Session-only by design:** this is a quick
    /// what-if estimator, not a long-term log — held in `@State` and deliberately
    /// NOT persisted (no `@AppStorage`/SwiftData/file). The allowance is recomputed
    /// fresh each visit (KISS, D4 privacy).
    @State private var days: [WorkDay]

    /// Opens a cross-persona guide by id; the limit is a permit condition.
    var onOpenGuide: (String) -> Void

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    private let guideId = "residence_permit"

    init(
        days: [WorkDay]? = nil,
        onOpenGuide: @escaping (String) -> Void = { _ in },
        embedInScrollView: Bool = true
    ) {
        // Seed a couple of plausible days so previews/tests show a populated list.
        self._days = State(initialValue: days ?? Self.seededDays())
        self.onOpenGuide = onOpenGuide
        self.embedInScrollView = embedInScrollView
    }

    /// One full day (8h) and one half day (3h).
    private static func seededDays() -> [WorkDay] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        func day(_ offset: Int) -> Date {
            cal.date(byAdding: .day, value: offset, to: today) ?? today
        }
        return [
            WorkDay(date: day(-7), hours: 8),
            WorkDay(date: day(-2), hours: 3),
        ]
    }

    private var usage: WorkAllowanceUsage {
        WorkingHoursTracker.usage(days: days)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_working_hours_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_working_hours_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            daysSection
            resultCard
            learnMore
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Logged days

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_working_hours_days_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Editable, session-only list (see `days`).
            ForEach($days) { $day in
                dayRow($day)
            }
            Button {
                days.append(newDay())
            } label: {
                Label("tool_working_hours_add_day", systemImage: "plus.circle.fill")
                    .appText(.label)
                    .foregroundStyle(AppColor.primaryDeep)
            }
            .buttonStyle(.plain)
        }
    }

    private func dayRow(_ day: Binding<WorkDay>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                DatePicker(
                    "tool_working_hours_date_label",
                    selection: day.date,
                    displayedComponents: .date)
                    .tint(AppColor.primary)
                Button {
                    days.removeAll { $0.id == day.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AppColor.severityUrgent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("tool_working_hours_delete_day")
            }
            Stepper(
                value: day.hours, in: 0...24, step: 0.5) {
                Text(hoursLine(day.wrappedValue.hours))
                    .appText(.body)
                    .foregroundStyle(AppColor.ink)
            }
            .tint(AppColor.primary)
            Text(day.wrappedValue.hours > WorkAllowance.current.halfDayMaxHours
                 ? "tool_working_hours_counts_full"
                 : "tool_working_hours_counts_half")
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
        }
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
    }

    /// A fresh full day (8h) on today for the user to adjust.
    private func newDay() -> WorkDay {
        WorkDay(date: Calendar.current.startOfDay(for: .now), hours: 8)
    }

    // MARK: - Result

    private var resultCard: some View {
        let u = usage
        let tint = resultTint(for: u)
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(usedLine(u), systemImage: "clock")
                .appText(.cardTitle)
                .foregroundStyle(tint)
            Text(countsLine(u))
                .appText(.body)
                .foregroundStyle(tint)
            Text(remainingLine(u))
                .appText(.bodyEmphasis)
                .foregroundStyle(tint)
            if u.remainingEquivalents == 0 {
                Text("tool_working_hours_at_limit")
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

    /// Green with headroom, amber when few equivalents left, urgent at/over limit.
    private func resultTint(for u: WorkAllowanceUsage) -> Color {
        if u.remainingEquivalents == 0 { return AppColor.severityUrgent }
        if u.remainingEquivalents <= 14 { return AppColor.amber }
        return AppColor.primary
    }

    // MARK: - Learn more

    private var learnMore: some View {
        Button { onOpenGuide(guideId) } label: {
            HStack(spacing: AppSpacing.xxs) {
                Text("tool_working_hours_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Formatting

    /// "8 h" / "3.5 h" — trims trailing `.0`.
    private func hoursLine(_ hours: Double) -> String {
        String(format: String(localized: "tool_working_hours_hours_fmt"), Self.number(hours))
    }

    private func usedLine(_ u: WorkAllowanceUsage) -> String {
        String(
            format: String(localized: "tool_working_hours_used_fmt"),
            Self.number(u.usedEquivalents), WorkAllowance.current.maxFullDays)
    }

    private func countsLine(_ u: WorkAllowanceUsage) -> String {
        String(
            format: String(localized: "tool_working_hours_counts_fmt"),
            u.fullDays, u.halfDays)
    }

    private func remainingLine(_ u: WorkAllowanceUsage) -> String {
        String(
            format: String(localized: "tool_working_hours_remaining_fmt"),
            Self.number(u.remainingEquivalents))
    }

    /// Formats a Double dropping a trailing `.0` (e.g. 0.5 → "0.5", 140.0 → "140").
    private static func number(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview {
    NavigationStack { WorkingHoursView() }
        .appFontDesign()
}
