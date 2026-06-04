import Foundation

enum ModelStoreError: Error, Equatable {
    /// A file expected on disk was missing when reading its size.
    case fileMissing
}

/// Owns the on-disk location of downloaded model files (A-23).
///
/// Mirrors the persistence conventions of `Core/Persistence`: the store lives in
/// **Application Support** (app-private, survives updates), under a `Models`
/// subfolder. The folder is **excluded from iCloud/iTunes backup** — the weights
/// are large and re-downloadable, so backing them up would waste the user's
/// iCloud quota (A-23). Files are written with complete file protection, matching
/// the document store.
///
/// The store is pure location + filesystem bookkeeping; it does not download or
/// verify (those are ``ModelDownloading`` / ``ModelVerifier``).
struct ModelStore {
    let directory: URL

    /// - Parameter directory: where model files live. Defaults to
    ///   `Application Support/Alltag/Models` (created + backup-excluded on init).
    ///   Tests pass a temp URL.
    init(directory: URL? = nil) throws {
        if let directory {
            self.directory = directory
        } else {
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true)
            self.directory = appSupport
                .appendingPathComponent("Alltag", isDirectory: true)
                .appendingPathComponent("Models", isDirectory: true)
        }
        try FileManager.default.createDirectory(
            at: self.directory, withIntermediateDirectories: true)
        try excludeFromBackup(self.directory)
    }

    /// On-disk URL for a spec's model file (whether or not it exists yet).
    func url(for spec: LLMModelSpec) -> URL {
        directory.appendingPathComponent(spec.fileName, isDirectory: false)
    }

    /// The file exists *and* matches the expected size — a cheap "is it usable?"
    /// check. Full integrity (SHA-256) is ``ModelVerifier``'s job, run once at
    /// install time, not on every launch.
    func isInstalled(_ spec: LLMModelSpec) -> Bool {
        byteCount(for: spec) == spec.expectedByteCount
    }

    /// Size on disk of a spec's file, or nil if absent.
    func byteCount(for spec: LLMModelSpec) -> Int64? {
        let url = url(for: spec)
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize else { return nil }
        return Int64(size)
    }

    /// Moves a freshly downloaded file into place, replacing any prior copy, and
    /// (re)applies backup-exclusion + file protection to it. Returns the final
    /// URL.
    @discardableResult
    func install(from temporaryURL: URL, as spec: LLMModelSpec) throws -> URL {
        let destination = url(for: spec)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: destination.path)
        try excludeFromBackup(destination)
        return destination
    }

    /// Deletes a spec's model file (Settings "delete model" / redownload, A-23).
    func remove(_ spec: LLMModelSpec) throws {
        let url = url(for: spec)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    /// Total bytes used by all files in the model directory (Settings "storage
    /// used", A-23).
    func totalBytesUsed() -> Int64 {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return contents.reduce(0) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return sum + Int64(size)
        }
    }

    private func excludeFromBackup(_ url: URL) throws {
        var url = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }
}
