import Foundation
import SwiftData
@testable import Alltag

/// A ``ReminderScheduling`` that records calls instead of touching
/// `UNUserNotificationCenter`, so the store's scheduling decisions are
/// assertable (P3-06/08).
actor RecordingReminderScheduler: ReminderScheduling {
    private(set) var scheduled: [ReminderRequest] = []
    private(set) var cancelled: [ReminderRequest] = []

    func schedule(_ request: ReminderRequest) async { scheduled.append(request) }
    func cancel(_ request: ReminderRequest) async { cancelled.append(request) }

    func scheduledRequests() -> [ReminderRequest] { scheduled }
    func cancelledRequests() -> [ReminderRequest] { cancelled }
}

enum CalendarTestFactory {
    /// An in-memory `PersistenceController` for store tests. **Return the
    /// controller, not just its context** — the context only weakly relates to
    /// its container, so a caller that keeps only the context lets the container
    /// deallocate and the next fetch traps. Tests retain this.
    @MainActor
    static func persistence() throws -> PersistenceController {
        try PersistenceController(inMemory: true)
    }

    /// `daysFromNow` days out, at noon, to avoid start-of-day edge effects.
    static func date(daysFromNow days: Int, now: Date = .now) -> Date {
        let cal = Calendar.current
        let day = cal.date(byAdding: .day, value: days, to: now)!
        return cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)!
    }
}
