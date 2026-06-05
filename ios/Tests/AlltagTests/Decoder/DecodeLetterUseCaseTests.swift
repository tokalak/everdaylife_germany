import XCTest
@testable import Alltag

/// Behaviour of ``DecodeLetterUseCase`` (P3-02): prompt construction, the
/// repair retry, and error surfacing — all against scripted engines, no device.
final class DecodeLetterUseCaseTests: XCTestCase {
    private let validJSON = #"""
    {"summary": "The tax office wants you to confirm your address.",
     "severity": "action", "sender": "Finanzamt", "deadline": "2026-06-20",
     "asks": ["Confirm address"], "reply": "Sehr geehrte ...", "needsLawyer": false}
    """#

    func testDecodesValidResponse() async throws {
        let engine = ScriptedLLMEngine(responses: [validJSON])
        let useCase = DecodeLetterUseCase(engine: engine)

        let letter = try await useCase(
            letterText: "Sehr geehrte Damen und Herren ...", outputLanguage: .en)

        XCTAssertEqual(letter.severity, .action)
        XCTAssertEqual(letter.sender, "Finanzamt")
        XCTAssertEqual(letter.asks, ["Confirm address"])
        // The verbatim OCR text is carried through, not regenerated.
        XCTAssertEqual(letter.originalText, "Sehr geehrte Damen und Herren ...")
    }

    func testPromptRequestsChosenOutputLanguage() async throws {
        let engine = ScriptedLLMEngine(responses: [validJSON])
        let useCase = DecodeLetterUseCase(engine: engine)

        _ = try await useCase(letterText: "…", outputLanguage: .tr)

        let prompts = await engine.promptsSoFar()
        XCTAssertEqual(prompts.count, 1)
        XCTAssertTrue(
            prompts[0].system.contains("Turkish"),
            "system prompt should name the output language; got: \(prompts[0].system)")
        XCTAssertEqual(prompts[0].user, "…")
    }

    func testRetriesOnceAfterMalformedFirstAttempt() async throws {
        // First attempt has no JSON, second is valid → use-case recovers.
        let engine = ScriptedLLMEngine(responses: ["sorry, I cannot", validJSON])
        let useCase = DecodeLetterUseCase(engine: engine)

        let letter = try await useCase(letterText: "…", outputLanguage: .en)

        XCTAssertEqual(letter.severity, .action)
        let calls = await engine.promptsSoFar().count
        XCTAssertEqual(calls, 2, "should have retried exactly once")
    }

    func testThrowsAfterRepeatedMalformedOutput() async {
        let engine = ScriptedLLMEngine(responses: ["nope", "still nope"])
        let useCase = DecodeLetterUseCase(engine: engine)

        do {
            _ = try await useCase(letterText: "…", outputLanguage: .en)
            XCTFail("expected a DecoderError")
        } catch let error as DecoderError {
            XCTAssertEqual(error, .noJSONObject)
        } catch {
            XCTFail("expected DecoderError, got \(error)")
        }
    }

    func testPropagatesEngineFailure() async {
        // The pre-vendoring engine reports runtimeUnavailable — it must surface,
        // not get swallowed by the repair loop.
        let useCase = DecodeLetterUseCase(engine: UnavailableEngine())
        do {
            _ = try await useCase(letterText: "…", outputLanguage: .en)
            XCTFail("expected LLMError.runtimeUnavailable")
        } catch let error as LLMError {
            XCTAssertEqual(error, .runtimeUnavailable)
        } catch {
            XCTFail("expected LLMError, got \(error)")
        }
    }
}

/// An engine that always fails the way ``LlamaCppEngine`` does before its
/// xcframework is vendored.
private struct UnavailableEngine: LLMEngine {
    func generate(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish(throwing: LLMError.runtimeUnavailable) }
    }
}
