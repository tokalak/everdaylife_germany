import Foundation

/// Maps a visa purpose to its document checklist (P6-T2).
///
/// Pure, exhaustively tested logic (A-05). The documents come from the versioned
/// `EmbassyChecklistCatalog`; this engine assembles the ordered list for the
/// chosen purpose as common documents followed by the purpose-specific ones.
/// **Information only** — the screen always carries the RDG note (requirements
/// vary by consulate).
enum EmbassyChecklistEngine {

    /// The ordered documents to bring for the given visa purpose:
    /// common documents (needed for every appointment) followed by the
    /// purpose-specific ones.
    static func documents(for purpose: VisaPurpose) -> [ChecklistDocument] {
        EmbassyChecklistCatalog.common + EmbassyChecklistCatalog.specific(for: purpose)
    }
}
