import CryptoKit
import Foundation
@testable import Alltag

/// A ``ModelDownloading`` that writes caller-supplied bytes to a temp file and
/// reports a couple of progress steps — lets the provisioner round-trip with no
/// network and no 3 GB file.
struct FakeModelDownloader: ModelDownloading {
    /// Bytes to "download". The test sets the spec's size/sha256 to match.
    let payload: Data
    /// When non-nil, the stream throws this instead of completing.
    let failure: LLMError?
    let temporaryDirectory: URL

    init(
        payload: Data,
        failure: LLMError? = nil,
        temporaryDirectory: URL = FileManager.default.temporaryDirectory
    ) {
        self.payload = payload
        self.failure = failure
        self.temporaryDirectory = temporaryDirectory
    }

    func download(_ spec: LLMModelSpec) -> AsyncThrowingStream<ModelDownloadEvent, Error> {
        AsyncThrowingStream { continuation in
            if let failure {
                continuation.finish(throwing: failure)
                return
            }
            let url = temporaryDirectory
                .appendingPathComponent("\(spec.id)-\(UUID().uuidString).part")
            do {
                try payload.write(to: url)
            } catch {
                continuation.finish(throwing: error)
                return
            }
            continuation.yield(.progress(0.5))
            continuation.yield(.progress(1.0))
            continuation.yield(.completed(url))
            continuation.finish()
        }
    }
}

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
            quant: .q4_K_M,
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
        let provisioner = ModelProvisioner(
            store: store, downloader: FakeModelDownloader(payload: Data()))
        return LLMService(
            catalog: .v1, store: store, provisioner: provisioner,
            engine: StubLLMEngine(), runtime: .current)
    }
}
