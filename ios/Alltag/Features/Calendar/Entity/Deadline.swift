import Foundation
import SwiftData

/// Where a deadline came from (P3-08). Drives whether it can be edited freely
/// (manual) and lets auto-populated entries be de-duplicated/refreshed by their
/// `sourceId` when a letter is re-decoded or a document's expiry changes.
enum DeadlineSource: String, Codable, Sendable, CaseIterable {
    case manual   // the user added it by hand
    case decoded  // extracted from a decoded letter (P3-08)
    case vault    // a document's expiry date (P3-06/08)
}

/// A date the user must not miss — a Behörden deadline, an appointment, or a
/// document expiry (A-07; P3-07/08).
///
/// Structured data, so it lives in **SwiftData** alongside the document index.
/// `Severity` and `DeadlineSource` are stored as their raw strings to keep the
/// persistence layer free of the DesignSystem/SwiftUI types; typed accessors sit
/// on top. The single most important date the Decoder extracts becomes one of
/// these (P3-08), as does each Vault document's expiry (P3-06).
@Model
final class Deadline {
    @Attribute(.unique) var id: UUID
    /// Short user-facing label, e.g. "Confirm address · Finanzamt".
    var title: String
    /// When it's due (day granularity is what matters; time is ignored in UI).
    var dueDate: Date
    /// `Severity.rawValue` — see `severity`.
    var severityRaw: String
    /// Optional longer context (the decoded summary, a manual note).
    var note: String?
    /// Marked done — kept (not deleted) so the user has a record.
    var isDone: Bool
    var createdAt: Date
    /// `DeadlineSource.rawValue` — see `source`.
    var sourceRaw: String
    /// Back-link to the originating decode/document (for de-dup/refresh, P3-08).
    var sourceId: String?

    init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date,
        severity: Severity = .action,
        note: String? = nil,
        isDone: Bool = false,
        createdAt: Date = .now,
        source: DeadlineSource = .manual,
        sourceId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.severityRaw = severity.rawValue
        self.note = note
        self.isDone = isDone
        self.createdAt = createdAt
        self.sourceRaw = source.rawValue
        self.sourceId = sourceId
    }
}

/// Typed accessors over the raw-string storage. Kept in an **extension** so the
/// `@Model` macro (which scans only the primary declaration) never tries to
/// persist these computed properties — it persists `severityRaw`/`sourceRaw`.
extension Deadline {
    /// Typed severity (falls back to `.action` if the stored string is unknown).
    var severity: Severity {
        get { Severity(rawValue: severityRaw) ?? .action }
        set { severityRaw = newValue.rawValue }
    }

    /// Typed source (falls back to `.manual`).
    var source: DeadlineSource {
        get { DeadlineSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}
