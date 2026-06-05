import SwiftUI

/// Top-level router (P2-04): shows the onboarding flow until it's completed,
/// then the 5-tab app shell. Mounted by `AlltagApp`.
///
/// Routing reads `onboarding.hasCompleted`, which is persisted — so onboarding
/// is shown once and the user lands directly on Home on every subsequent launch.
struct AppFlowView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Group {
            if env.onboarding.hasCompleted {
                RootView()
            } else {
                OnboardingView()
            }
        }
        .animation(.snappy(duration: 0.35), value: env.onboarding.hasCompleted)
    }
}

#Preview {
    AppFlowView()
        .environment(AppEnvironment.live())
}
