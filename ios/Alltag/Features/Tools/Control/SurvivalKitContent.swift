import Foundation

/// Pure accessor for the Pre-arrival survival kit content (P6-T6).
///
/// Thin by design — it exposes the versioned `SurvivalKitCatalog` as a single
/// tested surface (tip categories + the before-you-fly checklist) so the view
/// never reaches into the catalog directly and the content has a unit-test
/// boundary. **Information only**: there is no decision logic here, only
/// reference content.
enum SurvivalKitContent {

    /// The grouped tip categories, in reading order.
    static var categories: [SurvivalCategory] { SurvivalKitCatalog.categories }

    /// What to sort out before you fly.
    static var checklist: [SurvivalChecklistItem] { SurvivalKitCatalog.checklist }
}
