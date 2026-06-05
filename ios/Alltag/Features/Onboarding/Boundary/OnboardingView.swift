import SwiftUI

/// The onboarding flow container (P2): paper background, applies the app's
/// locale / layout direction / theme / rounded type (so a language pick is live
/// throughout), and shows the current step with a sliding transition.
struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()
            step
                .id(env.onboarding.step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
        }
        .environment(\.locale, env.language.locale)
        .environment(\.layoutDirection, env.language.layoutDirection)
        .preferredColorScheme(env.theme.theme.colorScheme)
        .appFontDesign()
        .tint(AppColor.primary)
    }

    @ViewBuilder
    private var step: some View {
        switch env.onboarding.step {
        case .language:      LanguageStepView()
        case .persona:       PersonaStepView()
        case .notifications: NotificationStepView()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppEnvironment.live())
}
