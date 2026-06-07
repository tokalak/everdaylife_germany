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
/// readiness flow exercises with no network and no 3 GB file. The app never
/// downloads — readiness is "supported device + model file present?".
enum DecoderReadinessFactory {
    /// ~8 GB device — comfortably runs the `q4_K_XL` floor.
    static let capableDevice = DeviceCapability(physicalMemory: 8 * 1_024 * 1_024 * 1_024)
    /// ~1 GB device — below every deliverable quant's floor.
    static let incapableDevice = DeviceCapability(physicalMemory: 1 * 1_024 * 1_024 * 1_024)

    /// A catalog whose primary (and fallback) spec matches `payload`'s size, so
    /// writing `payload` into the store makes the model count as installed.
    static func catalog(matching payload: Data) -> LLMModelCatalog {
        let primary = spec(matching: payload, id: "test-primary", quant: .q4_K_XL)
        let fallback = spec(matching: payload, id: "test-fallback", quant: .q2_K_XL)
        // Default to the primary quant here so the capable device picks it (these
        // readiness tests install `primary`); the production catalog's q2_K_XL
        // default is covered by the catalog/gate suites.
        return LLMModelCatalog(
            primary: primary, lowMemoryFallback: fallback, candidateB: primary,
            defaultQuant: .q4_K_XL)
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

    /// A provisioner over a fresh temp store — no model present yet (so it
    /// resolves to `.missing` on a capable device).
    static func provisioner(matching payload: Data) throws -> ModelProvisioner {
        ModelProvisioner(
            catalog: catalog(matching: payload),
            store: try LLMTestFactory.temporaryStore())
    }

    /// A provisioner whose model is already installed in the store (the bundled-
    /// /installed happy path), by writing `payload` into the primary spec's slot.
    static func readyProvisioner(matching payload: Data) throws -> ModelProvisioner {
        let p = try provisioner(matching: payload)
        try payload.write(to: p.store.url(for: p.catalog.primary))
        return p
    }
}
