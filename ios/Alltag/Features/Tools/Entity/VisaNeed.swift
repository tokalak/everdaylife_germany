import Foundation

/// Short-stay (≤90 days) visa-need classifier for Germany (P6-T1).
///
/// The user picks their **nationality** (ISO 3166-1 alpha-2 region code) and the
/// tool says whether they need a Schengen visa for a short stay. Country names
/// are *never* stored here — they come from `Locale` so the OS localizes them for
/// DE+EN automatically. Only the **code memberships** live here, isolated as
/// yearly-changing reference data (X-06 / AGENTS) that must be re-verified
/// against the EU lists (OQ-1). **Information only** (RDG / D9), never a decision.

/// What a nationality means for a short stay in Germany.
enum VisaNeedResult: String, Equatable {
    /// EU / EEA / Switzerland — free movement, no visa (may also live & work).
    case freeMovement
    /// Schengen visa-exempt (EU "Annex II") for short stays ≤90 days.
    case visaFreeShortStay
    /// A Schengen short-stay visa is required (EU "Annex I").
    case visaRequired
}

/// Versioned region-code memberships for the classifier.
///
/// **Re-verify against the official EU lists before each rollout (OQ-1):**
/// - free movement = EU/EEA/Switzerland,
/// - visa-free = the EU "Annex II" short-stay visa-exemption list
///   (Regulation (EU) 2018/1806, Annex II),
/// - everything else falls under "Annex I" → visa required.
struct VisaNeedData: Equatable {
    /// EU member states + Iceland, Liechtenstein, Norway, Switzerland.
    let freeMovement: Set<String>
    /// Annex II: third countries whose nationals are visa-exempt for short stays.
    let visaFree: Set<String>

    /// Shipping membership. Re-verify against Regulation (EU) 2018/1806 Annexes
    /// I & II and the Auswärtiges Amt overview before each rollout (OQ-1).
    static let current = VisaNeedData(
        // 27 EU members + EEA non-EU (IS, LI, NO) + Switzerland (CH) = 31.
        // (Switzerland is not in the EEA; free movement applies via a separate
        // agreement, so it's counted on top of the 30 EU/EEA states.)
        freeMovement: [
            "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
            "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
            "PL", "PT", "RO", "SK", "SI", "ES", "SE",          // 27 EU
            "IS", "LI", "NO",                                   // EEA non-EU
            "CH",                                               // Switzerland
        ],
        // EU Annex II — visa-exempt for short stays ≤90 days (non-exhaustive but
        // covers the common nationalities). Re-verify against Annex II (OQ-1).
        visaFree: [
            "AL", "AD", "AG", "AR", "AU", "BS", "BB", "BA", "BR", "BN",
            "CA", "CL", "CO", "CR", "DM", "SV", "GE", "GT", "GD", "HN",
            "HK", "IL", "JP", "KI", "XK", "MO", "MK", "MY", "MH", "MU",
            "MX", "FM", "MC", "ME", "NZ", "NI", "PW", "PA", "PY", "PE",
            "KN", "LC", "VC", "WS", "SM", "SC", "SG", "SB",
            "KR", "TW", "TL", "TO", "TT", "TV", "UA", "AE", "GB", "US",
            "UY", "VU", "VA", "VE",
        ]
    )
}
