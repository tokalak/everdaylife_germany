import CryptoKit
import XCTest
@testable import Alltag

/// A-08/A-09: blobs are written to disk encrypted and round-trip via id.
final class EncryptedFileStoreTests: XCTestCase {
    private var directory: URL!
    private var store: EncryptedFileStore!
    private let keyStore = InMemoryKeyStore()

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = try EncryptedFileStore(directory: directory, keyStore: keyStore)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testSaveThenLoadRoundTrips() throws {
        let id = UUID().uuidString
        let blob = Data("scan bytes".utf8)
        try store.save(blob, id: id)
        XCTAssertTrue(store.exists(id: id))
        XCTAssertEqual(try store.load(id: id), blob)
    }

    func testBytesOnDiskAreEncrypted() throws {
        let id = UUID().uuidString
        let blob = Data("plaintext-marker".utf8)
        let url = try store.save(blob, id: id)
        let onDisk = try Data(contentsOf: url)
        XCTAssertNotEqual(onDisk, blob, "blob must be encrypted at rest")
        XCTAssertFalse(
            onDisk.range(of: blob) != nil, "plaintext must not appear on disk")
    }

    func testDeleteRemovesBlob() throws {
        let id = UUID().uuidString
        try store.save(Data("x".utf8), id: id)
        try store.delete(id: id)
        XCTAssertFalse(store.exists(id: id))
    }

    func testLoadMissingThrows() {
        XCTAssertThrowsError(try store.load(id: "does-not-exist"))
    }

    func testWrongKeyCannotDecryptAnotherStoresBlob() throws {
        let id = UUID().uuidString
        try store.save(Data("secret".utf8), id: id)

        // A second store over the same directory but a different key (simulating
        // a different device) must fail authentication.
        let foreign = try EncryptedFileStore(
            directory: directory, keyStore: InMemoryKeyStore())
        XCTAssertThrowsError(try foreign.load(id: id))
    }
}
