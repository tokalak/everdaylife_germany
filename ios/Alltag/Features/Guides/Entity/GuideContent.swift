import SwiftUI

/// A renderable block inside a guide section. Guides are reference content
/// (information only, RDG / D9), so the vocabulary is deliberately small —
/// paragraphs and bullet points cover every guide we ship.
enum GuideBlock: Equatable {
    case paragraph(LocalizedStringKey)
    case bullet(LocalizedStringKey)
}

/// A titled section of a guide.
struct GuideSection: Identifiable, Equatable {
    let id: String
    let headingKey: LocalizedStringKey
    let blocks: [GuideBlock]
}

/// An official, external source for a guide — rendered as a link in the reader so
/// the user can go to the authoritative page (we inform, we don't replace it).
struct GuideSource: Identifiable, Equatable {
    let id: String
    let titleKey: LocalizedStringKey
    let url: URL
}

/// Full body content for a cross-persona guide (P6-G1…G5).
///
/// The lightweight Home tile is `Guide`; this is what the reader (P6-G6) renders,
/// looked up by a **shared stable `id`**. Versioned content (X-06) — lives in
/// `GuideLibrary`, never hard-coded in a view, so copy/order can change without
/// touching the reader. Title is reused from the tile's key (DRY).
struct GuideContent: Identifiable, Equatable {
    /// Matches the `Guide.id` of the Home tile that opens this guide.
    let id: String
    let titleKey: LocalizedStringKey
    /// One-line orientation shown under the title.
    var summaryKey: LocalizedStringKey?
    let sections: [GuideSection]
    var sources: [GuideSource] = []
    /// Whether the reader shows the "information, not legal advice" note — true
    /// for legally / tax consequential guides (most of them).
    var showsLegalDisclaimer: Bool = true
}
