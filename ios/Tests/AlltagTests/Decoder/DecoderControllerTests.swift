import XCTest
@testable import Alltag

/// Phase sequencing + failure mapping for ``DecoderController`` (P3-03), against
/// stubbed OCR + engine.
@MainActor
final class DecoderControllerTests: XCTestCase {
    private let validJSON = #"""
    {"summary": "The tax office wants you to confirm your address.",
     "severity": "urgent", "sender": "Finanzamt", "deadline": "2026-06-20",
     "asks": ["Confirm address"], "reply": "Sehr geehrte ...", "needsLawyer": false}
    """#

    private func controller(
        recognizer: any TextRecognizing,
        engine: any LLMEngine
    ) -> DecoderController {
        DecoderController(
            recognizer: recognizer,
            decode: DecodeLetterUseCase(engine: engine))
    }

    func testSuccessfulRunEndsInResult() async {
        let page = StubTextRecognizer.page("Sehr geehrte Damen und Herren ...")
        let recognizer = StubTextRecognizer(pages: [page.data: page.text])
        let c = controller(recognizer: recognizer, engine: ScriptedLLMEngine(responses: [validJSON]))

        await c.decode(pages: [page.data], outputLanguage: .en)

        guard case let .result(letter) = c.phase else {
            return XCTFail("expected .result, got \(c.phase)")
        }
        XCTAssertEqual(letter.severity, .urgent)
        XCTAssertEqual(letter.sender, "Finanzamt")
        // OCR text flows into the decode and is preserved on the result.
        XCTAssertEqual(letter.originalText, "Sehr geehrte Damen und Herren ...")
    }

    func testEmptyPagesFailFast() async {
        let c = controller(
            recognizer: StubTextRecognizer(), engine: ScriptedLLMEngine(responses: [validJSON]))
        await c.decode(pages: [], outputLanguage: .en)
        XCTAssertEqual(c.phase, .failed(.couldNotReadImage))
    }

    func testOCRFailureMapsToUnreadable() async {
        let recognizer = StubTextRecognizer(perPageError: .noTextFound)
        let c = controller(recognizer: recognizer, engine: ScriptedLLMEngine(responses: [validJSON]))
        await c.decode(pages: [Data("img".utf8)], outputLanguage: .en)
        XCTAssertEqual(c.phase, .failed(.couldNotReadImage))
    }

    func testModelGibberishMapsToNotUnderstood() async {
        let page = StubTextRecognizer.page("text")
        let recognizer = StubTextRecognizer(pages: [page.data: page.text])
        let c = controller(
            recognizer: recognizer, engine: ScriptedLLMEngine(responses: ["no json", "still none"]))
        await c.decode(pages: [page.data], outputLanguage: .en)
        XCTAssertEqual(c.phase, .failed(.couldNotUnderstand))
    }

    func testEngineUnavailableMapsToEngineFailure() async {
        let page = StubTextRecognizer.page("text")
        let recognizer = StubTextRecognizer(pages: [page.data: page.text])
        let c = DecoderController(
            recognizer: recognizer, decode: DecodeLetterUseCase(engine: UnavailableEngine()))
        await c.decode(pages: [page.data], outputLanguage: .en)
        XCTAssertEqual(c.phase, .failed(.engineUnavailable))
    }

    func testResetReturnsToIdle() async {
        let page = StubTextRecognizer.page("text")
        let recognizer = StubTextRecognizer(pages: [page.data: page.text])
        let c = controller(recognizer: recognizer, engine: ScriptedLLMEngine(responses: [validJSON]))
        await c.decode(pages: [page.data], outputLanguage: .en)
        c.reset()
        XCTAssertEqual(c.phase, .idle)
    }
}

/// Engine that always fails like ``LlamaCppEngine`` before vendoring.
private struct UnavailableEngine: LLMEngine {
    func generate(
        _ prompt: LLMPrompt,
        options: LLMGenerationOptions
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { $0.finish(throwing: LLMError.runtimeUnavailable) }
    }
}
