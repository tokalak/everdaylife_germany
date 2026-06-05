import Foundation
import SwiftData

/// Owns the SwiftData stack (A-07).
///
/// The store is placed in **Application Support** (not Documents, not Caches):
/// it is app-private structured data that must persist across app updates and
/// is never user-facing as files. The heavy, user-owned document bytes live
/// elsewhere, encrypted (`EncryptedFileStore`).
///
/// `@MainActor` because the app's `mainContext` is main-actor bound; background
/// work uses a `ModelContext` created off a `ModelContainer` (Sendable).
@MainActor
final class PersistenceController {
    let container: ModelContainer

    /// The set of `@Model` types in the store. New entities (Deadline, Persona,
    /// ChecklistProgress, …) are appended here as their features land.
    static let schema = Schema([
        DocumentRecord.self,
        Deadline.self,
        ChecklistProgress.self,
    ])

    /// - Parameters:
    ///   - storeURL: on-disk location of the store. Defaults to
    ///     `Application Support/Alltag/Alltag.store`. Tests pass a temp URL.
    ///   - inMemory: when true, an ephemeral store (no disk) — for fast tests.
    init(storeURL: URL? = nil, inMemory: Bool = false) throws {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(
                schema: Self.schema, isStoredInMemoryOnly: true)
        } else {
            let url = try storeURL ?? Self.defaultStoreURL()
            configuration = ModelConfiguration(schema: Self.schema, url: url)
        }
        container = try ModelContainer(
            for: Self.schema, configurations: [configuration])
    }

    /// `Application Support/Alltag/Alltag.store`, creating the directory if needed.
    static func defaultStoreURL() throws -> URL {
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        let dir = appSupport.appendingPathComponent("Alltag", isDirectory: true)
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("Alltag.store", isDirectory: false)
    }
}
