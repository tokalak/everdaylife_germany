import Foundation
import Observation
import SwiftData

/// Owns the user's deadlines: CRUD over SwiftData plus reminder scheduling
/// (P3-07/08).
///
/// The single place the Dates agenda, the Decoder's "add to calendar", and Vault
/// expiry population all go through, so scheduling stays consistent. Reminders
/// are (re)scheduled on add/restore and cancelled on done/delete — at **14, 7 and
/// 1 day** before (A-15/P3-08). The `ReminderScheduling` seam is injected, so the
/// store's scheduling decisions unit-test against a recording stub.
@MainActor
@Observable
final class DeadlineStore {
    /// Lead times for deadline reminders, in days before the due date (P3-08).
    static let reminderOffsets = [14, 7, 1]
    /// Identifier namespace for deadline notifications (vs Vault expiries).
    static let reminderPrefix = "deadline"

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let scheduler: any ReminderScheduling

    private(set) var deadlines: [Deadline] = []

    init(context: ModelContext, scheduler: any ReminderScheduling) {
        self.context = context
        self.scheduler = scheduler
        reload()
    }

    /// Deadlines grouped + sorted for the agenda (P3-07).
    func groups(now: Date = .now) -> [(bucket: DeadlineBucket, deadlines: [Deadline])] {
        DeadlineUrgency.grouped(deadlines, now: now)
    }

    var isEmpty: Bool { deadlines.isEmpty }

    func reload() {
        // Sort in memory rather than via a SortDescriptor keypath, which traps in
        // SwiftData on the current SDK; the result set is small (a user's
        // deadlines), so this is cheap.
        let all = (try? context.fetch(FetchDescriptor<Deadline>())) ?? []
        deadlines = all.sorted { $0.dueDate < $1.dueDate }
    }

    /// Add a new deadline and schedule its reminders. Returns the inserted model.
    @discardableResult
    func add(
        title: String,
        dueDate: Date,
        severity: Severity = .action,
        note: String? = nil,
        source: DeadlineSource = .manual,
        sourceId: String? = nil
    ) -> Deadline {
        let deadline = Deadline(
            title: title, dueDate: dueDate, severity: severity,
            note: note, source: source, sourceId: sourceId)
        context.insert(deadline)
        persist()
        scheduleReminders(for: deadline)
        return deadline
    }

    /// Create-or-update a deadline keyed by `source` + `sourceId` (P3-08): a
    /// re-decoded letter or a changed document expiry refreshes the existing
    /// entry instead of piling up duplicates.
    @discardableResult
    func upsert(
        source: DeadlineSource,
        sourceId: String,
        title: String,
        dueDate: Date,
        severity: Severity = .action,
        note: String? = nil
    ) -> Deadline {
        if let existing = deadlines.first(
            where: { $0.source == source && $0.sourceId == sourceId }) {
            existing.title = title
            existing.dueDate = dueDate
            existing.severity = severity
            existing.note = note
            persist()
            if existing.isDone {
                cancelReminders(for: existing)
            } else {
                scheduleReminders(for: existing)
            }
            return existing
        }
        return add(
            title: title, dueDate: dueDate, severity: severity,
            note: note, source: source, sourceId: sourceId)
    }

    /// Mark done (or not). Done deadlines keep a record but lose their reminders.
    func setDone(_ deadline: Deadline, _ done: Bool) {
        deadline.isDone = done
        persist()
        if done {
            cancelReminders(for: deadline)
        } else {
            scheduleReminders(for: deadline)
        }
    }

    func remove(_ deadline: Deadline) {
        cancelReminders(for: deadline)
        context.delete(deadline)
        persist()
    }

    /// Remove every deadline (GDPR "delete all data", P3-09).
    func removeAll() {
        for deadline in deadlines { cancelReminders(for: deadline) }
        try? context.delete(model: Deadline.self)
        persist()
    }

    // MARK: - Internals

    private func persist() {
        try? context.save()
        reload()
    }

    private func reminderRequest(for deadline: Deadline) -> ReminderRequest {
        ReminderRequest(
            id: deadline.id,
            title: String(localized: "reminder_deadline_title"),
            body: deadline.title,
            date: deadline.dueDate,
            offsetsInDays: Self.reminderOffsets,
            idPrefix: Self.reminderPrefix)
    }

    private func scheduleReminders(for deadline: Deadline) {
        guard !deadline.isDone else { return }
        let request = reminderRequest(for: deadline)
        Task { await scheduler.schedule(request) }
    }

    private func cancelReminders(for deadline: Deadline) {
        let request = reminderRequest(for: deadline)
        Task { await scheduler.cancel(request) }
    }
}
