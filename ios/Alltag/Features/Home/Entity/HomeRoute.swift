import Foundation

/// A push destination inside Home's navigation stack (P6-G6).
///
/// Tool engines land per P6 task (P6-W*/T*/S*/F*/R*); a tile only pushes `.tool`
/// once its screen exists (otherwise it toasts "coming soon"). Keeping the route
/// typed — rather than routing on bare `String` — keeps those additions
/// unambiguous from the guide/search routes.
enum HomeRoute: Hashable {
    /// Opens the reader for a guide by its stable id (`GuideContent.id`).
    case guide(String)
    /// Opens an interactive tool by its stable id (`PersonaTool.id`).
    case tool(String)
    /// Opens in-app search across guides and the active mode's tools.
    case search
}
