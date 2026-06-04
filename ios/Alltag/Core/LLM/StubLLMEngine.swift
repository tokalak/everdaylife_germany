import Foundation

/// A deterministic, dependency-free ``LLMEngine`` for development and tests.
///
/// The real on-device runtime needs a vendored ~70 MB+ binary framework and a
/// ~3 GB model on a physical device — neither available in the Simulator or CI.
/// This stub lets the **downstream Decoder work (P3-02) proceed in parallel**
/// with the device-side runtime spike: it streams a scripted response chunk by
/// chunk, mimicking the real engine's contract.
///
/// It faithfully models the parts of the contract feature code relies on:
/// - **Streaming**: the canned response is emitted in word-sized chunks.
/// - **Cancellation**: dropping the stream cancels mid-emission.
/// - **Single-inference guard** (A-26): a second concurrent `generate` while one
///   is running fails with ``LLMError/busy``.
///
/// It is an `actor` so the busy flag is race-free; `generate` itself is
/// `nonisolated` because the protocol returns synchronously.
actor StubLLMEngine: LLMEngine {
    /// Produces the canned completion for a prompt. Default echoes a short,
    /// deterministic acknowledgement; tests inject their own.
    private let responder: @Sendable (LLMPrompt) -> String
    /// Optional pause between chunks (nanoseconds). 0 emits as fast as possible
    /// (the default for UI/use-case tests); tests of the concurrency guard and
    /// cancellation set a small value so a generation stays observably in flight.
    private let perChunkDelay: UInt64
    private var isGenerating = false

    init(
        perChunkDelay: UInt64 = 0,
        responder: @escaping @Sendable (LLMPrompt) -> String = StubLLMEngine.defaultResponder
    ) {
        self.perChunkDelay = perChunkDelay
        self.responder = responder
    }

    nonisolated func generate(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                await self.run(prompt, options: options, into: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions,
        into continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async {
        guard !isGenerating else {
            continuation.finish(throwing: LLMError.busy)
            return
        }
        isGenerating = true
        defer { isGenerating = false }

        let text = responder(prompt)
        // Split into word-sized chunks (keeping the trailing space) so callers
        // see realistic incremental output.
        let chunks = text.split(
            omittingEmptySubsequences: false, whereSeparator: { $0 == " " }
        ).map(String.init)

        for (index, word) in chunks.enumerated() {
            if Task.isCancelled {
                continuation.finish(throwing: LLMError.cancelled)
                return
            }
            let chunk = index == chunks.count - 1 ? word : word + " "
            continuation.yield(chunk)
            if perChunkDelay > 0 {
                do {
                    try await Task.sleep(nanoseconds: perChunkDelay)
                } catch {
                    continuation.finish(throwing: LLMError.cancelled)
                    return
                }
            }
        }
        continuation.finish()
    }

    /// Deterministic placeholder completion — not a real decode, just enough
    /// shape for UI/use-case development before the model is wired.
    static let defaultResponder: @Sendable (LLMPrompt) -> String = { _ in
        "Decoder stub response — on-device model not loaded in this build."
    }
}
