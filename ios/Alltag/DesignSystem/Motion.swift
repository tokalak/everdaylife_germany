import SwiftUI

/// Gentle staggered reveal on screen load (DS-05).
///
/// Children fade + rise into place, each delayed slightly by its index. The
/// effect is **fully suppressed** when the system "Reduce Motion" setting is on
/// (content appears immediately at its resting state) — honoring accessibility.
private struct StaggeredRevealModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 12)
                .onAppear {
                    withAnimation(
                        .easeOut(duration: 0.4)
                            .delay(baseDelay + Double(index) * 0.06)
                    ) {
                        shown = true
                    }
                }
        }
    }
}

extension View {
    /// Reveals this view with a staggered fade-and-rise based on its `index`
    /// among siblings. Honors Reduce Motion (DS-05).
    func appReveal(index: Int = 0, baseDelay: Double = 0) -> some View {
        modifier(StaggeredRevealModifier(index: index, baseDelay: baseDelay))
    }
}
