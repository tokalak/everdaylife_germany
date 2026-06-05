import SwiftUI

/// Onboarding screen 1 — language pick (P2-01).
///
/// The full v1 language list is rendered so users see their language is coming,
/// but only `AppLanguage.selectable` (DE/EN) can be chosen today; the rest carry
/// a "Soon" badge and are disabled until Phase 8. Picking a language updates the
/// live `LanguageStore`, so the rest of onboarding localizes immediately.
struct LanguageStepView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        OnboardingScaffold(
            titleKey: "onboarding_language_title",
            subtitleKey: "onboarding_language_subtitle"
        ) {
            VStack(spacing: AppSpacing.xs) {
                ForEach(AppLanguage.allCases) { language in
                    row(for: language)
                }
            }
        } footer: {
            PrimaryButton(titleKey: "onboarding_continue") {
                withAnimation(.snappy(duration: 0.3)) { env.onboarding.advance() }
            }
        }
    }

    @ViewBuilder
    private func row(for language: AppLanguage) -> some View {
        let isSelected = env.language.language == language
        let isAvailable = language.isSelectable

        Button {
            env.language.select(language)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Text(language.endonym)
                    .appText(.bodyEmphasis)
                    .foregroundStyle(isAvailable ? AppColor.ink : AppColor.inkFaint)
                Spacer()
                if !isAvailable {
                    Text("onboarding_language_soon")
                        .appText(.pill)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColor.inkSoft)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 3)
                        .background(AppColor.paperSink, in: Capsule())
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColor.primary)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColor.primary : AppColor.line,
                        lineWidth: isSelected ? 2 : 1))
            .appShadow(.sm)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
