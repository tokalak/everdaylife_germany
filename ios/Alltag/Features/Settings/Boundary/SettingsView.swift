import SwiftUI

/// Settings tab (P0-06 slice).
///
/// The full settings list (storage explainer, export/delete data, help, legal
/// — D10) is built in P3-09. For the Foundation phase it
/// exposes the two controls P0-06 must demonstrate: **Appearance** (theme
/// switching, A-20) and **Language** (DE/EN, A-12/A-13), both wired to the live
/// controllers so the change is visible app-wide immediately.
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        NavigationStack {
            Form {
                Section("settings_appearance") {
                    Picker("settings_appearance", selection: themeBinding) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.labelKey).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("settings_language") {
                    Picker("settings_language", selection: languageBinding) {
                        ForEach(AppLanguage.selectable) { language in
                            Text(language.endonym).tag(language)
                        }
                    }
                }
            }
            .navigationTitle("tab_settings")
        }
    }

    private var themeBinding: Binding<AppTheme> {
        Binding(
            get: { env.theme.theme },
            set: { env.theme.select($0) })
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { env.language.language },
            set: { env.language.select($0) })
    }
}
