import SwiftUI

/// Warm-Companion typography (DS-02).
///
/// The design uses SF Pro **Rounded**. Applying `.fontDesign(.rounded)` once at
/// the root cascades to all text while keeping full Dynamic Type behaviour (we
/// never hard-code point sizes). Per-component refinements arrive in Phase 1.
extension View {
    /// Applies the app's rounded type design to this subtree.
    func appFontDesign() -> some View {
        fontDesign(.rounded)
    }
}
