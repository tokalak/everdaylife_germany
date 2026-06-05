import SwiftUI

/// Where a checklist row, tool tile or guide row points when tapped (D10 — Home
/// deep-links into tools/guides). The interactive engines/guide reader land in
/// **Phase 6**, so Home resolves these to a "coming soon" affordance for now;
/// the references are modelled here so the wiring is in place and the content
/// files (X-06) can already declare intent.
enum PersonaDestination: Equatable {
    /// Opens an interactive tool by its stable id (Phase 6 engines).
    case tool(String)
    /// Opens a cross-persona guide by its stable id (Phase 6 reader).
    case guide(String)
    /// Jumps to one of the app's primary tabs.
    case tab(AppTab)
}

/// One step in a persona's onboarding-into-Germany checklist (P4-03).
///
/// Pure content — title/subtitle are String-Catalog keys, never literals, and an
/// optional `link` deep-links into the matching tool/guide (resolved by Home).
/// Lives in the versioned content catalog (`PersonaCatalog`, X-06) so the steps
/// can be edited without touching views. `id` is **stable** — it keys the user's
/// done-state (`ChecklistProgress`), so it must never be reused for a different
/// step.
struct ChecklistItem: Identifiable, Equatable {
    let id: String
    let titleKey: LocalizedStringKey
    var subtitleKey: LocalizedStringKey?
    var link: PersonaDestination?
}
