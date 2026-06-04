import SwiftUI

/// App entry point.
///
/// This is the Foundation-phase shell (P0-01). The real DI container and the
/// 5-tab root (`Home · Docs · Decode · Dates · Settings`, see D10) arrive in
/// P0-06; for now we mount a single placeholder so the project builds, launches,
/// and is testable end to end.
@main
struct AlltagApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
