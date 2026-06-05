import Foundation
import UserNotifications

/// A Sendable snapshot of something to be reminded about (P3-06/08).
///
/// Plain values (not a SwiftData `@Model`) so it can cross actor boundaries into
/// the scheduler. `offsetsInDays` are the lead times — `[14, 7, 1]` for deadline
/// reminders, `[60, 30, 7]` for document-expiry reminders — each producing one
/// local notification that many days before `date` (only future ones fire).
struct ReminderRequest: Sendable, Equatable {
    /// Stable id of the owning entity (deadline/document). Notification request
    /// identifiers are derived as `"<idPrefix>-<id>-<offset>"`, so re-scheduling
    /// replaces the prior set deterministically.
    let id: UUID
    let title: String
    let body: String
    let date: Date
    let offsetsInDays: [Int]
    /// Namespaces identifiers so deadlines and expiries never collide.
    let idPrefix: String

    init(
        id: UUID, title: String, body: String, date: Date,
        offsetsInDays: [Int], idPrefix: String
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.offsetsInDays = offsetsInDays
        self.idPrefix = idPrefix
    }

    /// The notification-request identifiers this request maps to (one per offset),
    /// regardless of whether they're in the past — used to cancel as well.
    var notificationIdentifiers: [String] {
        offsetsInDays.map { "\(idPrefix)-\(id.uuidString)-\($0)" }
    }
}

/// Schedules/cancels the local notifications behind a reminder (P3-06/08).
///
/// Abstracted like ``NotificationAuthorizing`` so the Vault/Calendar features
/// unit-test their scheduling decisions against a recording stub — no real
/// `UNUserNotificationCenter`, no waiting for notifications to fire.
protocol ReminderScheduling: Sendable {
    /// (Re)schedule all future reminders for `request`, replacing any prior set
    /// for the same id+prefix first.
    func schedule(_ request: ReminderRequest) async
    /// Cancel every reminder previously scheduled for this id+prefix+offsets.
    func cancel(_ request: ReminderRequest) async
}

/// Production scheduler over `UNUserNotificationCenter`.
struct SystemReminderScheduler: ReminderScheduling {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func schedule(_ request: ReminderRequest) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(
            withIdentifiers: request.notificationIdentifiers)

        let now = Date()
        for offset in request.offsetsInDays {
            guard let fireDate = calendar.date(
                byAdding: .day, value: -offset,
                to: calendar.startOfDay(for: request.date)),
                fireDate > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = request.title
            content.body = request.body
            content.sound = .default

            // Fire at 9am local on the reminder day, not midnight.
            var components = calendar.dateComponents(
                [.year, .month, .day], from: fireDate)
            components.hour = 9
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components, repeats: false)

            let id = "\(request.idPrefix)-\(request.id.uuidString)-\(offset)"
            try? await center.add(
                UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    func cancel(_ request: ReminderRequest) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: request.notificationIdentifiers)
    }
}
