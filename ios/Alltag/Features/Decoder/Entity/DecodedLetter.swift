import Foundation

/// The structured result of decoding one official German letter (P3-02/P3-03).
///
/// This is the Decoder's domain entity — the tight, validated shape the result
/// screen renders and the Vault/Calendar features consume. The on-device model
/// fills the *language-dependent* fields (summary, asks, reply template) and
/// classifies severity/deadline; the ``originalText`` is carried over verbatim
/// from OCR (never re-generated, so the "see the original German" panel is always
/// faithful — X-07).
///
/// Producing it goes through ``DecodedLetterParser`` (validate/repair, A-27) so a
/// drifting small model can never yield an invalid severity or an invented
/// deadline.
struct DecodedLetter: Sendable, Equatable, Codable {
    /// Plain-language explanation in the user's chosen output language.
    var summary: String
    /// Severity drives the pill, color, and (for `.legal`) the lawyer-routing
    /// disclaimer on the result screen.
    var severity: Severity
    /// The authority / sender, e.g. "Finanzamt Berlin-Mitte". May be empty if the
    /// letter doesn't name one clearly.
    var sender: String
    /// The single most important deadline, if the letter states one. **Never
    /// invented** — `nil` whenever the model didn't extract a concrete date.
    var deadline: Date?
    /// What the authority is asking the user to do, as discrete steps.
    var asks: [String]
    /// An optional suggested reply *in German* the user can copy/adapt. `nil` when
    /// no reply is warranted (e.g. pure information letters).
    var replyTemplate: String?
    /// Legally consequential — surface the "talk to a lawyer" routing and the RDG
    /// disclaimer prominently. Always `true` when `severity == .legal`.
    var needsLawyer: Bool
    /// The OCR'd German source text, preserved verbatim for the collapsible
    /// "original" panel. Set by the use-case from the capture step, not the model.
    var originalText: String

    init(
        summary: String,
        severity: Severity,
        sender: String = "",
        deadline: Date? = nil,
        asks: [String] = [],
        replyTemplate: String? = nil,
        needsLawyer: Bool = false,
        originalText: String = ""
    ) {
        self.summary = summary
        self.severity = severity
        self.sender = sender
        self.deadline = deadline
        self.asks = asks
        self.replyTemplate = replyTemplate
        // A legal classification always implies lawyer routing, regardless of the
        // model's separate flag — keep the two consistent at the entity boundary.
        self.needsLawyer = needsLawyer || severity == .legal
        self.originalText = originalText
    }

    /// True when the letter carries a concrete deadline worth adding to Dates.
    var hasDeadline: Bool { deadline != nil }
}
