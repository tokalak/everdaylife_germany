import Foundation

/// The urgency buckets the Dates agenda groups deadlines into (P3-07), in display
/// order. Done items sink to the bottom.
enum DeadlineBucket: Int, CaseIterable, Identifiable, Sendable {
    case overdue
    case today
    case thisWeek
    case later
    case done

    var id: Int { rawValue }

    /// Localized section-header key.
    var titleKey: String {
        switch self {
        case .overdue:  "dates_bucket_overdue"
        case .today:    "dates_bucket_today"
        case .thisWeek: "dates_bucket_this_week"
        case .later:    "dates_bucket_later"
        case .done:     "dates_bucket_done"
        }
    }
}

/// Pure date math for deadlines (P3-07) — bucketing and day countdowns —
/// isolated here so it's exhaustively unit-testable independent of SwiftData and
/// SwiftUI, with an injectable "now" and calendar (no hidden `Date.now`).
enum DeadlineUrgency {
    /// Whole calendar days from `now` to `due` (both floored to start-of-day):
    /// negative when overdue, 0 today, positive in the future. Day granularity is
    /// what the UI cares about — a deadline "today at 23:59" is still today.
    static func daysUntil(
        _ due: Date, from now: Date, calendar: Calendar = .current
    ) -> Int {
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: due)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// Which bucket a deadline falls in. Done always sinks to `.done`.
    static func bucket(
        for deadline: Deadline, now: Date, calendar: Calendar = .current
    ) -> DeadlineBucket {
        if deadline.isDone { return .done }
        let days = daysUntil(deadline.dueDate, from: now, calendar: calendar)
        switch days {
        case ..<0:    return .overdue
        case 0:       return .today
        case 1...7:   return .thisWeek
        default:      return .later
        }
    }

    /// Groups + sorts deadlines for the agenda: by bucket (display order), then
    /// soonest-first within a bucket (done items most-recent-first). Empty
    /// buckets are omitted. Returns tuples so the View can render sections.
    static func grouped(
        _ deadlines: [Deadline], now: Date, calendar: Calendar = .current
    ) -> [(bucket: DeadlineBucket, deadlines: [Deadline])] {
        var byBucket: [DeadlineBucket: [Deadline]] = [:]
        for deadline in deadlines {
            byBucket[bucket(for: deadline, now: now, calendar: calendar), default: []]
                .append(deadline)
        }
        return DeadlineBucket.allCases.compactMap { bucket in
            guard let items = byBucket[bucket], !items.isEmpty else { return nil }
            let sorted = items.sorted { a, b in
                bucket == .done ? a.dueDate > b.dueDate : a.dueDate < b.dueDate
            }
            return (bucket, sorted)
        }
    }
}
