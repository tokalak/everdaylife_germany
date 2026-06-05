import SwiftUI

/// Shared chrome for an onboarding step (P2): an optional back control + a
/// step-progress indicator at the top, a scrollable title/subtitle/content
/// block, and a footer pinned to the bottom for the call(s) to action.
struct OnboardingScaffold<Content: View, Footer: View>: View {
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(titleKey)
                            .appText(.display)
                            .foregroundStyle(AppColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitleKey)
                            .appText(.callout)
                            .foregroundStyle(AppColor.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
            }
            footer
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.md)
        }
    }

    private var topBar: some View {
        HStack {
            if !env.onboarding.isFirstStep {
                Button {
                    withAnimation(.snappy(duration: 0.3)) { env.onboarding.back() }
                } label: {
                    Image(systemName: "chevron.backward")
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.inkSoft)
                        .frame(width: 40, height: 40)
                        .background(AppColor.card, in: Circle())
                        .appShadow(.sm)
                }
                .accessibilityLabel("onboarding_back")
            }
            Spacer()
            OnboardingProgress(step: env.onboarding.step)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.sm)
    }
}

/// A row of dots showing progress through the onboarding steps; the current
/// step's dot is elongated and tinted.
struct OnboardingProgress: View {
    let step: OnboardingStep

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(OnboardingStep.allCases) { s in
                Capsule()
                    .fill(s == step ? AppColor.primary : AppColor.line)
                    .frame(width: s == step ? 22 : 8, height: 8)
            }
        }
        .animation(.snappy(duration: 0.3), value: step)
        .accessibilityLabel(Text("\(step.ordinal) / \(OnboardingStep.count)"))
    }
}
