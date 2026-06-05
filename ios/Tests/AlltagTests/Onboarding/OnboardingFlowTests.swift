import SwiftUI
import XCTest
@testable import Alltag

/// Wiring + routing behavior for the onboarding flow (P2).
@MainActor
final class OnboardingFlowTests: XCTestCase {

    func testFlowRoutesToOnboardingUntilComplete() throws {
        let env = try OnboardingTestEnv.make()
        XCTAssertFalse(env.onboarding.hasCompleted, "fresh env starts in onboarding")
        // Walk the flow as the UI would.
        env.language.select(.en)
        env.onboarding.advance()
        env.personas.select(.worker)
        env.onboarding.advance()
        env.onboarding.complete()
        XCTAssertTrue(env.onboarding.hasCompleted)
        XCTAssertEqual(env.personas.activePersona, .worker)
    }

    func testEnableRemindersRequestsAuthorizationThenFinishes() async throws {
        let stub = StubNotificationAuthorizer(grant: true)
        let env = try OnboardingTestEnv.make(notifications: stub)
        // NotificationStepView's primary action: request, then complete.
        _ = await env.notifications.requestAuthorization()
        env.onboarding.complete()
        let count = await stub.requestCount
        XCTAssertEqual(count, 1, "permission requested exactly once")
        XCTAssertTrue(env.onboarding.hasCompleted)
    }

    func testSkipFinishesWithoutRequesting() async throws {
        let stub = StubNotificationAuthorizer(grant: false)
        let env = try OnboardingTestEnv.make(notifications: stub)
        // "Not now" finishes without touching the authorizer.
        env.onboarding.complete()
        let count = await stub.requestCount
        XCTAssertEqual(count, 0)
        XCTAssertTrue(env.onboarding.hasCompleted)
    }

    func testFlowViewsInstantiate() throws {
        let env = try OnboardingTestEnv.make()
        _ = AppFlowView().environment(env)
        _ = OnboardingView().environment(env)
    }
}

/// Render-smoke "snapshot" coverage for each onboarding screen across the trait
/// matrix (light/dark · Dynamic Type accessibility · RTL) — A-06 / X-02.
@MainActor
final class OnboardingRenderTests: XCTestCase {

    func testLanguageStep() throws {
        let env = try OnboardingTestEnv.make()
        SnapshotSupport.assertRenders(LanguageStepView().environment(env), width: 360, height: 800)
    }

    func testPersonaStep() throws {
        let env = try OnboardingTestEnv.make()
        env.personas.select(.worker)  // exercise the selected state too
        SnapshotSupport.assertRenders(PersonaStepView().environment(env), width: 360, height: 800)
    }

    func testNotificationStep() throws {
        let env = try OnboardingTestEnv.make()
        env.onboarding.advance()
        env.onboarding.advance()
        SnapshotSupport.assertRenders(NotificationStepView().environment(env), width: 360, height: 800)
    }
}
