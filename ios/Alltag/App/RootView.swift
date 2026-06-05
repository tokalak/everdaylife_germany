import SwiftUI

/// Root of the app: the 5-tab shell (D10) with live theming and localization
/// (P0-06).
///
/// Applies, app-wide:
/// - the selected **theme** via `preferredColorScheme` (A-20),
/// - the selected **language**'s `locale` and **RTL** `layoutDirection`
///   (A-12…A-14), and
/// - the Warm-Companion **rounded** type design (DS-02).
///
/// The tabs host Boundary placeholder screens; real features replace them in
/// later phases.
struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            ForEach(AppTab.allCases) { tab in
                screen(for: tab)
                    .tabItem { Label(tab.titleKey, systemImage: tab.systemImage) }
                    .tag(tab)
            }
        }
        .tint(AppColor.primary)
        .appFontDesign()
        .environment(\.locale, env.language.locale)
        .environment(\.layoutDirection, env.language.layoutDirection)
        .preferredColorScheme(env.theme.theme.colorScheme)
    }

    @ViewBuilder
    private func screen(for tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView(selection: $selection)
        case .docs: VaultView()
        case .decode: DecoderView()
        case .dates: DatesView()
        case .settings: SettingsView()
        }
    }
}

#Preview {
    RootView()
        .environment(AppEnvironment.live())
}
