import Foundation

/// Schengen 90/180 short-stay counter types (P6-T5).
///
/// Rule: a non-EU short-stay visitor may be present in the Schengen area at most
/// **90 days within any rolling 180-day period**. The tool counts days of
/// presence in the trailing 180-day window ending on a reference date and reports
/// how many of the 90 allowed days remain.
///
/// These are not yearly-changing figures — 90/180 is fixed in the Schengen
/// Borders Code — but they are named constants so the rule reads clearly and the
/// engine never hard-codes magic numbers.

/// One stay in the Schengen area: present every day from `entry` to `exit`
/// inclusive (both the entry day and the exit day count as days of presence —
/// the official Schengen rule). Identifiable with a stable id so the editable
/// list of stays can add/update/delete rows.
struct SchengenStay: Identifiable, Equatable {
    let id: UUID
    var entry: Date
    var exit: Date

    init(id: UUID = UUID(), entry: Date, exit: Date) {
        self.id = id
        self.entry = entry
        self.exit = exit
    }
}

/// The computed usage for a reference date.
struct SchengenUsage: Equatable {
    /// Distinct days of presence within the trailing 180-day window.
    let daysUsed: Int
    /// Days still available: `max(0, maxDays - daysUsed)` — never negative even
    /// when the traveller has overstayed.
    let daysRemaining: Int
    /// Start of the trailing window (`referenceDate - (windowDays - 1)` days,
    /// start-of-day).
    let windowStart: Date
    /// The "as of" date the window ends on (start-of-day).
    let referenceDate: Date

    /// Maximum days of presence allowed in the rolling window.
    static let maxDays = 90
    /// Length of the rolling window in calendar days.
    static let windowDays = 180
}
