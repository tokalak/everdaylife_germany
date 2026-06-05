import Foundation

/// Classifies a nationality (ISO 3166-1 alpha-2 region code) into the short-stay
/// visa-need result for Germany (P6-T1).
///
/// Pure, exhaustively tested logic (A-05) over injected, versioned memberships
/// (`VisaNeedData`) so the rule is data-independent. Codes are normalized
/// (trimmed + uppercased). Anything not on the free-movement or visa-free lists
/// falls under EU "Annex I" → `visaRequired`. **Information only** — the screen
/// always carries the RDG note and points the user to the Auswärtiges Amt.
enum VisaNeedEngine {

    static func result(
        for regionCode: String,
        data: VisaNeedData = .current
    ) -> VisaNeedResult {
        let code = regionCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if data.freeMovement.contains(code) { return .freeMovement }
        if data.visaFree.contains(code) { return .visaFreeShortStay }
        return .visaRequired
    }
}
