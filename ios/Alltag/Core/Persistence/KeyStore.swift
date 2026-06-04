import CryptoKit
import Foundation
import Security

/// Supplies the symmetric key used to encrypt document blobs at rest (A-09).
///
/// Abstracted behind a protocol so the file cryptor can be unit-tested with a
/// deterministic in-memory key, independent of the Keychain (which is awkward in
/// unhosted simulator test runs).
protocol KeyProviding: Sendable {
    /// Returns the device's document-encryption key, creating and persisting one
    /// on first access so it is stable across launches and app updates.
    func symmetricKey() throws -> SymmetricKey
}

enum KeyStoreError: Error, Equatable {
    /// The Keychain returned an unexpected OSStatus.
    case keychain(OSStatus)
    /// Stored key material had an unexpected size.
    case malformedKey
}

/// Keychain-backed `KeyProviding` (A-09).
///
/// Stores a 256-bit AES key as a generic-password item with
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — available after the
/// first unlock following boot, never migrated to another device, and excluded
/// from iCloud Keychain. This pairs with `FileProtectionType.complete` on the
/// encrypted blobs (see `EncryptedFileStore`).
struct KeychainKeyStore: KeyProviding {
    /// Service + account namespacing the item; overridable so tests use an
    /// isolated slot that can be cleaned up.
    let service: String
    let account: String

    init(service: String = "de.everydaygermany.app.documents",
         account: String = "document-encryption-key") {
        self.service = service
        self.account = account
    }

    func symmetricKey() throws -> SymmetricKey {
        if let existing = try loadKeyData() {
            guard existing.count == 32 else { throw KeyStoreError.malformedKey }
            return SymmetricKey(data: existing)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        try store(data)
        return key
    }

    /// Removes the stored key. Test-support / "delete all data" (GDPR) hook.
    func reset() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyStoreError.keychain(status)
        }
    }

    // MARK: - Keychain plumbing

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func loadKeyData() throws -> Data? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            return item as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeyStoreError.keychain(status)
        }
    }

    private func store(_ data: Data) throws {
        var attributes = baseQuery()
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] =
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeyStoreError.keychain(status) }
    }
}

/// Deterministic in-memory key store for tests. NOT for production use —
/// the key lives only for the lifetime of the instance.
final class InMemoryKeyStore: KeyProviding, @unchecked Sendable {
    private let key: SymmetricKey

    init(key: SymmetricKey = SymmetricKey(size: .bits256)) {
        self.key = key
    }

    func symmetricKey() throws -> SymmetricKey { key }
}
