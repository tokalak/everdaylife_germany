import Foundation

/// Pure accessor for the A1 German test guide content (P6-F2).
///
/// Thin by design — it exposes the versioned `A1TestCatalog` as a single tested
/// surface (explainer sections + the booking checklist) so the view never
/// reaches into the catalog directly and the content has a unit-test boundary.
/// **Information only**: there is no decision logic here, only reference content.
enum A1TestContent {

    /// The ordered explainer sections.
    static var sections: [A1TestSection] { A1TestCatalog.sections }

    /// The ordered booking checklist.
    static var steps: [A1TestStep] { A1TestCatalog.steps }
}
