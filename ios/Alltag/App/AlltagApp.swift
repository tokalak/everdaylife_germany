import SwiftUI

/// App entry point (P0-06).
///
/// Builds the `AppEnvironment` DI container once and injects it into the SwiftUI
/// environment, then mounts the 5-tab `RootView`. The environment owns the
/// long-lived foundations (persistence, language, theme) wired up in Phase 0.
@main
struct AlltagApp: App {
    @State private var env = AppEnvironment.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
        }
    }
}
