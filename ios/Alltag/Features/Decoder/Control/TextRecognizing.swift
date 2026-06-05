import Foundation

enum TextRecognitionError: Error, Equatable {
    /// The image bytes couldn't be decoded into something recognizable.
    case invalidImage
    /// Recognition ran but found no usable text — surface "couldn't read this,
    /// try a clearer photo" rather than handing empty text to the model.
    case noTextFound
}

/// The Decoder's seam onto on-device OCR (P3-01).
///
/// Turning a letter photo into text is a **separate step from the LLM** (the
/// model explains already-extracted text; it does not read pixels — see the
/// P0-07 scope note). Keeping OCR behind a protocol mirrors ``LLMEngine``: the
/// capture/decode flow depends only on this, so the real Apple Vision
/// implementation (``VisionTextRecognizer``) and a deterministic test stub are
/// interchangeable, and the orchestration unit-tests with no camera.
protocol TextRecognizing: Sendable {
    /// Extract text from one page image (JPEG/PNG bytes). Multiple pages are
    /// recognized separately and joined by the caller.
    func recognizeText(in imageData: Data) async throws -> String
}

extension TextRecognizing {
    /// Recognize several captured pages and join them into one document, in order.
    /// Pages that yield no text are skipped; throws ``TextRecognitionError/noTextFound``
    /// only if *every* page is empty.
    func recognizeText(in pages: [Data]) async throws -> String {
        var parts: [String] = []
        for page in pages {
            let text = (try? await recognizeText(in: page)) ?? ""
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { parts.append(trimmed) }
        }
        guard !parts.isEmpty else { throw TextRecognitionError.noTextFound }
        return parts.joined(separator: "\n\n")
    }
}
