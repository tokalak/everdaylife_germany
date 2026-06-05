import SwiftUI

/// The Dates/Termine agenda (P3-07): deadlines grouped by urgency, each with a
/// severity stripe and a day countdown, plus manual add and mark-done. Entries
/// auto-populate from decoded letters and document expiries (P3-08/06).
struct DatesView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showAdd = false

    private var store: DeadlineStore { env.deadlines }

    var body: some View {
        NavigationStack {
            Group {
                if store.isEmpty {
                    EmptyState(
                        systemImage: "calendar.badge.clock",
                        titleKey: "dates_empty_title",
                        messageKey: "dates_empty_message",
                        actionTitleKey: "dates_add",
                        action: { showAdd = true })
                    .padding(AppSpacing.lg)
                } else {
                    agenda
                }
            }
            .background(AppColor.paper)
            .navigationTitle("tab_dates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("dates_add")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddDeadlineSheet { title, date, severity in
                    store.add(title: title, dueDate: date, severity: severity)
                }
            }
        }
    }

    private var agenda: some View {
        List {
            ForEach(store.groups(), id: \.bucket) { group in
                Section {
                    ForEach(group.deadlines) { deadline in
                        DeadlineRow(deadline: deadline) {
                            store.setDone(deadline, !deadline.isDone)
                        }
                        .listRowInsets(EdgeInsets(
                            top: AppSpacing.xxs, leading: AppSpacing.md,
                            bottom: AppSpacing.xxs, trailing: AppSpacing.md))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                store.remove(deadline)
                            } label: {
                                Label("dates_delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                store.setDone(deadline, !deadline.isDone)
                            } label: {
                                Label(
                                    deadline.isDone ? "dates_mark_undone" : "dates_mark_done",
                                    systemImage: deadline.isDone ? "arrow.uturn.left" : "checkmark")
                            }
                            .tint(AppColor.primary)
                        }
                    }
                } header: {
                    Text(LocalizedStringKey(group.bucket.titleKey))
                        .appText(.sectionHeader)
                        .foregroundStyle(AppColor.inkSoft)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

/// One deadline in the agenda: a severity stripe, title + day countdown + a
/// source hint, and a done toggle.
struct DeadlineRow: View {
    let deadline: Deadline
    var onToggleDone: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(deadline.isDone ? AppColor.line : deadline.severity.color)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(deadline.title)
                    .appText(.bodyEmphasis)
                    .foregroundStyle(deadline.isDone ? AppColor.inkFaint : AppColor.ink)
                    .strikethrough(deadline.isDone, color: AppColor.inkFaint)
                HStack(spacing: AppSpacing.xs) {
                    Text(DatesFormat.countdown(for: deadline.dueDate))
                        .appText(.label)
                        .foregroundStyle(deadline.isDone ? AppColor.inkFaint : deadline.severity.color)
                    Text("· \(deadline.dueDate, format: .dateTime.day().month(.abbreviated))")
                        .appText(.label)
                        .foregroundStyle(AppColor.inkFaint)
                    if deadline.source != .manual {
                        Image(systemName: deadline.source == .decoded
                            ? "doc.text.viewfinder" : "folder")
                            .appText(.label)
                            .foregroundStyle(AppColor.inkFaint)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onToggleDone) {
                Image(systemName: deadline.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(deadline.isDone ? AppColor.primary : AppColor.inkFaint)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(deadline.isDone ? "dates_mark_undone" : "dates_mark_done")
        }
        .padding(AppSpacing.sm)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .appShadow(.sm)
    }
}

/// Presentation helpers for the Dates screen (localized, day-floored countdowns).
enum DatesFormat {
    /// "Today" / "Tomorrow" / "Yesterday" / "in N days" / "N days overdue".
    /// Day-floored, so a deadline later today still reads "Today". Counts of 1
    /// are handled by the tomorrow/yesterday cases, so the `%lld` strings only
    /// ever render n ≥ 2 — no plural-variation table needed.
    static func countdown(for due: Date, now: Date = .now) -> String {
        let days = DeadlineUrgency.daysUntil(due, from: now)
        switch days {
        case 0:  return String(localized: "dates_due_today")
        case 1:  return String(localized: "dates_due_tomorrow")
        case -1: return String(localized: "dates_due_yesterday")
        case 2...:
            return String(format: String(localized: "dates_due_in_days"), days)
        default:
            return String(format: String(localized: "dates_overdue_days"), -days)
        }
    }
}
