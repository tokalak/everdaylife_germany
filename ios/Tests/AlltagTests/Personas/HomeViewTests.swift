import SwiftUI
import XCTest
@testable import Alltag

/// Home screen (P4-02): greeting-time logic plus render-smoke across the trait
/// matrix (light/dark · Dynamic Type accessibility · RTL) — A-06 / X-02.
@MainActor
final class HomeViewTests: XCTestCase {

    // MARK: - Greeting logic

    private func at(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now)!
    }

    func testGreetingTracksTimeOfDay() {
        XCTAssertEqual(HomeView.greetingKey(now: at(hour: 8)), "home_greeting_morning")
        XCTAssertEqual(HomeView.greetingKey(now: at(hour: 14)), "home_greeting_day")
        XCTAssertEqual(HomeView.greetingKey(now: at(hour: 21)), "home_greeting_evening")
        XCTAssertEqual(HomeView.greetingKey(now: at(hour: 3)), "home_greeting_evening")
    }

    // MARK: - Render

    /// Builds an environment with the worker persona active, one pending deadline
    /// (for the "Up next" card) and a couple of ticked checklist items.
    private func workerEnvironment() throws -> AppEnvironment {
        let personas = PersonaStore(
            defaults: UserDefaults(suiteName: "home.\(UUID().uuidString)")!)
        personas.select(.worker)
        let env = AppEnvironment(
            persistence: try PersistenceController(inMemory: true),
            llm: try LLMTestFactory.service(),
            personas: personas)
        env.deadlines.add(
            title: "Confirm address · Finanzamt",
            dueDate: Date().addingTimeInterval(60 * 60 * 24 * 6),
            severity: .urgent)
        env.checklist.setDone("anmeldung", in: .worker, true)
        env.checklist.setDone("bank_account", in: .worker, true)
        return env
    }

    func testRendersWorkerHome() throws {
        let env = try workerEnvironment()
        SnapshotSupport.assertRenders(
            HomeView(embedInScrollView: false).environment(env),
            height: 1400)
    }

    /// Every persona's Home (P5-01…04 content) renders across the trait matrix —
    /// proves the Phase 5 checklist/tools content lays out for all five modes, not
    /// just Worker.
    func testRendersEveryPersonaHome() throws {
        for persona in Persona.allCases {
            let personas = PersonaStore(
                defaults: UserDefaults(suiteName: "home.\(UUID().uuidString)")!)
            personas.select(persona)
            let env = AppEnvironment(
                persistence: try PersistenceController(inMemory: true),
                llm: try LLMTestFactory.service(),
                personas: personas)
            SnapshotSupport.assertRenders(
                HomeView(embedInScrollView: false).environment(env),
                height: 1600)
        }
    }

    func testRendersDefensiveNoModeState() throws {
        // No persona selected → the teaching empty state still renders.
        let env = AppEnvironment(
            persistence: try PersistenceController(inMemory: true),
            llm: try LLMTestFactory.service())
        SnapshotSupport.assertRenders(
            HomeView(embedInScrollView: false).environment(env),
            height: 500)
    }
}
