import Foundation

/// The production ``LLMEngine`` for Candidate A — Gemma 4 E2B GGUF on
/// `llama.cpp` with the Metal backend (``RuntimeDecision/current``).
///
/// **Integration seam, not yet active.** Wiring the real runtime requires a step
/// that cannot be done in this environment or in CI: vendoring the `llama.cpp`
/// **xcframework / SwiftPM binary target** with the Metal backend (A-21) and
/// loading a ~3 GB model on a *physical* device. Until that binary is added to
/// the project, this engine reports ``LLMError/runtimeUnavailable`` so the app
/// composes cleanly and falls back to ``StubLLMEngine`` for development, while
/// `Core/LLM`'s download/management/capability machinery (A-22…A-26) is fully
/// exercised by tests.
///
/// When the binary lands, this is the only file that changes: load the model
/// from the provisioned ``LLMModelSpec`` URL, cap the context at
/// `spec.contextWindowCap` (A-26), translate ``LLMGenerationOptions/grammar``
/// into a llama.cpp **GBNF** sampler for guaranteed-valid JSON (A-27), and pump
/// decoded tokens into the stream. Nothing above the ``LLMEngine`` protocol is
/// affected — that is the point of the seam.
struct LlamaCppEngine: LLMEngine {
    /// The provisioned, on-disk model this engine would load. Captured now so
    /// the wiring point is explicit even while the runtime is inert.
    let modelURL: URL
    let contextWindowCap: Int

    init(modelURL: URL, contextWindowCap: Int) {
        self.modelURL = modelURL
        self.contextWindowCap = contextWindowCap
    }

    func generate(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            // TODO(P0-07 device step): replace with a real llama.cpp/Metal decode
            // once the xcframework is vendored. See the type doc for the plan.
            continuation.finish(throwing: LLMError.runtimeUnavailable)
        }
    }
}
