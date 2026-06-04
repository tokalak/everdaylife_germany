import CryptoKit
import XCTest
@testable import Alltag

/// A-09: the Keychain key store yields a stable key across instances.
///
/// Keychain access can be unavailable in an unhosted/unsigned simulator test run
/// (`errSecMissingEntitlement`, -34018). Those cases `XCTSkip` rather than fail —
/// the behaviour is still verified on a hosted run/device, and `FileCryptor` /
/// `EncryptedFileStore` are covered independently via the in-memory key store.
final class KeychainKeyStoreTests: XCTestCase {
    private var sut: KeychainKeyStore!

    override func setUp() {
        super.setUp()
        // Unique slot per run so tests never collide with real app keys.
        sut = KeychainKeyStore(
            service: "de.everydaygermany.app.tests.\(UUID().uuidString)",
            account: "key")
    }

    override func tearDown() {
        try? sut.reset()
        super.tearDown()
    }

    func testKeyIsStableAcrossCalls() throws {
        let key1: SymmetricKey
        do {
            key1 = try sut.symmetricKey()
        } catch KeyStoreError.keychain(let status) {
            throw XCTSkip("Keychain unavailable in this environment (OSStatus \(status))")
        }
        let key2 = try sut.symmetricKey()
        XCTAssertEqual(
            key1.withUnsafeBytes { Data($0) },
            key2.withUnsafeBytes { Data($0) },
            "the same key must be returned on subsequent calls")
    }

    func testResetCausesNewKey() throws {
        let key1: SymmetricKey
        do {
            key1 = try sut.symmetricKey()
        } catch KeyStoreError.keychain(let status) {
            throw XCTSkip("Keychain unavailable in this environment (OSStatus \(status))")
        }
        try sut.reset()
        let key2 = try sut.symmetricKey()
        XCTAssertNotEqual(
            key1.withUnsafeBytes { Data($0) },
            key2.withUnsafeBytes { Data($0) })
    }
}
