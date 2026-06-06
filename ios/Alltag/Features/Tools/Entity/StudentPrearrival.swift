import Foundation

/// Content model for the pre-arrival checklist by nationality (P6-S1).
///
/// For studying in Germany (a long stay > 90 days) the steps you must take
/// *before* you travel depend on your nationality. This classifies a nationality
/// (ISO 3166-1 alpha-2 region code) into one of three entry routes and carries
/// the matching ordered pre-arrival checklist. Country names are *never* stored
/// here — they come from `Locale`. Only the **code memberships** live here,
/// isolated as yearly-changing reference data (X-06 / AGENTS) to be re-verified
/// (OQ-1). **Information only** (RDG / D9), never a decision.

/// How a nationality enters Germany to study.
enum StudentEntryRoute: String, Equatable, CaseIterable {
    /// EU / EEA / Switzerland — free movement: no visa, no residence permit;
    /// just enrol, register and arrange health insurance.
    case freeMovement
    /// "Privileged" non-EU nationals (§41 AufenthV) who may enter visa-free and
    /// apply for the residence permit **after** arrival (within 90 days).
    case visaFreeEntryThenPermit
    /// Everyone else: must obtain a national student visa (type D) at the German
    /// embassy **before** travelling.
    case nationalVisaRequired
}

/// One step in a pre-arrival checklist (stable id + title key + optional detail
/// key). Keys only — no literals (the strings live in `Localizable.xcstrings`).
struct PrearrivalStep: Identifiable, Equatable {
    let id: String
    let titleKey: String
    /// Optional short clarification shown under the title.
    let detailKey: String?

    init(id: String, titleKey: String, detailKey: String? = nil) {
        self.id = id
        self.titleKey = titleKey
        self.detailKey = detailKey
    }
}

/// Versioned region-code memberships for the route classifier.
///
/// **Re-verify before each rollout (OQ-1):**
/// - free movement = EU/EEA/Switzerland — reused from `VisaNeedData.current`
///   (DRY: that set is the single source of truth);
/// - the privileged set = §41 AufenthV (nationals who may enter visa-free for any
///   purpose and apply for a residence permit after arrival).
struct StudentPrearrivalData: Equatable {
    /// EU/EEA/Switzerland — free movement (no visa, no permit).
    let freeMovement: Set<String>
    /// §41 AufenthV "privileged" nationals: visa-free entry, then apply for the
    /// study residence permit after arrival.
    let privileged: Set<String>

    /// Shipping membership.
    static let current = StudentPrearrivalData(
        // Reuse the EU/EEA/Switzerland set from the short-stay classifier (DRY).
        freeMovement: VisaNeedData.current.freeMovement,
        // §41 AufenthV — exactly these 8 nationalities may enter visa-free and
        // apply for the residence permit after arrival (re-verify, OQ-1):
        // Australia, Israel, Japan, Canada, South Korea, New Zealand,
        // United Kingdom, United States.
        privileged: [
            "AU", "IL", "JP", "CA", "KR", "NZ", "GB", "US",
        ]
    )
}
