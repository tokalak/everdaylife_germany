import SwiftUI

/// A persona-specific tool shown in the Home "Tools for your mode" grid (P4-04 /
/// D10). The interactive **engines** behind these (Chancenkarte calculator, Blue
/// Card checker, …) are built in **Phase 6**; this is the catalog entry that
/// renders the tile and carries the deep-link.
///
/// Content only (String-Catalog keys, no literals); lives in `PersonaCatalog`
/// (X-06). `id` is stable so a tile's identity survives copy/threshold updates.
struct PersonaTool: Identifiable, Equatable {
    let id: String
    let titleKey: LocalizedStringKey
    var subtitleKey: LocalizedStringKey?
    let systemImage: String
    /// Icon-chip accent, drawn from the design-system palette (no new tokens).
    var tint: Color = AppColor.primary
    /// Small corner badge (e.g. "Try it" on the prototyped Chancenkarte tool).
    var badgeKey: LocalizedStringKey?
}

/// A cross-persona guide shown in the Home "Guides" list (P4-04 / P6-G*). All
/// five ship in V1; the reader screen + in-app search are **Phase 6** (P6-G6).
struct Guide: Identifiable, Equatable {
    let id: String
    let titleKey: LocalizedStringKey
    var subtitleKey: LocalizedStringKey?
    let systemImage: String
    var tint: Color = AppColor.primary
}
