import XCTest
@testable import Alltag

/// A-23: model files live in their own dir, install/size/remove correctly, and
/// the directory is excluded from backup.
final class ModelStoreTests: XCTestCase {
    private var directory: URL!
    private var store: ModelStore!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = try ModelStore(directory: directory)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeSpec(byteCount: Int64) -> LLMModelSpec {
        LLMModelSpec(
            id: "m", displayName: "M", runtime: .llamaCpp, quant: .q4_K_XL,
            fileName: "m.gguf",
            sourceURL: URL(string: "https://example.test/m.gguf")!,
            expectedByteCount: byteCount, sha256: nil, contextWindowCap: 4096)
    }

    func testDirectoryIsExcludedFromBackup() throws {
        let values = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)
    }

    func testNotInstalledWhenAbsent() {
        XCTAssertFalse(store.isInstalled(makeSpec(byteCount: 10)))
        XCTAssertNil(store.byteCount(for: makeSpec(byteCount: 10)))
    }

    func testInstallMovesFileAndReportsInstalled() throws {
        let payload = Data(repeating: 0xAB, count: 1234)
        let spec = makeSpec(byteCount: Int64(payload.count))
        let temp = directory.appendingPathComponent("incoming.part")
        try payload.write(to: temp)

        let url = try store.install(from: temp, as: spec)
        XCTAssertEqual(url, store.url(for: spec))
        XCTAssertTrue(store.isInstalled(spec))
        XCTAssertEqual(store.byteCount(for: spec), Int64(payload.count))
        XCTAssertFalse(FileManager.default.fileExists(atPath: temp.path),
                       "source should have been moved, not copied")
    }

    func testInstalledFileIsExcludedFromBackup() throws {
        let payload = Data(repeating: 1, count: 64)
        let spec = makeSpec(byteCount: Int64(payload.count))
        let temp = directory.appendingPathComponent("incoming.part")
        try payload.write(to: temp)
        let url = try store.install(from: temp, as: spec)

        let values = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, true)
    }

    func testWrongSizeIsNotInstalled() throws {
        let payload = Data(repeating: 0, count: 100)
        let temp = directory.appendingPathComponent("incoming.part")
        try payload.write(to: temp)
        // Spec expects a different size than what we wrote.
        let spec = makeSpec(byteCount: 999)
        _ = try store.install(from: temp, as: spec)
        XCTAssertFalse(store.isInstalled(spec))
    }

    func testRemoveDeletesFileAndIsIdempotent() throws {
        let payload = Data(repeating: 2, count: 50)
        let spec = makeSpec(byteCount: Int64(payload.count))
        let temp = directory.appendingPathComponent("incoming.part")
        try payload.write(to: temp)
        _ = try store.install(from: temp, as: spec)

        try store.remove(spec)
        XCTAssertFalse(store.isInstalled(spec))
        XCTAssertNoThrow(try store.remove(spec))  // removing again is a no-op
    }

    func testBundledCopyCountsAsInstalled() throws {
        let payload = Data(repeating: 0xCD, count: 256)
        let bundled = directory.appendingPathComponent("bundled.gguf")
        try payload.write(to: bundled)
        let spec = makeSpec(byteCount: Int64(payload.count))
        // A store whose download dir is empty but with the weights "bundled".
        let store = try ModelStore(
            directory: directory.appendingPathComponent("store", isDirectory: true),
            bundledModelURL: { _ in bundled })

        XCTAssertTrue(store.isInstalled(spec))
        XCTAssertEqual(store.bundledURL(for: spec), bundled)
        XCTAssertEqual(store.installedURL(for: spec), bundled,
                       "with no download, the bundled copy is the usable URL")
    }

    func testBundledCopyIgnoredWhenSizeMismatches() throws {
        let bundled = directory.appendingPathComponent("bundled.gguf")
        try Data(repeating: 0, count: 10).write(to: bundled)
        let spec = makeSpec(byteCount: 999)  // expects a different size
        let store = try ModelStore(
            directory: directory.appendingPathComponent("store2", isDirectory: true),
            bundledModelURL: { _ in bundled })

        XCTAssertFalse(store.isInstalled(spec))
        XCTAssertNil(store.bundledURL(for: spec))
        XCTAssertNil(store.installedURL(for: spec))
    }

    func testDownloadedCopyPreferredOverBundled() throws {
        let payload = Data(repeating: 9, count: 128)
        let bundled = directory.appendingPathComponent("bundled.gguf")
        try payload.write(to: bundled)
        let spec = makeSpec(byteCount: Int64(payload.count))
        let store = try ModelStore(
            directory: directory.appendingPathComponent("store3", isDirectory: true),
            bundledModelURL: { _ in bundled })

        // A user download of the same spec lands in the writable store.
        let temp = directory.appendingPathComponent("incoming.part")
        try payload.write(to: temp)
        _ = try store.install(from: temp, as: spec)

        XCTAssertEqual(store.installedURL(for: spec), store.url(for: spec),
                       "a downloaded copy wins over the bundled one")
    }

    func testTotalBytesUsedSumsFiles() throws {
        let spec = makeSpec(byteCount: 300)
        let temp = directory.appendingPathComponent("incoming.part")
        try Data(repeating: 7, count: 300).write(to: temp)
        _ = try store.install(from: temp, as: spec)
        XCTAssertEqual(store.totalBytesUsed(), 300)
    }
}
