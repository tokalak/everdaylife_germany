import CryptoKit
import Foundation

/// Symmetric authenticated encryption for document blobs (A-09).
///
/// AES-GCM (256-bit) provides confidentiality *and* integrity: a tampered blob
/// fails to open rather than decrypting to garbage. The returned `Data` is the
/// GCM "combined" form (nonce ‖ ciphertext ‖ tag), self-contained for storage.
struct FileCryptor {
    func encrypt(_ plaintext: Data, using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw FileCryptorError.sealingFailed
        }
        return combined
    }

    func decrypt(_ ciphertext: Data, using key: SymmetricKey) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(box, using: key)
    }
}

enum FileCryptorError: Error {
    case sealingFailed
}
