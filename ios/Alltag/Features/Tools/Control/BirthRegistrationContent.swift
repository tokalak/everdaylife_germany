import Foundation

/// Pure accessor for the birth-registration (Standesamt) sub-flow content (P6-F7).
///
/// Thin by design — it exposes the versioned `BirthRegistrationCatalog` as a
/// single tested surface (explainer sections + documents + follow-up steps) so
/// the view never reaches into the catalog directly and the content has a
/// unit-test boundary. **Information only**: there is no decision logic here, only
/// reference content.
enum BirthRegistrationContent {

    /// The ordered explainer sections.
    static var sections: [BirthRegistrationSection] { BirthRegistrationCatalog.sections }

    /// The documents the parents bring to the Standesamt.
    static var documents: [BirthRegistrationDocument] { BirthRegistrationCatalog.documents }

    /// The ordered follow-up steps.
    static var steps: [BirthRegistrationStep] { BirthRegistrationCatalog.steps }
}
