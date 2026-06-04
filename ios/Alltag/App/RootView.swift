import SwiftUI

/// Placeholder root for the Foundation phase (P0-01).
///
/// Deliberately minimal: the Warm-Companion design system (Phase 1) and the
/// real `TabView` shell (P0-06) replace this. It exists only to give the app a
/// launchable surface and a stable hook for the smoke test.
struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Alltag")
                .font(.largeTitle.weight(.semibold))
            Text("Foundation build")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    RootView()
}
