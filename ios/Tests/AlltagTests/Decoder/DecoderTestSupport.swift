import Foundation
@testable import Alltag

/// An ``LLMEngine`` that returns successive scripted completions, so use-case
/// tests can exercise the repair-retry path (first malformed → second valid).
///
/// It also records the prompts it received, letting tests assert the Decoder
/// asked for the right output language. An `actor` so the call index + capture
/// are race-free under the streaming contract.
actor ScriptedLLMEngine: LLMEngine {
    private let responses: [String]
    private(set) var receivedPrompts: [LLMPrompt] = []
    private var index = 0

    /// - Parameter responses: one entry per expected `generate` call. After the
    ///   last, it repeats the final response.
    init(responses: [String]) {
        self.responses = responses
    }

    func promptsSoFar() -> [LLMPrompt] { receivedPrompts }

    nonisolated func generate(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let text = await self.next(for: prompt)
                continuation.yield(text)
                continuation.finish()
            }
        }
    }

    private func next(for prompt: LLMPrompt) -> String {
        receivedPrompts.append(prompt)
        defer { index += 1 }
        return responses[min(index, responses.count - 1)]
    }
}

/// A deterministic ``TextRecognizing`` keyed by the page bytes, so capture/decode
/// orchestration tests run with no camera and no Vision. The map's key is the
/// page's `Data`; an absent key throws ``TextRecognitionError/noTextFound``.
struct StubTextRecognizer: TextRecognizing {
    /// Page bytes → recognized text. Use ``page(_:)`` to build entries.
    var pages: [Data: String]
    var perPageError: TextRecognitionError?

    init(pages: [Data: String] = [:], perPageError: TextRecognitionError? = nil) {
        self.pages = pages
        self.perPageError = perPageError
    }

    /// Convenience: a synthetic page whose bytes encode `text`, mapped to `text`.
    static func page(_ text: String) -> (data: Data, text: String) {
        (Data(text.utf8), text)
    }

    func recognizeText(in imageData: Data) async throws -> String {
        if let perPageError { throw perPageError }
        guard let text = pages[imageData] else { throw TextRecognitionError.noTextFound }
        return text
    }
}

/// Builds provisioners/capabilities sized to small fake payloads, so the
/// readiness flow round-trips with no network and no 3 GB file.
enum DecoderReadinessFactory {
    /// ~8 GB device — comfortably runs the `q4_K_M` floor.
    static let capableDevice = DeviceCapability(physicalMemory: 8 * 1_024 * 1_024 * 1_024)
    /// ~1 GB device — below every deliverable quant's floor.
    static let incapableDevice = DeviceCapability(physicalMemory: 1 * 1_024 * 1_024 * 1_024)

    /// A catalog whose primary (and fallback) spec verifies against `payload`,
    /// so a `FakeModelDownloader(payload:)` produces an installable model.
    static func catalog(matching payload: Data) -> LLMModelCatalog {
        let primary = spec(matching: payload, id: "test-primary", quant: .q4_K_M)
        let fallback = spec(matching: payload, id: "test-fallback", quant: .q3_K_M)
        return LLMModelCatalog(
            primary: primary, lowMemoryFallback: fallback, candidateB: primary)
    }

    private static func spec(
        matching payload: Data, id: String, quant: ModelQuant
    ) -> LLMModelSpec {
        LLMModelSpec(
            id: id,
            displayName: id,
            runtime: .llamaCpp,
            quant: quant,
            fileName: "\(id).gguf",
            sourceURL: URL(string: "https://example.test/\(id).gguf")!,
            expectedByteCount: Int64(payload.count),
            sha256: LLMTestFactory.sha256Hex(payload),
            contextWindowCap: 4096)
    }

    /// A provisioner with a temp store + fake downloader serving `payload`.
    static func provisioner(matching payload: Data) throws -> ModelProvisioner {
        let cat = catalog(matching: payload)
        return ModelProvisioner(
            catalog: cat,
            store: try LLMTestFactory.temporaryStore(),
            downloader: FakeModelDownloader(payload: payload))
    }

    /// A provisioner whose downloader always fails (for the failure branch).
    static func failingProvisioner() throws -> ModelProvisioner {
        let payload = Data("x".utf8)
        return ModelProvisioner(
            catalog: catalog(matching: payload),
            store: try LLMTestFactory.temporaryStore(),
            downloader: FakeModelDownloader(payload: payload, failure: .modelNotLoaded))
    }

    /// An isolated UserDefaults suite so the consent flag doesn't leak between tests.
    static func defaults() -> UserDefaults {
        UserDefaults(suiteName: "decoder-readiness-\(UUID().uuidString)")!
    }
}
