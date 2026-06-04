import XCTest
@testable import Alltag

/// A-21/A-26: the stub engine streams, enforces the single-inference guard, and
/// honours cancellation — the contract downstream Decoder code depends on.
final class StubLLMEngineTests: XCTestCase {
    func testStreamsScriptedResponseInChunks() async throws {
        let engine = StubLLMEngine { _ in "one two three" }
        var chunks: [String] = []
        for try await chunk in engine.generate(LLMPrompt(user: "hi")) {
            chunks.append(chunk)
        }
        XCTAssertGreaterThan(chunks.count, 1, "output should arrive incrementally")
        XCTAssertEqual(chunks.joined(), "one two three")
    }

    func testCompleteAggregatesStream() async throws {
        let engine = StubLLMEngine { prompt in "echo: \(prompt.user)" }
        let result = try await engine.complete(LLMPrompt(user: "Behörde"))
        XCTAssertEqual(result, "echo: Behörde")
    }

    func testConcurrentGenerationHitsBusyGuard() async throws {
        // Deterministic, not timing-based: a per-chunk delay means that once the
        // first chunk arrives, the first generation provably holds the guard and
        // is suspended mid-stream — so a second generation started now must see
        // `.busy`, with no reliance on sleep timing.
        let engine = StubLLMEngine(perChunkDelay: 20_000_000) { _ in "a b c d e" }

        var first = engine.generate(LLMPrompt(user: "a")).makeAsyncIterator()
        _ = try await first.next()  // guard is now held

        let secondError = await captureError(engine.generate(LLMPrompt(user: "b")))
        XCTAssertEqual(secondError as? LLMError, .busy)

        while try await first.next() != nil {}  // drain the first generation
    }

    func testCancellationStopsGeneration() async throws {
        // Cancelling the consumer interrupts generation: far fewer than all the
        // chunks arrive, and the task returns promptly (no hang).
        let total = 1000
        let engine = StubLLMEngine(perChunkDelay: 10_000_000) { _ in
            Array(repeating: "x", count: total).joined(separator: " ")
        }
        let task = Task { () -> Int in
            var consumed = 0
            for try await _ in engine.generate(LLMPrompt(user: "c")) { consumed += 1 }
            return consumed
        }
        try await Task.sleep(nanoseconds: 30_000_000)  // ~3 chunks emitted
        task.cancel()
        let consumed = (try? await task.value) ?? 0
        XCTAssertLessThan(consumed, total, "cancellation must interrupt generation")
    }

    // MARK: - helpers

    private func drain(_ stream: AsyncThrowingStream<String, Error>) async throws {
        for try await _ in stream {}
    }

    private func captureError(_ stream: AsyncThrowingStream<String, Error>) async -> Error? {
        do {
            for try await _ in stream {}
            return nil
        } catch {
            return error
        }
    }
}
