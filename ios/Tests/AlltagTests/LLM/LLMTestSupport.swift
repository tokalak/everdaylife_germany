import CryptoKit
import Foundation
@testable import Alltag

enum LLMTestFactory {
    /// Lowercase-hex SHA-256, matching ``ModelVerifier``'s output.
    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// A spec whose size + checksum match `payload`, so verification passes.
    static func spec(matching payload: Data, id: String = "test-model") -> LLMModelSpec {
        LLMModelSpec(
            id: id,
            displayName: "Test Model",
            runtime: .llamaCpp,
            quant: .q4_K_XL,
            fileName: "\(id).gguf",
            sourceURL: URL(string: "https://example.test/\(id).gguf")!,
            expectedByteCount: Int64(payload.count),
            sha256: sha256Hex(payload),
            contextWindowCap: 4096)
    }

    /// An isolated, auto-creatable temp ``ModelStore`` for a test.
    static func temporaryStore() throws -> ModelStore {
        try ModelStore(
            directory: FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true))
    }

    /// A fully-stubbed LLM facade for DI tests (no network, temp storage).
    static func service() throws -> LLMService {
        let store = try temporaryStore()
        let provisioner = ModelProvisioner(store: store)
        return LLMService(
            catalog: .v1, store: store, provisioner: provisioner,
            engine: StubLLMEngine(), runtime: .current)
    }
}
