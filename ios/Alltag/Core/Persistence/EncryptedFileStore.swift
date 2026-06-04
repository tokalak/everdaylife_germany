import CryptoKit
import Foundation

/// On-device store for document blobs — scans, PDFs, photographed letters
/// (A-08/A-09, implements D4: "everything is local").
///
/// Guarantees, by construction:
/// - Blobs live under the **Documents** directory, never Caches/tmp, so they
///   survive app updates and are not reclaimable by the OS (A-08).
/// - Each blob is encrypted with AES-GCM using the device key (A-09) *before*
///   it touches disk — plaintext never lands in a file.
/// - Files are written with `FileProtectionType.complete`: unreadable while the
///   device is locked, a second layer under the at-rest encryption.
///
/// Blobs are addressed by a caller-supplied id (typically a `DocumentRecord.id`)
/// so the SwiftData metadata index and the encrypted bytes stay linked.
struct EncryptedFileStore {
    let directory: URL
    private let keyStore: KeyProviding
    private let cryptor = FileCryptor()

    /// - Parameters:
    ///   - directory: where encrypted blobs are written. Defaults to a `Documents/Vault`
    ///     subfolder (created on demand).
    ///   - keyStore: supplies the encryption key (Keychain in production).
    init(directory: URL? = nil, keyStore: KeyProviding) throws {
        self.keyStore = keyStore
        if let directory {
            self.directory = directory
        } else {
            let docs = try FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true)
            self.directory = docs.appendingPathComponent("Vault", isDirectory: true)
        }
        try FileManager.default.createDirectory(
            at: self.directory, withIntermediateDirectories: true)
    }

    /// Encrypts and writes `data`, returning the on-disk URL. Overwrites any
    /// existing blob with the same id.
    @discardableResult
    func save(_ data: Data, id: String) throws -> URL {
        let key = try keyStore.symmetricKey()
        let ciphertext = try cryptor.encrypt(data, using: key)
        let url = fileURL(for: id)
        try ciphertext.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    /// Reads and decrypts the blob for `id`. Throws if missing or tampered.
    func load(id: String) throws -> Data {
        let ciphertext = try Data(contentsOf: fileURL(for: id))
        let key = try keyStore.symmetricKey()
        return try cryptor.decrypt(ciphertext, using: key)
    }

    func exists(id: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: id).path)
    }

    func delete(id: String) throws {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func fileURL(for id: String) -> URL {
        // ".bin" — opaque ciphertext; the real type lives in the metadata index.
        directory.appendingPathComponent("\(id).bin", isDirectory: false)
    }
}
