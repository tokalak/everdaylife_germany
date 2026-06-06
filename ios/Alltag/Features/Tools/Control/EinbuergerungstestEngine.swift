import Foundation

/// Einbürgerungstest practice scoring engine (P6-R3) — PURE.
///
/// Highest-risk surface (A-05): exhaustively unit-tested. The engine is fully
/// **deterministic** — it never shuffles internally and never reads `Date.now`.
/// If the view wants variety it passes a pre-shuffled array in; the engine only
/// slices and scores so tests are stable.
enum EinbuergerungstestEngine {

    /// Builds a round by taking the first `size` questions (or all of them if the
    /// bank is smaller). Deterministic: it preserves the given order and does not
    /// shuffle. `size` defaults to a full official exam (or the whole bank if it
    /// holds fewer than `examQuestionCount` questions).
    static func round(
        from questions: [EinbuergerungstestQuestion],
        size: Int = min(EinbuergerungstestBank.examQuestionCount, EinbuergerungstestBank.questions.count)
    ) -> [EinbuergerungstestQuestion] {
        let count = max(0, min(size, questions.count))
        return Array(questions.prefix(count))
    }

    /// The correct answers needed to pass a round of `total` questions: the
    /// official 17-of-33 pass mark scaled up to the round size and rounded up, so
    /// a full 33-question round needs 17.
    static func requiredCorrect(forTotal total: Int) -> Int {
        guard total > 0 else { return 0 }
        let ratio = Double(EinbuergerungstestBank.passMark) / Double(EinbuergerungstestBank.examQuestionCount)
        return Int((Double(total) * ratio).rounded(.up))
    }

    /// Scores a round. `answers` maps a question id to the chosen option index;
    /// any question without an entry (or with a wrong index) counts as wrong.
    static func score(
        questions: [EinbuergerungstestQuestion],
        answers: [Int: Int]
    ) -> EinbuergerungstestResult {
        let total = questions.count
        let correct = questions.reduce(into: 0) { acc, question in
            if answers[question.id] == question.answerIndex { acc += 1 }
        }
        let required = requiredCorrect(forTotal: total)
        return EinbuergerungstestResult(
            correct: correct,
            total: total,
            requiredCorrect: required,
            passed: correct >= required)
    }
}
