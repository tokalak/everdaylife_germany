import Foundation

/// Pure accessor for the Verpflichtungserklärung explainer content (P6-T3).
///
/// Thin by design — it exposes the versioned `VerpflichtungCatalog` as a single
/// tested surface (sections + the sponsor's checklist) so the view never reaches
/// into the catalog directly and the content has a unit-test boundary.
/// **Information only**: there is no decision logic here, only reference content.
enum VerpflichtungContent {

    /// The ordered explainer sections.
    static var sections: [VerpflichtungSection] { VerpflichtungCatalog.sections }

    /// What the sponsor brings to the appointment.
    static var checklist: [VerpflichtungItem] { VerpflichtungCatalog.checklist }
}
