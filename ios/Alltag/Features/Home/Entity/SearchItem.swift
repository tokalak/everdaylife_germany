import SwiftUI

/// One searchable Home entry — a cross-persona guide or a persona tool (P6-G6).
///
/// Carries the String-Catalog **keys** (resolved to display text at search and
/// render time) plus what's needed to open the result. Pure content; built from
/// the catalog by `HomeSearch`.
struct SearchItem: Identifiable, Equatable {
    enum Kind: Equatable { case guide, tool }

    let kind: Kind
    /// The guide / tool id this result opens.
    let targetId: String
    let titleKey: String
    let subtitleKey: String?
    let systemImage: String
    var tint: Color = AppColor.primary

    /// Stable across kinds so guide and tool ids can never collide in a list.
    var id: String { "\(kind)/\(targetId)" }
}
