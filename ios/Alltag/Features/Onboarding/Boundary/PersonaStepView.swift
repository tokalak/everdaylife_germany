import SwiftUI

/// Onboarding screen 2 — persona pick (P2-02), the key decision (D1).
///
/// Five cards, one per audience (D2). Selecting one writes the active persona to
/// the live `PersonaStore`; `Continue` is enabled only once a persona is chosen.
struct PersonaStepView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        OnboardingScaffold(
            titleKey: "onboarding_persona_title",
            subtitleKey: "onboarding_persona_subtitle"
        ) {
            VStack(spacing: AppSpacing.sm) {
                ForEach(Persona.allCases) { persona in
                    card(for: persona)
                }
            }
        } footer: {
            PrimaryButton(titleKey: "onboarding_continue") {
                withAnimation(.snappy(duration: 0.3)) { env.onboarding.advance() }
            }
            .disabled(!env.personas.hasSelection)
            .opacity(env.personas.hasSelection ? 1 : 0.5)
        }
    }

    @ViewBuilder
    private func card(for persona: Persona) -> some View {
        let isSelected = env.personas.activePersona == persona

        Button {
            withAnimation(.snappy(duration: 0.25)) { env.personas.select(persona) }
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: persona.systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppColor.onPrimary)
                    .frame(width: 52, height: 52)
                    .background(persona.accent, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(persona.titleKey)
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(persona.subtitleKey)
                        .appText(.label)
                        .foregroundStyle(AppColor.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .imageScale(.large)
                    .foregroundStyle(isSelected ? persona.accent : AppColor.line)
            }
            .padding(AppSpacing.md)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? persona.accent : AppColor.line,
                        lineWidth: isSelected ? 2 : 1))
            .appShadow(isSelected ? .md : .sm)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
