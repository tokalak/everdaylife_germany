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
/// The store is pure location + filesystem bookkeeping; it does not verify
/// (that's ``ModelVerifier``). Nothing downloads — the weights ship bundled in
/// the app (hard rule), so the store only locates the bundled/installed file.
///
/// A model can also ship **bundled inside the app** (the weights are copied into
/// `Alltag.app` at build time — see `project.yml`). When present, the store
/// treats that read-only copy as already installed, so device builds run fully
/// offline on first launch with no ~2 GB download. The writable store location
/// (Application Support) is unchanged; the bundle is only an extra *read* source
/// consulted as a fallback, and the download path still applies when no bundled
/// copy exists (Simulator/CI, or a quant the device picks that wasn't shipped).
struct ModelStore {
    let directory: URL

    /// Locates a spec's weights inside the app bundle, if they were shipped
    /// there. Injectable so tests can point at a temp file instead of
    /// `Bundle.main`. Returns `nil` when nothing is bundled for the spec.
    private let bundledModelURL: @Sendable (LLMModelSpec) -> URL?

    /// - Parameters:
    ///   - directory: where downloaded model files live. Defaults to
    ///     `Application Support/Alltag/Models` (created + backup-excluded on
    ///     init). Tests pass a temp URL.
    ///   - bundledModelURL: resolves a spec to its bundled copy. Defaults to a
    ///     `Bundle.main` lookup by filename.
    init(
        directory: URL? = nil,
        bundledModelURL: @escaping @Sendable (LLMModelSpec) -> URL? = ModelStore.mainBundleModelURL
    ) throws {
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
        self.bundledModelURL = bundledModelURL
        try FileManager.default.createDirectory(
            at: self.directory, withIntermediateDirectories: true)
        try excludeFromBackup(self.directory)
    }

    /// Default ``bundledModelURL``: look the spec's file up in the main app
    /// bundle (the build-time bundled-weights path).
    static func mainBundleModelURL(for spec: LLMModelSpec) -> URL? {
        let name = (spec.fileName as NSString).deletingPathExtension
        let ext = (spec.fileName as NSString).pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    /// Writable on-disk URL for a spec's downloaded file (the install
    /// destination, whether or not the file exists yet). Never the bundle —
    /// for the resolved *usable* location, see ``installedURL(for:)``.
    func url(for spec: LLMModelSpec) -> URL {
        directory.appendingPathComponent(spec.fileName, isDirectory: false)
    }

    /// The spec's bundled-in-app copy, but only if it's present and the right
    /// size (`nil` otherwise). Read-only — usable for loading, not writing.
    func bundledURL(for spec: LLMModelSpec) -> URL? {
        guard let url = bundledModelURL(spec),
              let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize,
              Int64(size) == spec.expectedByteCount
        else { return nil }
        return url
    }

    /// The usable location of a valid copy of the spec, or `nil` if neither a
    /// downloaded nor a bundled copy is present. Prefers the writable download
    /// over the bundled copy (a user redownload/update wins), falling back to
    /// the app bundle. This is the URL the engine should load.
    func installedURL(for spec: LLMModelSpec) -> URL? {
        if byteCount(for: spec) == spec.expectedByteCount { return url(for: spec) }
        return bundledURL(for: spec)
    }

    /// A valid copy exists (downloaded *or* bundled) and matches the expected
    /// size — a cheap "is it usable?" check. Full integrity (SHA-256) is
    /// ``ModelVerifier``'s job, run once at install time, not on every launch.
    func isInstalled(_ spec: LLMModelSpec) -> Bool {
        installedURL(for: spec) != nil
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
