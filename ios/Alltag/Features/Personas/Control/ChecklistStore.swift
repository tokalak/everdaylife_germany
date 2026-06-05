import Foundation
import Observation
import SwiftData

/// Owns the user's checklist progress across personas (P4-01/03).
///
/// The single source of truth for "which steps has the user ticked", persisted
/// in SwiftData keyed by **(persona, itemId)** so progress is **preserved when
/// switching mode** (D1). Only *completed* items are stored — an absent record
/// means "not done" — so the store stays tiny and a content edit to the catalog
/// never strands rows. Counts/fractions are always taken against the current
/// `PersonaCatalog`, so a step removed from content silently drops out of the
/// progress maths.
@MainActor
@Observable
final class ChecklistStore {
    @ObservationIgnored private let context: ModelContext

    /// Completed keys (`"<persona>|<itemId>"`), cached in memory for cheap reads
    /// and to drive `@Observable` updates.
    private(set) var completedKeys: Set<String> = []

    init(context: ModelContext) {
        self.context = context
        reload()
    }

    private static func key(_ persona: Persona, _ itemId: String) -> String {
        "\(persona.rawValue)|\(itemId)"
    }

    func reload() {
        let all = (try? context.fetch(FetchDescriptor<ChecklistProgress>())) ?? []
        completedKeys = Set(all.filter(\.isDone).map { "\($0.personaRaw)|\($0.itemId)" })
    }

    // MARK: - Reads

    func isDone(_ itemId: String, in persona: Persona) -> Bool {
        completedKeys.contains(Self.key(persona, itemId))
    }

    /// Number of the persona's *current* checklist steps the user has completed.
    func completedCount(in persona: Persona) -> Int {
        PersonaCatalog.checklist(for: persona).filter { isDone($0.id, in: persona) }.count
    }

    func totalCount(in persona: Persona) -> Int {
        PersonaCatalog.checklist(for: persona).count
    }

    /// Completion fraction 0…1 (0 when the persona has no checklist yet).
    func fraction(in persona: Persona) -> Double {
        let total = totalCount(in: persona)
        guard total > 0 else { return 0 }
        return Double(completedCount(in: persona)) / Double(total)
    }

    // MARK: - Writes

    func toggle(_ itemId: String, in persona: Persona) {
        setDone(itemId, in: persona, !isDone(itemId, in: persona))
    }

    func setDone(_ itemId: String, in persona: Persona, _ done: Bool) {
        let existing = record(for: itemId, in: persona)
        if done {
            if let existing {
                existing.isDone = true
                existing.updatedAt = .now
            } else {
                context.insert(ChecklistProgress(
                    personaRaw: persona.rawValue, itemId: itemId, isDone: true))
            }
        } else if let existing {
            // Absent record == not done; delete rather than keep a false row.
            context.delete(existing)
        }
        persist()
    }

    /// Remove all progress (GDPR "delete all data", P3-09).
    func removeAll() {
        try? context.delete(model: ChecklistProgress.self)
        persist()
    }

    // MARK: - Internals

    private func record(for itemId: String, in persona: Persona) -> ChecklistProgress? {
        // Fetch-all + filter in memory rather than a `#Predicate` keypath: the
        // set is tiny (a user's ticks) and this keeps the persistence layer free
        // of the SwiftData keypath pitfalls the Calendar store also avoids.
        let all = (try? context.fetch(FetchDescriptor<ChecklistProgress>())) ?? []
        return all.first { $0.personaRaw == persona.rawValue && $0.itemId == itemId }
    }

    private func persist() {
        try? context.save()
        reload()
    }
}
