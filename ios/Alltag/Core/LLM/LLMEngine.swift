import Foundation

/// A prompt for the on-device model, in Gemma chat terms (A-27).
///
/// `images` carries letter photos for the multimodal path (requires the `mmproj`
/// projector — OQ-12); for the OCR-first default it stays empty and the text is
/// folded into `user`.
struct LLMPrompt: Sendable, Equatable {
    /// System / task instruction (e.g. the Decoder's structured-output template).
    var system: String
    /// The user content — typically the OCR'd German letter text.
    var user: String
    /// Optional image bytes for vision input (empty for OCR-first).
    var images: [Data]

    init(system: String = "", user: String, images: [Data] = []) {
        self.system = system
        self.user = user
        self.images = images
    }
}

/// Decoding parameters for a single generation.
struct LLMGenerationOptions: Sendable, Equatable {
    /// Hard cap on generated tokens (bounds latency + KV growth, A-26).
    var maxTokens: Int
    /// 0 = deterministic. The Decoder wants near-deterministic structured output.
    var temperature: Double
    /// Optional **GBNF grammar** constraining output to valid JSON (A-27). On
    /// `llama.cpp` this *guarantees* a parseable shape; runtimes without grammar
    /// support fall back to validate/repair/retry.
    var grammar: String?

    init(maxTokens: Int = 512, temperature: Double = 0.0, grammar: String? = nil) {
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.grammar = grammar
    }

    /// Sensible default for short, factual Decoder output.
    static let `default` = LLMGenerationOptions()

    /// Structured-output preset: deterministic, grammar-constrained.
    static func structured(grammar: String) -> LLMGenerationOptions {
        LLMGenerationOptions(maxTokens: 768, temperature: 0.0, grammar: grammar)
    }
}

enum LLMError: Error, Equatable {
    /// The chosen runtime (e.g. the vendored llama.cpp xcframework) isn't wired
    /// into this build yet — callers should fall back or surface readiness UI.
    case runtimeUnavailable
    /// No model file is loaded (download/provision not complete).
    case modelNotLoaded
    /// Another generation is already in flight (single-inference guard, A-26).
    case busy
    /// Generation was cancelled by the caller.
    case cancelled
}

/// The Decoder's one seam onto on-device inference (A-21).
///
/// Feature code depends only on this protocol, never on a concrete runtime, so
/// the P0-07 runtime decision (``RuntimeDecision`` / OQ-14) stays swappable:
/// today a deterministic ``StubLLMEngine`` for development and tests, later the
/// real ``LlamaCppEngine`` (or a LiteRT-LM engine if the benchmark flips it),
/// with no change to the Decoder use-cases above.
///
/// `generate` streams text incrementally (token-ish chunks) so the UI can render
/// progressively and the "first-token" latency budget (OQ-13) is observable.
/// Cancellation flows through the stream's task: dropping the iterator cancels
/// the generation.
protocol LLMEngine: Sendable {
    func generate(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions
    ) -> AsyncThrowingStream<String, Error>
}

extension LLMEngine {
    /// Convenience: generate with default options.
    func generate(_ prompt: LLMPrompt) -> AsyncThrowingStream<String, Error> {
        generate(prompt, options: .default)
    }

    /// Convenience: collect the full completion into one string. Throws if the
    /// stream errors (e.g. ``LLMError/runtimeUnavailable``).
    func complete(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions = .default
    ) async throws -> String {
        var output = ""
        for try await chunk in generate(prompt, options: options) {
            output += chunk
        }
        return output
    }
}
