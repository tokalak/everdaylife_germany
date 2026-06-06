import Foundation

/// Renewal tracker engine (P6-R4) — the PURE, deterministic logic.
///
/// Pulls the documents that carry an expiry date out of the Vault and ranks them
/// by how close they are to expiring. **No `Date.now` inside the engine** — the
/// reference date and calendar are injected so day math is fully deterministic
/// and the engine is exhaustively unit-testable (A-05). Reuses
/// `DocumentRecord.daysUntilExpiry` so the day-counting rule lives in one place.
enum RenewalTracker {

    /// Builds the renewal list for `documents` as of `referenceDate`.
    ///
    /// - Only documents with a non-nil `expiresAt` are included.
    /// - `daysUntil` comes from `daysUntilExpiry` (negative once expired).
    /// - Status: `< 0` → `.expired`; `0...dueSoonWindowDays` → `.dueSoon`;
    ///   `> dueSoonWindowDays` → `.upcoming`.
    /// - Sorted ascending by `expiresAt` (soonest / most-overdue first).
    static func upcoming(
        documents: [DocumentRecord],
        asOf referenceDate: Date,
        calendar: Calendar = .current,
        dueSoonWindowDays: Int = Renewal.dueSoonWindowDays
    ) -> [Renewal] {
        documents
            .compactMap { doc -> Renewal? in
                guard let expiresAt = doc.expiresAt,
                      let days = doc.daysUntilExpiry(from: referenceDate, calendar: calendar)
                else { return nil }
                return Renewal(
                    id: doc.id,
                    name: doc.fileName,
                    category: doc.categoryValue,
                    expiresAt: expiresAt,
                    daysUntil: days,
                    status: status(for: days, dueSoonWindowDays: dueSoonWindowDays))
            }
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    private static func status(for daysUntil: Int, dueSoonWindowDays: Int) -> RenewalStatus {
        if daysUntil < 0 { return .expired }
        if daysUntil <= dueSoonWindowDays { return .dueSoon }
        return .upcoming
    }
}
