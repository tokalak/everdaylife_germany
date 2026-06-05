import XCTest
@testable import Alltag

/// Validate/repair contract for ``DecodedLetterParser`` (A-27, X-07): the layer
/// that makes a drifting small model's output safe to render.
final class DecodedLetterParserTests: XCTestCase {
    private let parser = DecodedLetterParser()

    private func date(_ iso: String) -> Date {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: iso)!
    }

    // MARK: - Happy path

    func testParsesWellFormedObject() throws {
        let raw = """
        {
          "summary": "The tax office wants you to confirm your address.",
          "severity": "action",
          "sender": "Finanzamt Berlin-Mitte",
          "deadline": "2026-06-20",
          "asks": ["Confirm your address", "Sign and return the form"],
          "reply": "Sehr geehrte Damen und Herren, ...",
          "needsLawyer": false
        }
        """
        let letter = try parser.parse(raw, originalText: "Sehr geehrte ...")

        XCTAssertEqual(letter.summary, "The tax office wants you to confirm your address.")
        XCTAssertEqual(letter.severity, .action)
        XCTAssertEqual(letter.sender, "Finanzamt Berlin-Mitte")
        XCTAssertEqual(letter.deadline, date("2026-06-20"))
        XCTAssertEqual(letter.asks, ["Confirm your address", "Sign and return the form"])
        XCTAssertEqual(letter.replyTemplate, "Sehr geehrte Damen und Herren, ...")
        XCTAssertFalse(letter.needsLawyer)
        XCTAssertEqual(letter.originalText, "Sehr geehrte ...")
    }

    // MARK: - Extraction robustness

    func testStripsMarkdownCodeFences() throws {
        let raw = """
        Here is the result:
        ```json
        {"summary": "Info letter.", "severity": "info"}
        ```
        Hope that helps!
        """
        let letter = try parser.parse(raw)
        XCTAssertEqual(letter.summary, "Info letter.")
        XCTAssertEqual(letter.severity, .info)
    }

    func testIgnoresBraceInsideStringValue() throws {
        // A `}` inside a string must not terminate the object early.
        let raw = #"{"summary": "Use form A } B now", "severity": "action"}"#
        let letter = try parser.parse(raw)
        XCTAssertEqual(letter.summary, "Use form A } B now")
        XCTAssertEqual(letter.severity, .action)
    }

    func testThrowsWhenNoJSONObject() {
        XCTAssertThrowsError(try parser.parse("I could not read this letter.")) {
            XCTAssertEqual($0 as? DecoderError, .noJSONObject)
        }
    }

    // MARK: - Field repair

    func testUnknownSeverityFallsBackToInfo() throws {
        let raw = #"{"summary": "x", "severity": "catastrophic"}"#
        XCTAssertEqual(try parser.parse(raw).severity, .info)
    }

    func testMissingSeverityFallsBackToInfo() throws {
        let raw = #"{"summary": "x"}"#
        XCTAssertEqual(try parser.parse(raw).severity, .info)
    }

    func testLegalSeverityForcesNeedsLawyer() throws {
        // Even if the model says needsLawyer:false, a legal classification routes
        // to a lawyer (entity invariant).
        let raw = #"{"summary": "Court summons.", "severity": "legal", "needsLawyer": false}"#
        let letter = try parser.parse(raw)
        XCTAssertEqual(letter.severity, .legal)
        XCTAssertTrue(letter.needsLawyer)
    }

    func testNeedsLawyerAcceptsStringBool() throws {
        let raw = #"{"summary": "x", "severity": "action", "needsLawyer": "true"}"#
        XCTAssertTrue(try parser.parse(raw).needsLawyer)
    }

    func testNeverInventsDeadlineForPlaceholders() throws {
        for token in ["null", "none", "keine", "-", ""] {
            let raw = #"{"summary": "x", "severity": "info", "deadline": "\#(token)"}"#
            XCTAssertNil(try parser.parse(raw).deadline, "token=\(token) should yield nil")
        }
    }

    func testNeverInventsDeadlineForUnparseableDate() throws {
        let raw = #"{"summary": "x", "severity": "info", "deadline": "next Tuesday"}"#
        XCTAssertNil(try parser.parse(raw).deadline)
    }

    func testParsesDeadlineFromFullISOTimestamp() throws {
        let raw = #"{"summary": "x", "severity": "info", "deadline": "2026-06-20T00:00:00Z"}"#
        XCTAssertEqual(try parser.parse(raw).deadline, date("2026-06-20"))
    }

    func testAsksDropsEmptyAndNonStrings() throws {
        let raw = #"{"summary": "x", "severity": "info", "asks": ["  do this  ", "", 5, "and that"]}"#
        XCTAssertEqual(try parser.parse(raw).asks, ["do this", "and that"])
    }

    func testMissingAsksIsEmptyArray() throws {
        XCTAssertEqual(try parser.parse(#"{"summary": "x", "severity": "info"}"#).asks, [])
    }

    func testBlankReplyBecomesNil() throws {
        for token in ["", "   ", "null", "none"] {
            let raw = #"{"summary": "x", "severity": "info", "reply": "\#(token)"}"#
            XCTAssertNil(try parser.parse(raw).replyTemplate, "token=\(token)")
        }
    }

    // MARK: - Rejection

    func testThrowsWhenSummaryMissing() {
        XCTAssertThrowsError(try parser.parse(#"{"severity": "info"}"#)) {
            XCTAssertEqual($0 as? DecoderError, .missingSummary)
        }
    }

    func testThrowsWhenSummaryBlank() {
        XCTAssertThrowsError(try parser.parse(#"{"summary": "   ", "severity": "info"}"#)) {
            XCTAssertEqual($0 as? DecoderError, .missingSummary)
        }
    }
}
