import Foundation
import Vision
import UIKit

/// On-device OCR via Apple's Vision framework (P3-01).
///
/// Lives in Boundary because it's an external-service client (the Vision engine),
/// the BCE home for framework edges. It runs **entirely on-device** — no text
/// leaves the phone (X-03) — and is tuned for dense printed Behörden letters:
/// accurate recognition with German + English language models and language
/// correction on.
///
/// Its accuracy isn't unit-tested here (that needs real letter images — the job
/// of the A-28 eval harness); the seam ``TextRecognizing`` is what the
/// orchestration tests against.
struct VisionTextRecognizer: TextRecognizing {
    /// Recognition languages, best-effort by priority. German first (the source),
    /// English second (many letters mix in English, and it aids correction).
    var languages: [String] = ["de-DE", "en-US"]

    func recognizeText(in imageData: Data) async throws -> String {
        let languages = self.languages
        // Everything Vision touches (the non-Sendable request/handler/CGImage) is
        // created and consumed inside the work closure; only Sendable values
        // (`imageData`, `languages`, the continuation) cross into it.
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = UIImage(data: imageData)?.cgImage else {
                    continuation.resume(throwing: TextRecognitionError.invalidImage)
                    return
                }
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = languages

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                    let observations = request.results ?? []
                    // Top candidate per line, joined top-to-bottom (Vision returns
                    // observations roughly in reading order for printed text).
                    let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                    let text = lines.joined(separator: "\n")
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        continuation.resume(throwing: TextRecognitionError.noTextFound)
                    } else {
                        continuation.resume(returning: text)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
