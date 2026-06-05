import SwiftUI

/// The "My mode" switcher (P5-05 / D1): choose the active persona, see your
/// checklist progress in each mode, and revisit **"Past situations"** — the modes
/// you've used before.
///
/// Switching is **lossless**: progress is keyed by persona in `ChecklistStore`
/// and the engaged set is preserved in `PersonaStore`, so changing mode here never
/// discards anything. The screen is pushed from Settings inside its
/// `NavigationStack`.
struct ModePickerView: View {
    @Environment(AppEnvironment.self) private var env

    private var active: Persona? { env.personas.activePersona }

    var body: some View {
        List {
            chooseSection
            if !env.personas.pastPersonas.isEmpty {
                pastSection
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.paper)
        .navigationTitle("settings_mode_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    /// Every persona, selectable; the active one carries the badge.
    private var chooseSection: some View {
        Section {
            ForEach(Persona.allCases) { persona in
                row(persona)
            }
        } header: {
            Text("mode_choose")
        } footer: {
            Text("mode_switch_footer")
        }
    }

    /// Personas the user has engaged before but isn't currently in — a quick way
    /// back, with their preserved progress on show.
    private var pastSection: some View {
        Section {
            ForEach(env.personas.pastPersonas) { persona in
                row(persona)
            }
        } header: {
            Text("mode_past_situations")
        } footer: {
            Text("mode_past_footer")
        }
    }

    // MARK: - Row

    private func row(_ persona: Persona) -> some View {
        let isActive = persona == active
        return Button { env.personas.select(persona) } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: persona.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(persona.accent)
                    .frame(width: 32, height: 32)
                    .background(persona.accent.opacity(0.14), in: RoundedRectangle(
                        cornerRadius: AppRadius.sm, style: .continuous))
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(persona.titleKey)
                        .appText(.bodyEmphasis)
                        .foregroundStyle(AppColor.ink)
                    Text(persona.subtitleKey)
                        .appText(.label)
                        .foregroundStyle(AppColor.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    if let progress = progressText(persona) {
                        Text(verbatim: progress)
                            .appText(.label)
                            .foregroundStyle(persona.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if isActive {
                    Text("mode_active")
                        .appText(.pill)
                        .foregroundStyle(persona.accent)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(persona.accent.opacity(0.14), in: Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    /// "3/7" once a persona has a checklist; nil for personas without one. Matches
    /// Home's verbatim count style (the raw count isn't worth a plural table).
    private func progressText(_ persona: Persona) -> String? {
        let total = env.checklist.totalCount(in: persona)
        guard total > 0 else { return nil }
        return "\(env.checklist.completedCount(in: persona))/\(total)"
    }
}

#Preview {
    NavigationStack {
        ModePickerView()
            .environment(AppEnvironment.live())
    }
    .appFontDesign()
}
