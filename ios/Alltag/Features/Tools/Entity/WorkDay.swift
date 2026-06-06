import Foundation

/// Student work-allowance tracker types (P6-S5).
///
/// Rule (a condition of the student residence permit): a non-EU international
/// student may work a limited amount per year — commonly expressed as **140 full
/// days or 280 half days per year**. A day of up to 4 hours counts as a **half
/// day** (0.5 of a full-day equivalent); more than 4 hours counts as a **full
/// day** (1.0). The tool logs work days and reports how much of the annual
/// allowance is used and what remains.
///
/// **Re-verification (OQ-1):** the rules were liberalised in 2024 (also ~20h/week
/// during the semester). For KISS this models the long-standing **140 full / 280
/// half** day-equivalent allowance and the 4-hour half/full threshold — both
/// isolated here as versioned constants and **must be re-verified annually**
/// against the current §16b AufenthG / Auswärtiges Amt guidance.

/// One logged work day. Identifiable with a stable id so the editable list of
/// days can add/update/delete rows.
struct WorkDay: Identifiable, Equatable {
    let id: UUID
    var date: Date
    /// Hours worked that day.
    var hours: Double

    init(id: UUID = UUID(), date: Date, hours: Double) {
        self.id = id
        self.date = date
        self.hours = hours
    }
}

/// The annual work allowance, expressed in full-day equivalents.
///
/// **Yearly-changing / rule data (OQ-1):** isolated here so a rule change is a
/// one-line edit and never hard-coded in the engine or the view.
struct WorkAllowance: Equatable {
    /// Maximum full-day equivalents per year (140 full days == 280 half days).
    let maxFullDays: Int
    /// A day of at most this many hours counts as a half day; more counts as a
    /// full day.
    let halfDayMaxHours: Double

    /// Shipping values — re-verify annually (OQ-1).
    static let current = WorkAllowance(maxFullDays: 140, halfDayMaxHours: 4.0)
}

/// The computed usage of the annual work allowance.
struct WorkAllowanceUsage: Equatable {
    /// Number of logged days counted as full days (> `halfDayMaxHours`).
    let fullDays: Int
    /// Number of logged days counted as half days (0 < hours <= `halfDayMaxHours`).
    let halfDays: Int
    /// Full-day equivalents used: `fullDays * 1.0 + halfDays * 0.5`.
    let usedEquivalents: Double
    /// Equivalents still available: `max(0, maxFullDays - usedEquivalents)` —
    /// never negative even when the student has overworked.
    let remainingEquivalents: Double
}
