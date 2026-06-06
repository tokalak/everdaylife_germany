import Foundation

/// Pure accessor for the Post-arrival checklist content (P6-F4).
///
/// Thin by design — it exposes the versioned `PostArrivalCatalog` as a single
/// tested surface (the ordered first-weeks steps) so the view never reaches into
/// the catalog directly and the content has a unit-test boundary. **Information
/// only**: there is no decision logic here, only ordered reference content.
enum PostArrivalContent {

    /// Short "why the order matters" intro note key.
    static var introNoteKey: String { PostArrivalCatalog.introNoteKey }

    /// The ordered first-weeks checklist.
    static var steps: [PostArrivalStep] { PostArrivalCatalog.steps }
}
