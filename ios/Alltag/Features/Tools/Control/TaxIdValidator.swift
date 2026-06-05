import Foundation

/// Pure validator for German tax identifiers (P6-W6).
///
/// This is the A-05 tested engine: no UI, no storage, no side effects. It
/// validates the **Steuer-ID** rigorously using the official check-digit
/// algorithm, and offers a deliberately *loose* structural check for the
/// **Steuernummer** (whose format is Bundesland-specific, so only a plausibility
/// check is meaningful here).
enum TaxIdValidator {

    /// Strip spaces and slashes (the separators the user may type/paste).
    private static func digitsOnly(_ raw: String) -> String {
        raw.filter { $0 != " " && $0 != "/" }
    }

    /// Validate a Steuerliche Identifikationsnummer (Steuer-ID).
    ///
    /// Accepts the 11-digit number with optional spaces/slashes. Structural
    /// requirements: exactly 11 digits and a non-zero leading digit. Then the
    /// official check-digit algorithm must hold (the 11th digit is the checksum
    /// over the first ten).
    static func isValidSteuerID(_ raw: String) -> Bool {
        let cleaned = digitsOnly(raw)
        // Exactly 11 characters, all digits.
        guard cleaned.count == 11, cleaned.allSatisfy(\.isNumber) else { return false }
        let d = cleaned.compactMap { $0.wholeNumberValue }
        guard d.count == 11 else { return false }
        // Leading digit must not be zero.
        guard d[0] != 0 else { return false }

        var product = 10
        for i in 0..<10 {
            var sum = (d[i] + product) % 10
            if sum == 0 { sum = 10 }
            product = (sum * 2) % 11
        }
        var check = (11 - product) % 10
        if check == 10 { check = 0 }
        return check == d[10]
    }

    /// Loose plausibility check for a Steuernummer.
    ///
    /// The Steuernummer format is **Bundesland-specific** (10–13 digits,
    /// optionally written with slashes), so a rigorous national check is not
    /// possible here — only a structural plausibility check is offered: digits
    /// (plus optional `/`), with the digit count in the plausible 10–13 range.
    static func looksLikeSteuernummer(_ raw: String) -> Bool {
        // Only digits and slashes are allowed in the raw input.
        guard raw.allSatisfy({ $0.isNumber || $0 == "/" || $0 == " " }) else { return false }
        let digits = digitsOnly(raw)
        guard digits.allSatisfy(\.isNumber), !digits.isEmpty else { return false }
        return (10...13).contains(digits.count)
    }
}
