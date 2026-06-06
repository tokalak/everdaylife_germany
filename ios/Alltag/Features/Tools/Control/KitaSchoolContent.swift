import Foundation

/// Pure accessor for the Kita/school enrollment content (P6-F6).
///
/// Thin by design — it exposes the versioned `KitaSchoolCatalog` as a single
/// tested surface (explainer sections + the practical steps) so the view never
/// reaches into the catalog directly and the content has a unit-test boundary.
/// **Information only**: there is no decision logic here, only reference content.
enum KitaSchoolContent {

    /// The ordered explainer sections.
    static var sections: [KitaSchoolSection] { KitaSchoolCatalog.sections }

    /// The ordered practical steps.
    static var steps: [KitaSchoolStep] { KitaSchoolCatalog.steps }
}
