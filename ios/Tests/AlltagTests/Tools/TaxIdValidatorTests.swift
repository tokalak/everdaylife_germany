import XCTest
@testable import Alltag

/// Exhaustive tests for the pure German tax-identifier validator (P6-W6 / A-05).
///
/// The Steuer-ID checksum is verified by *constructing* a valid number with the
/// official algorithm and asserting acceptance, then mutating it to assert
/// rejection — no reliance on a hard-coded "magic" number.
final class TaxIdValidatorTests: XCTestCase {

    /// Compute the official check digit for a 10-digit prefix and return the full
    /// 11-digit Steuer-ID string.
    private func makeValidSteuerID(prefix10: [Int]) -> String {
        precondition(prefix10.count == 10)
        var product = 10
        for i in 0..<10 {
            var sum = (prefix10[i] + product) % 10
            if sum == 0 { sum = 10 }
            product = (sum * 2) % 11
        }
        var check = (11 - product) % 10
        if check == 10 { check = 0 }
        return (prefix10 + [check]).map(String.init).joined()
    }

    // MARK: - Steuer-ID

    func testAcceptsValidSteuerID() {
        let id = makeValidSteuerID(prefix10: [2, 4, 7, 6, 2, 9, 1, 3, 5, 7])
        XCTAssertEqual(id.count, 11)
        XCTAssertTrue(TaxIdValidator.isValidSteuerID(id))
    }

    func testAcceptsValidSteuerIDWithSpaces() {
        let id = makeValidSteuerID(prefix10: [2, 4, 7, 6, 2, 9, 1, 3, 5, 7])
        let spaced = "\(id.prefix(2)) \(id.dropFirst(2).prefix(3)) \(id.dropFirst(5).prefix(3)) \(id.suffix(3))"
        XCTAssertTrue(spaced.contains(" "))
        XCTAssertTrue(TaxIdValidator.isValidSteuerID(spaced))
    }

    func testAcceptsValidSteuerIDWithSlashes() {
        let id = makeValidSteuerID(prefix10: [3, 1, 4, 1, 5, 9, 2, 6, 5, 3])
        XCTAssertTrue(TaxIdValidator.isValidSteuerID("\(id.prefix(5))/\(id.suffix(6))"))
    }

    func testRejectsTooShort() {
        // 10 digits.
        XCTAssertFalse(TaxIdValidator.isValidSteuerID("1234567890"))
    }

    func testRejectsTooLong() {
        // 12 digits.
        XCTAssertFalse(TaxIdValidator.isValidSteuerID("123456789012"))
    }

    func testRejectsNonDigits() {
        XCTAssertFalse(TaxIdValidator.isValidSteuerID("0247629135X"))
        XCTAssertFalse(TaxIdValidator.isValidSteuerID("abcdefghijk"))
    }

    func testRejectsLeadingZero() {
        // Build a checksum-valid number whose leading digit is 0, then confirm
        // the structural leading-zero rule still rejects it.
        let id = makeValidSteuerID(prefix10: [0, 4, 7, 6, 2, 9, 1, 3, 5, 7])
        XCTAssertEqual(id.first, "0")
        XCTAssertFalse(TaxIdValidator.isValidSteuerID(id))
    }

    func testRejectsBadChecksumFromSingleMutation() {
        let id = Array(makeValidSteuerID(prefix10: [2, 4, 7, 6, 2, 9, 1, 3, 5, 7]))
        // Mutate the check digit (last char) to a different digit.
        var mutated = id
        let last = mutated.count - 1
        mutated[last] = mutated[last] == "0" ? "1" : "0"
        XCTAssertFalse(TaxIdValidator.isValidSteuerID(String(mutated)))
    }

    func testRejectsEmpty() {
        XCTAssertFalse(TaxIdValidator.isValidSteuerID(""))
    }

    // MARK: - Steuernummer (loose)

    func testLooksLikeSteuernummerAcceptsPlausible() {
        XCTAssertTrue(TaxIdValidator.looksLikeSteuernummer("1234567890"))     // 10
        XCTAssertTrue(TaxIdValidator.looksLikeSteuernummer("12/345/67890"))   // slashes, 11
        XCTAssertTrue(TaxIdValidator.looksLikeSteuernummer("1234567890123"))  // 13
    }

    func testLooksLikeSteuernummerRejectsJunk() {
        XCTAssertFalse(TaxIdValidator.looksLikeSteuernummer(""))
        XCTAssertFalse(TaxIdValidator.looksLikeSteuernummer("123"))            // too short
        XCTAssertFalse(TaxIdValidator.looksLikeSteuernummer("12345678901234")) // too long (14)
        XCTAssertFalse(TaxIdValidator.looksLikeSteuernummer("12-345-678"))     // illegal char
        XCTAssertFalse(TaxIdValidator.looksLikeSteuernummer("abcdefghij"))
    }

    // MARK: - Content catalog

    func testIdentifiersPopulated() {
        let ids = TaxIdentifierCatalog.identifiers
        XCTAssertGreaterThanOrEqual(ids.count, 2)
        XCTAssertEqual(Set(ids.map(\.id)).count, ids.count, "identifier ids must be unique")
        for i in ids {
            XCTAssertFalse(i.titleKey.isEmpty)
            XCTAssertFalse(i.whatKey.isEmpty)
            XCTAssertFalse(i.whereKey.isEmpty)
            XCTAssertFalse(i.whenKey.isEmpty)
        }
    }

    func testChecklistPopulated() {
        let steps = TaxIdentifierCatalog.checklist
        XCTAssertGreaterThanOrEqual(steps.count, 3)
        XCTAssertEqual(Set(steps.map(\.id)).count, steps.count, "step ids must be unique")
        for s in steps {
            XCTAssertFalse(s.titleKey.isEmpty)
            XCTAssertFalse(s.subtitleKey.isEmpty)
        }
    }

    // MARK: - Guide deep-link

    @MainActor
    func testLearnMoreGuideExists() {
        XCTAssertNotNil(
            GuideLibrary.content(for: "how_taxes_work"),
            "organizer 'learn more' deep-links a guide that must ship")
    }
}
