import CryptoKit
import XCTest
@testable import Alltag

/// A-09: blob encryption is a round-trip and authenticated.
final class FileCryptorTests: XCTestCase {
    private let cryptor = FileCryptor()
    private let key = SymmetricKey(size: .bits256)

    func testEncryptThenDecryptRecoversPlaintext() throws {
        let plaintext = Data("Behörden-Brief: Bitte zahlen Sie 90 €.".utf8)
        let ciphertext = try cryptor.encrypt(plaintext, using: key)
        XCTAssertNotEqual(ciphertext, plaintext, "ciphertext must not equal plaintext")
        let recovered = try cryptor.decrypt(ciphertext, using: key)
        XCTAssertEqual(recovered, plaintext)
    }

    func testDecryptWithWrongKeyFails() throws {
        let ciphertext = try cryptor.encrypt(Data("secret".utf8), using: key)
        let otherKey = SymmetricKey(size: .bits256)
        XCTAssertThrowsError(try cryptor.decrypt(ciphertext, using: otherKey))
    }

    func testTamperedCiphertextFailsAuthentication() throws {
        var ciphertext = try cryptor.encrypt(Data("secret".utf8), using: key)
        ciphertext[ciphertext.count - 1] ^= 0xFF // flip a tag bit
        XCTAssertThrowsError(try cryptor.decrypt(ciphertext, using: key))
    }

    func testEmptyDataRoundTrips() throws {
        let ciphertext = try cryptor.encrypt(Data(), using: key)
        XCTAssertEqual(try cryptor.decrypt(ciphertext, using: key), Data())
    }
}
