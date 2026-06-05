import Foundation
import SwiftData

/// One persona-checklist item's done-state for the user (A-07; P4-01/03).
///
/// Keyed by **(persona, itemId)** so progress is **preserved per persona**: when
/// the user switches mode and later switches back, their ticks are still there
/// (D1 — "switch without losing progress"). Structured data → SwiftData, in the
/// Application-Support store that survives app updates. The catalog
/// (`PersonaCatalog`) owns the item *content*; this owns only the user's state,
/// so a content edit never disturbs saved progress.
@Model
final class ChecklistProgress {
    /// `Persona.rawValue` of the checklist this item belongs to.
    var personaRaw: String
    /// Stable `ChecklistItem.id` within that persona's checklist.
    var itemId: String
    var isDone: Bool
    var updatedAt: Date

    init(personaRaw: String, itemId: String, isDone: Bool = true, updatedAt: Date = .now) {
        self.personaRaw = personaRaw
        self.itemId = itemId
        self.isDone = isDone
        self.updatedAt = updatedAt
    }
}
