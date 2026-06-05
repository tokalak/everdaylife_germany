import Foundation
import UserNotifications
@testable import Alltag

/// A test double for `NotificationAuthorizing` — records request calls and
/// returns a configurable grant, with no system prompt.
actor StubNotificationAuthorizer: NotificationAuthorizing {
    private let grant: Bool
    private(set) var requestCount = 0

    init(grant: Bool = true) { self.grant = grant }

    func requestAuthorization() async -> Bool {
        requestCount += 1
        return grant
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        grant ? .authorized : .denied
    }
}

enum OnboardingTestEnv {
    /// Builds an `AppEnvironment` with isolated, in-memory controllers so
    /// onboarding/persona state doesn't leak between tests.
    @MainActor
    static func make(
        notifications: NotificationAuthorizing = StubNotificationAuthorizer()
    ) throws -> AppEnvironment {
        let suite = "alltag.tests.flow.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return AppEnvironment(
            persistence: try PersistenceController(inMemory: true),
            llm: try LLMTestFactory.service(),
            language: LanguageStore(defaults: defaults),
            personas: PersonaStore(defaults: defaults),
            onboarding: OnboardingController(defaults: defaults),
            notifications: notifications)
    }
}
