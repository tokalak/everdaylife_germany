import Foundation
import Observation
import SwiftData

/// Owns the on-device document vault (P3-05/06): the encrypted blobs, their
/// SwiftData index, and expiry handling.
///
/// Bytes are written through ``EncryptedFileStore`` (AES-GCM, Documents,
/// complete file protection — D4/X-03), addressed by the record id. Documents
/// with an expiry get **two** things: a `.vault` ``Deadline`` so they surface in
/// the Dates agenda (P3-08), and expiry reminders at **60/30/7 days** (P3-06),
/// the longer lead time important papers (passport, permit) need. The Dates
/// reminders are deliberately suppressed for `.vault` deadlines so the user isn't
/// reminded twice.
///
/// All collaborators are injected, so the store unit-tests with an in-memory
/// context, a temp file store, an in-memory key, and a recording scheduler.
@MainActor
@Observable
final class VaultStore {
    /// Expiry reminder lead times, in days before the expiry date (P3-06).
    static let expiryOffsets = [60, 30, 7]
    /// Identifier namespace for expiry notifications (vs deadline reminders).
    static let expiryPrefix = "expiry"

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let fileStore: EncryptedFileStore
    @ObservationIgnored private let deadlines: DeadlineStore
    @ObservationIgnored private let scheduler: any ReminderScheduling

    private(set) var documents: [DocumentRecord] = []

    init(
        context: ModelContext,
        fileStore: EncryptedFileStore,
        deadlines: DeadlineStore,
        scheduler: any ReminderScheduling
    ) {
        self.context = context
        self.fileStore = fileStore
        self.deadlines = deadlines
        self.scheduler = scheduler
        reload()
    }

    var isEmpty: Bool { documents.isEmpty }

    /// Documents grouped by category (display order), newest first within a group.
    func grouped() -> [(category: DocumentCategory, documents: [DocumentRecord])] {
        DocumentCategory.allCases.compactMap { category in
            let items = documents
                .filter { $0.categoryValue == category }
                .sorted { $0.createdAt > $1.createdAt }
            return items.isEmpty ? nil : (category, items)
        }
    }

    func reload() {
        let all = (try? context.fetch(FetchDescriptor<DocumentRecord>())) ?? []
        documents = all.sorted { $0.createdAt > $1.createdAt }
    }

    /// Encrypt + store `data`, index it, and set up expiry handling. Throws if the
    /// blob can't be written (e.g. Keychain unavailable on an unsigned simulator).
    @discardableResult
    func add(
        data: Data,
        fileName: String,
        category: DocumentCategory = .other,
        expiresAt: Date? = nil
    ) throws -> DocumentRecord {
        let record = DocumentRecord(
            fileName: fileName, category: category.rawValue, expiresAt: expiresAt)
        try fileStore.save(data, id: record.id.uuidString)
        context.insert(record)
        persist()
        applyExpiry(for: record)
        return record
    }

    /// Decrypted bytes for a document (for preview / export / share), or nil.
    func data(for record: DocumentRecord) -> Data? {
        try? fileStore.load(id: record.id.uuidString)
    }

    func remove(_ record: DocumentRecord) {
        let id = record.id.uuidString
        try? fileStore.delete(id: id)
        cancelExpiryReminders(for: record)
        deadlines.removeBySource(.vault, sourceId: id)
        context.delete(record)
        persist()
    }

    /// Delete every document + blob (GDPR "delete all data", P3-09). The matching
    /// `.vault` deadlines are cleared by `DeadlineStore.removeAll()` in that flow.
    func removeAll() {
        for record in documents {
            try? fileStore.delete(id: record.id.uuidString)
            cancelExpiryReminders(for: record)
        }
        try? context.delete(model: DocumentRecord.self)
        persist()
    }

    /// Total bytes used by stored blobs (Settings storage explainer, P3-09).
    func totalBytesUsed() -> Int64 {
        documents.reduce(0) { $0 + (fileStore.byteCount(id: $1.id.uuidString) ?? 0) }
    }

    // MARK: - Internals

    private func persist() {
        try? context.save()
        reload()
    }

    /// On an expiry: surface it in the agenda (P3-08) and schedule 60/30/7
    /// reminders (P3-06). Re-applied on every change so edits stay in sync.
    private func applyExpiry(for record: DocumentRecord) {
        guard let expiresAt = record.expiresAt else { return }
        deadlines.upsert(
            source: .vault, sourceId: record.id.uuidString,
            title: String(format: String(localized: "vault_expiry_deadline"), record.fileName),
            dueDate: expiresAt, severity: .action)
        Task { await scheduler.schedule(expiryRequest(for: record, expiresAt: expiresAt)) }
    }

    private func cancelExpiryReminders(for record: DocumentRecord) {
        guard let expiresAt = record.expiresAt else { return }
        let request = expiryRequest(for: record, expiresAt: expiresAt)
        Task { await scheduler.cancel(request) }
    }

    private func expiryRequest(
        for record: DocumentRecord, expiresAt: Date
    ) -> ReminderRequest {
        ReminderRequest(
            id: record.id,
            title: String(localized: "reminder_expiry_title"),
            body: record.fileName,
            date: expiresAt,
            offsetsInDays: Self.expiryOffsets,
            idPrefix: Self.expiryPrefix)
    }
}
