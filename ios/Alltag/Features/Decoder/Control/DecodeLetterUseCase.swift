import Foundation

/// Decodes one captured German letter into a validated ``DecodedLetter`` using
/// the on-device model (P3-02).
///
/// This is the feature's central interactor and the seam between the Decoder UI
/// and `Core/LLM`: it owns nothing concrete about the runtime (it depends only on
/// the ``LLMEngine`` protocol) so it runs identically against the development
/// ``StubLLMEngine`` and the real llama.cpp engine. The whole decode therefore
/// unit-tests with a scripted stub — no model, no device.
///
/// Flow: build the structured prompt (``DecoderPrompt``) in the user's output
/// language → run the engine (deterministic, grammar-constrained) → validate /
/// repair the JSON (``DecodedLetterParser``) → attach the verbatim OCR text. One
/// **repair retry** absorbs the occasional malformed first attempt small models
/// produce, before surfacing an error (A-27).
struct DecodeLetterUseCase: Sendable {
    let engine: any LLMEngine
    let parser: DecodedLetterParser

    init(engine: any LLMEngine, parser: DecodedLetterParser = DecodedLetterParser()) {
        self.engine = engine
        self.parser = parser
    }

    /// Decode `letterText` (OCR'd German) into a result in `outputLanguage`.
    ///
    /// - Throws: ``DecoderError`` if the model output can't be parsed after one
    ///   retry, or an ``LLMError`` if the engine itself fails (e.g.
    ///   `runtimeUnavailable` before the binary is vendored).
    func callAsFunction(
        letterText: String,
        outputLanguage: AppLanguage
    ) async throws -> DecodedLetter {
        let prompt = DecoderPrompt.prompt(
            letterText: letterText, outputLanguage: outputLanguage.englishName)
        let options = DecoderPrompt.generationOptions

        var lastError: Error = DecoderError.noJSONObject
        // First attempt + one repair retry. The grammar should make the first
        // attempt valid on llama.cpp; the retry covers non-grammar runtimes.
        for _ in 0..<2 {
            let raw = try await engine.complete(prompt, options: options)
            do {
                return try parser.parse(raw, originalText: letterText)
            } catch {
                lastError = error
            }
        }
        throw lastError
    }
}
