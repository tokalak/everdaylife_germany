import CryptoKit
import Foundation

enum ModelVerificationError: Error, Equatable {
    /// On-disk size differs from the spec's expected size.
    case sizeMismatch(expected: Int64, actual: Int64)
    /// SHA-256 of the file differs from the spec's pinned hash.
    case checksumMismatch(expected: String, actual: String)
    /// The file couldn't be read for hashing.
    case unreadable
}

/// Validates a downloaded model file against its ``LLMModelSpec`` (A-22).
///
/// Two gates, cheapest first:
/// 1. **Size** — always checked; catches truncated/partial downloads instantly.
/// 2. **SHA-256** — checked when the spec pins a hash; streamed in chunks so a
///    ~3 GB file never loads into memory at once.
///
/// A release must ship specs with a pinned `sha256` (enforced by the release
/// checklist / tests); during development a spec may omit it and rely on size.
struct ModelVerifier: Sendable {
    /// Bytes read per chunk while hashing (16 MB).
    private let chunkSize = 16 * 1_024 * 1_024

    func verify(fileAt url: URL, against spec: LLMModelSpec) throws {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize else {
            throw ModelVerificationError.unreadable
        }
        let actualSize = Int64(size)
        guard actualSize == spec.expectedByteCount else {
            throw ModelVerificationError.sizeMismatch(
                expected: spec.expectedByteCount, actual: actualSize)
        }

        guard let expectedHash = spec.sha256 else { return }
        let actualHash = try sha256Hex(of: url)
        guard actualHash == expectedHash.lowercased() else {
            throw ModelVerificationError.checksumMismatch(
                expected: expectedHash.lowercased(), actual: actualHash)
        }
    }

    /// Streams the file through SHA-256 in bounded chunks.
    func sha256Hex(of url: URL) throws -> String {
        let handle: FileHandle
        do {
            handle = try FileHandle(forReadingFrom: url)
        } catch {
            throw ModelVerificationError.unreadable
        }
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            let chunk: Data
            do {
                chunk = try handle.read(upToCount: chunkSize) ?? Data()
            } catch {
                throw ModelVerificationError.unreadable
            }
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
