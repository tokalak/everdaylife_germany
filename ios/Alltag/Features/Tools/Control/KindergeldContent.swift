import Foundation

/// Pure accessor for the Kindergeld (child benefit) guide content (P6-F5).
///
/// Thin by design — it exposes the versioned `KindergeldCatalog` and the
/// yearly-changing `KindergeldRate` as a single tested surface (explainer
/// sections + documents + steps + the current monthly amount) so the view never
/// reaches into the catalog directly and the content has a unit-test boundary.
/// **Information only**: there is no decision logic here, only reference content.
enum KindergeldContent {

    /// The ordered explainer sections.
    static var sections: [KindergeldSection] { KindergeldCatalog.sections }

    /// The documents the applicant needs.
    static var documents: [KindergeldDocument] { KindergeldCatalog.documents }

    /// The ordered application steps.
    static var steps: [KindergeldStep] { KindergeldCatalog.steps }

    /// The current (versioned) monthly amount per child. Re-verify yearly (OQ-1).
    static var rate: KindergeldRate { KindergeldRate.current }
}
