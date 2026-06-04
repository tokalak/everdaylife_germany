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
            id: "m", displayName: "M", runtime: .llamaCpp, quant: .q4_K_M,
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

    func testTotalBytesUsedSumsFiles() throws {
        let spec = makeSpec(byteCount: 300)
        let temp = directory.appendingPathComponent("incoming.part")
        try Data(repeating: 7, count: 300).write(to: temp)
        _ = try store.install(from: temp, as: spec)
        XCTAssertEqual(store.totalBytesUsed(), 300)
    }
}
