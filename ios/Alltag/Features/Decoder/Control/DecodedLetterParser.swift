import Foundation

enum DecoderError: Error, Equatable {
    /// The model output contained no JSON object at all.
    case noJSONObject
    /// JSON was found but couldn't be parsed even after fence-stripping.
    case malformedJSON
    /// A decode came back with no usable summary — the one field we refuse to
    /// fabricate or show empty. Callers surface a "couldn't read this letter"
    /// state rather than a blank result (X-07).
    case missingSummary
}

/// Turns the on-device model's raw text into a validated ``DecodedLetter``
/// (A-27, X-07).
///
/// Small models drift: they wrap JSON in ``` fences, add a sentence of preamble,
/// emit `"deadline": "none"`, or invent a severity string. This parser is the
/// **validate / repair** layer that makes the output trustworthy before it
/// reaches the UI:
///
/// - **Extract** the first balanced `{…}` object, ignoring code fences and any
///   prose around it (so a GBNF-constrained *or* a free-form runtime both work).
/// - **Repair** each field to a safe value: unknown severity → `.info`, an
///   unparseable or absent deadline → `nil` (**never invent a date**), missing
///   arrays → empty, blank reply → `nil`.
/// - **Reject** only when there is no usable `summary`, the single field we will
///   not show empty.
struct DecodedLetterParser {
    /// ISO calendar dates the model is asked to emit (`YYYY-MM-DD`), parsed in a
    /// fixed locale/timezone so "2026-06-20" is stable regardless of device.
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Parse + repair `raw` into a ``DecodedLetter``, attaching the verbatim
    /// `originalText` from OCR. Throws ``DecoderError`` only when the output has no
    /// JSON or no summary.
    func parse(_ raw: String, originalText: String = "") throws -> DecodedLetter {
        guard let json = Self.extractJSONObject(from: raw) else {
            throw DecoderError.noJSONObject
        }
        guard
            let data = json.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw DecoderError.malformedJSON
        }

        let summary = Self.string(object["summary"]).trimmed
        guard !summary.isEmpty else { throw DecoderError.missingSummary }

        let severity = Self.severity(from: object["severity"])
        let needsLawyer = Self.bool(object["needsLawyer"])

        return DecodedLetter(
            summary: summary,
            severity: severity,
            sender: Self.string(object["sender"]).trimmed,
            deadline: Self.date(from: object["deadline"]),
            asks: Self.asks(from: object["asks"]),
            replyTemplate: Self.optionalString(object["reply"]),
            needsLawyer: needsLawyer,
            originalText: originalText)
    }

    // MARK: - JSON extraction

    /// Returns the first balanced `{…}` substring, tolerating ``` fences and prose
    /// before/after. Brace-counting respects string literals + escapes so a `}`
    /// inside a value (e.g. a reply mentioning `}`) doesn't end the object early.
    static func extractJSONObject(from raw: String) -> String? {
        let chars = Array(raw)
        guard let start = chars.firstIndex(of: "{") else { return nil }

        var depth = 0
        var inString = false
        var escaped = false
        for i in start..<chars.count {
            let c = chars[i]
            if escaped { escaped = false; continue }
            switch c {
            case "\\" where inString:
                escaped = true
            case "\"":
                inString.toggle()
            case "{" where !inString:
                depth += 1
            case "}" where !inString:
                depth -= 1
                if depth == 0 {
                    return String(chars[start...i])
                }
            default:
                break
            }
        }
        return nil
    }

    // MARK: - Field repair

    private static func string(_ value: Any?) -> String {
        value as? String ?? ""
    }

    /// Trimmed string, or `nil` when blank or a literal "null"/"none" placeholder.
    private static func optionalString(_ value: Any?) -> String? {
        let s = string(value).trimmed
        guard !s.isEmpty, !Self.nullTokens.contains(s.lowercased()) else { return nil }
        return s
    }

    private static func severity(from value: Any?) -> Severity {
        let raw = string(value).trimmed.lowercased()
        return Severity(rawValue: raw) ?? .info
    }

    private static func bool(_ value: Any?) -> Bool {
        if let b = value as? Bool { return b }
        if let n = value as? NSNumber { return n.boolValue }
        if let s = value as? String { return ["true", "yes", "1"].contains(s.lowercased()) }
        return false
    }

    /// Parse a `YYYY-MM-DD` date; tolerate a leading full-ISO timestamp. Any
    /// placeholder, empty, or unparseable value yields `nil` — we never invent a
    /// deadline (X-07).
    private static func date(from value: Any?) -> Date? {
        let s = string(value).trimmed
        guard !s.isEmpty, !Self.nullTokens.contains(s.lowercased()) else { return nil }
        let dayPart = String(s.prefix(10))
        return dayFormatter.date(from: dayPart)
    }

    private static func asks(from value: Any?) -> [String] {
        guard let array = value as? [Any] else { return [] }
        return array
            .compactMap { $0 as? String }
            .map(\.trimmed)
            .filter { !$0.isEmpty }
    }

    private static let nullTokens: Set<String> = ["null", "none", "n/a", "keine", "-"]
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
