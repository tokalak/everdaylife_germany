import Foundation

/// Student work-allowance tracker (P6-S5) — the PURE engine.
///
/// A-05 highest-risk surface: exhaustively unit-tested. Deterministic and
/// value-independent — the `WorkAllowance` (limit + half/full threshold) is
/// injected, never read from global state, so the day math is fully testable.
///
/// Classification of each logged day against `allowance.halfDayMaxHours`
/// (default 4.0h):
/// - `hours <= 0`         → ignored (contributes nothing).
/// - `0 < hours <= 4.0`   → **half day** (0.5 equivalents). 4.0h exactly is a
///   half day (boundary).
/// - `hours > 4.0`        → **full day** (1.0 equivalents).
///
/// `usedEquivalents = fullDays * 1.0 + halfDays * 0.5`;
/// `remainingEquivalents = max(0, maxFullDays - usedEquivalents)` — floored, so
/// overworking shows 0 remaining while `usedEquivalents` may exceed the limit.
enum WorkingHoursTracker {

    static func usage(
        days: [WorkDay],
        allowance: WorkAllowance = .current
    ) -> WorkAllowanceUsage {
        var fullDays = 0
        var halfDays = 0
        for day in days {
            // Guard: a day with no (or invalid) hours contributes nothing.
            guard day.hours > 0 else { continue }
            if day.hours > allowance.halfDayMaxHours {
                fullDays += 1
            } else {
                halfDays += 1
            }
        }

        let used = Double(fullDays) * 1.0 + Double(halfDays) * 0.5
        let remaining = max(0, Double(allowance.maxFullDays) - used)
        return WorkAllowanceUsage(
            fullDays: fullDays,
            halfDays: halfDays,
            usedEquivalents: used,
            remainingEquivalents: remaining)
    }
}
