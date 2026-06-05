import Foundation

/// Schengen 90/180 rolling-window counter (P6-T5) — the PURE engine.
///
/// Highest-risk surface (A-05): exhaustively unit-tested. **No `Date.now` inside
/// the engine** — the reference date and calendar are injected so day math is
/// fully deterministic and tests are stable.
///
/// Algorithm: the trailing window is the `windowDays` (180) calendar days ending
/// on and including `referenceDate`, i.e. `windowStart = referenceDate − 179
/// days`. For every stay we add each calendar day of presence (entry…exit, both
/// inclusive) that falls inside `[windowStart, referenceDate]` to a `Set` of
/// start-of-day dates — so overlapping or adjacent stays never double-count a
/// shared day, and a day outside the window is simply skipped. `daysUsed` is the
/// size of that set; `daysRemaining = max(0, maxDays − daysUsed)`.
enum SchengenCounter {

    /// A calendar fixed to gregorian/UTC so day boundaries are deterministic
    /// regardless of the device locale or time zone.
    static let fixedCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func usage(
        stays: [SchengenStay],
        asOf referenceDate: Date,
        calendar: Calendar = fixedCalendar
    ) -> SchengenUsage {
        let refDay = calendar.startOfDay(for: referenceDate)
        // Window covers `windowDays` days inclusive of the reference day, so it
        // starts `windowDays - 1` days earlier.
        let windowStart = calendar.date(
            byAdding: .day, value: -(SchengenUsage.windowDays - 1), to: refDay)!

        var presentDays: Set<Date> = []
        for stay in stays {
            let entry = calendar.startOfDay(for: stay.entry)
            let exit = calendar.startOfDay(for: stay.exit)
            // Guard: a stay whose exit precedes its entry is invalid — ignore it.
            guard exit >= entry else { continue }
            // Clamp the stay to the window so out-of-window days never count.
            let from = max(entry, windowStart)
            let to = min(exit, refDay)
            guard to >= from else { continue }

            var day = from
            while day <= to {
                presentDays.insert(day)
                day = calendar.date(byAdding: .day, value: 1, to: day)!
            }
        }

        let used = presentDays.count
        let remaining = max(0, SchengenUsage.maxDays - used)
        return SchengenUsage(
            daysUsed: used,
            daysRemaining: remaining,
            windowStart: windowStart,
            referenceDate: refDay)
    }
}
