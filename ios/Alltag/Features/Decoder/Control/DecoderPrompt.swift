import Foundation

/// Builds the Decoder's system prompt + structured-output constraints (A-27).
///
/// Kept separate from the use-case so the *wording* — the highest-leverage,
/// most-iterated artifact for decode quality — and the JSON contract live in one
/// reviewable place, versioned content (X-06) rather than buried in control flow.
///
/// Two safety properties are baked in here, not left to the model:
/// - **RDG framing** (D9/X-04): the prompt forbids advice and tells the model to
///   classify clearly-legal matters as `legal` so the UI routes to a lawyer.
/// - **No invented deadlines** (X-07): the prompt instructs `null` when no
///   explicit date is present; the parser enforces it as a backstop.
enum DecoderPrompt {
    /// The JSON object the model must emit. Field order/notes double as the spec
    /// the ``DecodedLetterParser`` reads back.
    static func system(outputLanguage: String) -> String {
        """
        You are a careful assistant that explains official German letters \
        (Behörden-Briefe) to people who don't speak German well. You translate \
        and summarize — you do NOT give legal or tax advice.

        Read the letter text and reply with ONE JSON object, nothing else, with \
        exactly these fields:
        - "summary": a short plain-language explanation in \(outputLanguage) of \
        what this letter is and what it means for the reader (2–4 sentences).
        - "severity": one of "info", "action", "urgent", "legal".
          • "info" = informational, nothing to do.
          • "action" = the reader must do something, no hard time pressure.
          • "urgent" = time-critical, a deadline is near or money/penalty is at risk.
          • "legal" = a legal proceeding, court, fine, deportation or similar \
        serious legal matter.
        - "sender": the authority or sender name, or "" if unclear.
        - "deadline": the single most important deadline as "YYYY-MM-DD", or null \
        if the letter states no explicit date. NEVER guess a date.
        - "asks": an array of short steps (in \(outputLanguage)) the reader is \
        being asked to do; [] if none.
        - "reply": a short suggested reply IN GERMAN the reader could send, or \
        null if no reply is needed.
        - "needsLawyer": true if this is a legal matter a lawyer should review, \
        else false.

        Only use information present in the letter. Do not invent deadlines, \
        amounts, or obligations. Output the JSON object and nothing else.
        """
    }

    /// GBNF grammar constraining llama.cpp to emit exactly the Decoder JSON shape
    /// (A-27). On grammar-capable runtimes this *guarantees* a parseable object;
    /// the validate/repair parser remains the backstop for runtimes without it.
    static let grammar: String = #"""
    root   ::= "{" ws
               "\"summary\"" ws ":" ws string ws "," ws
               "\"severity\"" ws ":" ws severity ws "," ws
               "\"sender\"" ws ":" ws string ws "," ws
               "\"deadline\"" ws ":" ws (string | "null") ws "," ws
               "\"asks\"" ws ":" ws array ws "," ws
               "\"reply\"" ws ":" ws (string | "null") ws "," ws
               "\"needsLawyer\"" ws ":" ws boolean ws
               "}" ws
    severity ::= "\"info\"" | "\"action\"" | "\"urgent\"" | "\"legal\""
    boolean  ::= "true" | "false"
    array    ::= "[" ws (string (ws "," ws string)*)? ws "]"
    string   ::= "\"" ([^"\\] | "\\" ["\\/bfnrt])* "\""
    ws       ::= [ \t\n]*
    """#

    /// Default generation options for a decode: deterministic + grammar-constrained.
    static var generationOptions: LLMGenerationOptions {
        .structured(grammar: grammar)
    }

    /// Builds the full prompt for a captured letter.
    static func prompt(letterText: String, outputLanguage: String) -> LLMPrompt {
        LLMPrompt(system: system(outputLanguage: outputLanguage), user: letterText)
    }
}
