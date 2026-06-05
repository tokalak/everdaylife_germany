import Foundation

/// A push destination inside Home's navigation stack (P6-G6).
///
/// Currently only guides navigate (their reader). Tool engines arrive in later
/// P6 tasks (P6-W*/T*/S*/F*/R*) and will extend this enum with a `.tool` case;
/// keeping the route typed (rather than routing on bare `String`) means those
/// additions stay unambiguous.
enum HomeRoute: Hashable {
    /// Opens the reader for a guide by its stable id (`GuideContent.id`).
    case guide(String)
    /// Opens in-app search across guides and the active mode's tools.
    case search
}
