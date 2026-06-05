import Foundation
import Observation

/// Why a decode couldn't complete, mapped to user-facing guidance (X-05/X-07).
///
/// Each case is a distinct *next action* for the user, not a raw error — "take a
/// clearer photo" vs "the AI couldn't read this" vs "the model isn't ready".
enum DecoderFailure: Equatable, Sendable {
    /// OCR found no usable text — the photo was too blurry/dark/empty.
    case couldNotReadImage
    /// The model ran but produced nothing usable even after a repair retry.
    case couldNotUnderstand
    /// The on-device engine isn't available (runtime not vendored / model gone).
    case engineUnavailable
    /// Anything else.
    case unknown

    /// Localization key for the headline shown on the error card.
    var messageKey: String {
        switch self {
        case .couldNotReadImage: "decoder_error_unreadable"
        case .couldNotUnderstand: "decoder_error_not_understood"
        case .engineUnavailable: "decoder_error_engine"
        case .unknown: "decoder_error_unknown"
        }
    }
}

/// The Decode flow's phase, once the model is ready (P3-03).
enum DecoderPhase: Equatable, Sendable {
    /// Waiting for the user to scan a letter.
    case idle
    /// OCR is extracting text from the captured pages (P3-01).
    case recognizing
    /// The on-device model is explaining the text (P3-02).
    case decoding
    /// Done — the validated result is ready to render (P3-03).
    case result(DecodedLetter)
    /// Something went wrong; carries the user-facing reason.
    case failed(DecoderFailure)
}

/// Orchestrates one capture → OCR → explain → result run (P3-03).
///
/// This is the Decode tab's interactor once ``DecoderReadinessController`` has the
/// model ready. It owns the phase the UI renders and sequences the two on-device
/// steps — Vision OCR (``TextRecognizing``) then the model (``DecodeLetterUseCase``)
/// — mapping every failure to an actionable ``DecoderFailure``. Both dependencies
/// are protocols, so the whole sequence unit-tests with stubs.
@MainActor
@Observable
final class DecoderController {
    @ObservationIgnored private let recognizer: any TextRecognizing
    @ObservationIgnored private let decode: DecodeLetterUseCase

    private(set) var phase: DecoderPhase = .idle

    init(recognizer: any TextRecognizing, decode: DecodeLetterUseCase) {
        self.recognizer = recognizer
        self.decode = decode
    }

    var isBusy: Bool { phase == .recognizing || phase == .decoding }

    /// Run the captured pages through OCR then the model, landing on `.result`
    /// or `.failed`. `outputLanguage` follows the app language (A-15).
    func decode(pages: [Data], outputLanguage: AppLanguage) async {
        guard !pages.isEmpty else {
            phase = .failed(.couldNotReadImage)
            return
        }
        phase = .recognizing
        let text: String
        do {
            text = try await recognizer.recognizeText(in: pages)
        } catch {
            phase = .failed(.couldNotReadImage)
            return
        }

        phase = .decoding
        do {
            let letter = try await decode(letterText: text, outputLanguage: outputLanguage)
            phase = .result(letter)
        } catch let error as LLMError where error == .runtimeUnavailable || error == .modelNotLoaded {
            phase = .failed(.engineUnavailable)
        } catch is DecoderError {
            phase = .failed(.couldNotUnderstand)
        } catch {
            phase = .failed(.unknown)
        }
    }

    /// Back to the start for another letter.
    func reset() {
        phase = .idle
    }
}
