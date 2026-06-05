import Foundation

/// Maps a freelance registration path to its ordered steps (P6-W7).
///
/// Pure, exhaustively tested logic (A-05). The steps come from the versioned
/// `FreelanceRegistrationCatalog`; this engine just selects the right ordered
/// list for the chosen legal form. **Information only** — the screen always
/// carries the RDG note.
enum FreelanceRegistrationEngine {

    /// The ordered steps to register under the given legal form.
    static func steps(for path: FreelancePath) -> [FreelanceStep] {
        switch path {
        case .freiberufler: return FreelanceRegistrationCatalog.freiberuflerSteps
        case .gewerbe:      return FreelanceRegistrationCatalog.gewerbeSteps
        }
    }
}
