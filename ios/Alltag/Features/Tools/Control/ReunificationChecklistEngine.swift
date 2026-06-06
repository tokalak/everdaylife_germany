import Foundation

/// Maps a family relation to its reunification-visa document checklist (P6-F1).
///
/// Pure, exhaustively tested logic (A-05). The documents come from the versioned
/// `ReunificationChecklistCatalog`; this engine assembles the ordered list for the
/// chosen relation as common documents followed by the relation-specific ones.
/// **Information only** — the screen always carries the RDG note (requirements
/// vary by case and consulate).
enum ReunificationChecklistEngine {

    /// The ordered documents to gather for the given family relation:
    /// common documents (needed for every reunification application) followed by
    /// the relation-specific ones.
    static func documents(for relation: FamilyRelation) -> [ReunificationDocument] {
        ReunificationChecklistCatalog.common + ReunificationChecklistCatalog.specific(for: relation)
    }
}
