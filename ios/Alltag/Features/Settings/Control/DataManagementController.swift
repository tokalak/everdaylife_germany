import Foundation

/// GDPR/DSGVO data controls behind Settings (P3-09, X-03): export everything the
/// app holds, and erase everything from the device.
///
/// Both operations go through the existing stores (`VaultStore`, `DeadlineStore`)
/// so encryption, reminder cancellation, and the agenda all stay consistent.
/// Injected, so delete + export are unit-testable.
@MainActor
struct DataManagementController {
    let vault: VaultStore
    let deadlines: DeadlineStore
    let checklist: ChecklistStore

    /// **Delete all my data** — erase every document (and its encrypted blob),
    /// every deadline (cancelling their reminders), and all checklist progress.
    /// Irreversible; the caller confirms first. Onboarding/persona/theme prefs
    /// are intentionally left.
    func deleteAllData() {
        vault.removeAll()
        deadlines.removeAll()
        checklist.removeAll()
    }

    /// **Export my data** — write a human-readable summary plus a copy of every
    /// stored document to temp files, returned as URLs to hand to a share sheet.
    /// Decrypted bytes live only in these temp files for the share (X-03).
    func exportItems(now: Date = .now) -> [URL] {
        var urls: [URL] = []
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AlltagExport-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true)

        let summary = DataExport.summary(
            documents: vault.documents, deadlines: deadlines.deadlines, now: now)
        let summaryURL = directory.appendingPathComponent("Alltag-summary.txt")
        if (try? summary.data(using: .utf8)?.write(to: summaryURL)) != nil {
            urls.append(summaryURL)
        }

        for document in vault.documents {
            guard let data = vault.data(for: document) else { continue }
            let url = directory
                .appendingPathComponent(DataExport.safeFileName(document.fileName))
                .appendingPathExtension("pdf")
            if (try? data.write(to: url)) != nil { urls.append(url) }
        }
        return urls
    }
}

/// Pure formatting for the data export (P3-09) — testable without the file system.
enum DataExport {
    /// A plain-text summary of the user's documents + deadlines.
    static func summary(
        documents: [DocumentRecord], deadlines: [Deadline], now: Date = .now
    ) -> String {
        let date = now.formatted(date: .abbreviated, time: .shortened)
        var lines = ["Alltag — data export", "Generated \(date)", ""]

        lines.append("Documents (\(documents.count)):")
        if documents.isEmpty { lines.append("  (none)") }
        for document in documents.sorted(by: { $0.createdAt < $1.createdAt }) {
            var line = "  • \(document.fileName) — \(document.category)"
            if let expiresAt = document.expiresAt {
                line += " (expires \(expiresAt.formatted(date: .abbreviated, time: .omitted)))"
            }
            lines.append(line)
        }
        lines.append("")

        lines.append("Dates (\(deadlines.count)):")
        if deadlines.isEmpty { lines.append("  (none)") }
        for deadline in deadlines.sorted(by: { $0.dueDate < $1.dueDate }) {
            let due = deadline.dueDate.formatted(date: .abbreviated, time: .omitted)
            let done = deadline.isDone ? " [done]" : ""
            lines.append("  • \(due) — \(deadline.title)\(done)")
        }
        return lines.joined(separator: "\n")
    }

    /// Strip path-hostile characters from a user-supplied document name.
    static func safeFileName(_ name: String) -> String {
        let cleaned = name.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "document" : cleaned
    }
}
