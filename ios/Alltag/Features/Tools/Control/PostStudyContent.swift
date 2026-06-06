import Foundation

/// Pure accessor for the Post-study transition content (P6-S6).
///
/// Thin by design — it exposes the versioned `PostStudyCatalog` as a single
/// tested surface (explainer sections + the transition checklist) so the view
/// never reaches into the catalog directly and the content has a unit-test
/// boundary. **Information only**: there is no decision logic here, only
/// reference content.
enum PostStudyContent {

    /// The ordered explainer sections.
    static var sections: [PostStudySection] { PostStudyCatalog.sections }

    /// The ordered transition checklist.
    static var checklist: [PostStudyChecklistItem] { PostStudyCatalog.checklist }
}
