import Foundation

/// Renewal tracker types (P6-R4) — surfaces Vault documents that are expiring or
/// already expired so a long-term resident can renew them in time.
///
/// `Renewal` is a flat, presentation-ready view of one expiring `DocumentRecord`;
/// the pure `RenewalTracker` engine builds the list. Day math is injected (no
/// `Date.now` in the engine) so it is deterministic and exhaustively testable.

/// How close a document is to (or past) its expiry.
enum RenewalStatus: Equatable {
    /// Expiry date is in the past (`daysUntil < 0`).
    case expired
    /// Expires within the "due soon" window (`0...dueSoonWindowDays`).
    case dueSoon
    /// Expires beyond the window (`> dueSoonWindowDays`).
    case upcoming
}

/// One upcoming/overdue document renewal, derived from a `DocumentRecord`.
struct Renewal: Identifiable, Equatable {
    /// Mirrors the source document's id (stable across recomputes).
    let id: UUID
    /// Document name (from `DocumentRecord.fileName`).
    let name: String
    /// Typed category for the icon/label.
    let category: DocumentCategory
    /// The document's expiry date.
    let expiresAt: Date
    /// Days until expiry; negative once expired.
    let daysUntil: Int
    /// Derived urgency band.
    let status: RenewalStatus

    /// Days within which an upcoming expiry counts as "due soon". ~2 months gives
    /// enough lead time to book an Ausländerbehörde appointment and gather
    /// papers. Versioned here (not hard-coded in views) so it can be tuned.
    static let dueSoonWindowDays = 60
}
