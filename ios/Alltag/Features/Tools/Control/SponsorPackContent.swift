import Foundation

/// Pure accessor for the Sponsor document pack content (P6-F3).
///
/// Thin by design — it exposes the versioned `SponsorPackCatalog` as a single
/// tested surface (the grouped document pack) so the view never reaches into the
/// catalog directly and the content has a unit-test boundary. **Information
/// only**: there is no decision logic here, only reference content.
enum SponsorPackContent {

    /// The ordered document groups, each with its document items.
    static var groups: [SponsorDocGroup] { SponsorPackCatalog.groups }
}
