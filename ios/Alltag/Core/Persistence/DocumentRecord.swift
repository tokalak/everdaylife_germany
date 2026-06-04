import Foundation
import SwiftData

/// Metadata index for a stored document (A-07).
///
/// This is the *searchable, structured* half of a Vault document; the encrypted
/// bytes live separately in `EncryptedFileStore`, linked by `id`. Keeping blobs
/// out of SwiftData keeps the store small and lets the OS apply file-level
/// protection to the heavy data.
///
/// Richer Vault modelling (categories enum, tags, source = scanned/imported)
/// arrives with the Vault feature in P3-05; this is the foundation slice.
@Model
final class DocumentRecord {
    /// Stable id; also the address of the encrypted blob in `EncryptedFileStore`.
    @Attribute(.unique) var id: UUID
    /// User-facing file name (e.g. "Anmeldung confirmation").
    var fileName: String
    /// Free-form category for now; becomes an enum in the Vault feature.
    var category: String
    var createdAt: Date
    /// Optional expiry for documents that lapse (passport, residence permit) —
    /// drives Vault expiry notifications (P3-06).
    var expiresAt: Date?

    init(
        id: UUID = UUID(),
        fileName: String,
        category: String = "uncategorized",
        createdAt: Date = .now,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.category = category
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
}
