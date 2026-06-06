import Foundation

/// Pure accessor for the Family-reunification quick guide content (P6-R5).
///
/// Thin by design — it exposes the versioned `ReunificationGuideCatalog` as a
/// single tested surface (explainer sections + the step list) so the view never
/// reaches into the catalog directly and the content has a unit-test boundary.
/// **Information only**: there is no decision logic here, only reference content.
enum ReunificationGuideContent {

    /// The ordered explainer sections.
    static var sections: [ReunificationGuideSection] { ReunificationGuideCatalog.sections }

    /// The ordered step list.
    static var steps: [ReunificationGuideStep] { ReunificationGuideCatalog.steps }
}
