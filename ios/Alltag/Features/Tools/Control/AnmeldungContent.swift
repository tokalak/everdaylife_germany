import Foundation

/// Pure accessor for the Anmeldung guide content (P6-S4, shared with Worker).
///
/// Thin by design — it exposes the versioned `AnmeldungCatalog` as a single
/// tested surface (sections + documents + steps) so the view never reaches into
/// the catalog directly and the content has a unit-test boundary.
/// **Information only**: there is no decision logic here, only reference content.
enum AnmeldungContent {

    /// The ordered explainer sections.
    static var sections: [AnmeldungSection] { AnmeldungCatalog.sections }

    /// What to bring to the appointment.
    static var documents: [AnmeldungDocument] { AnmeldungCatalog.documents }

    /// The ordered how-to steps.
    static var steps: [AnmeldungStep] { AnmeldungCatalog.steps }
}
