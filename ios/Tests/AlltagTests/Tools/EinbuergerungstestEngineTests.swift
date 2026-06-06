import XCTest
@testable import Alltag

/// Einbürgerungstest practice scoring (P6-R3). Pure engine + question bank,
/// exhaustively tested (A-05): the bank is well-formed, `round` slices
/// deterministically, and scoring (including the scaled pass mark and unanswered
/// questions) is correct at the boundaries.
final class EinbuergerungstestEngineTests: XCTestCase {

    private var bank: [EinbuergerungstestQuestion] { EinbuergerungstestBank.questions }

    // MARK: - Bank integrity

    func testBankIsNonEmpty() {
        XCTAssertFalse(bank.isEmpty)
    }

    func testAllIdsAreUnique() {
        XCTAssertEqual(Set(bank.map(\.id)).count, bank.count)
    }

    func testEveryQuestionHasFourOptionsAndAValidAnswerIndex() {
        for q in bank {
            XCTAssertEqual(q.options.count, 4, "question \(q.id) must have 4 options")
            XCTAssertTrue((0...3).contains(q.answerIndex), "question \(q.id) answerIndex out of range")
            XCTAssertFalse(q.prompt.de.isEmpty, "question \(q.id) German prompt empty")
            XCTAssertFalse(q.prompt.en.isEmpty, "question \(q.id) English prompt empty")
            for option in q.options {
                XCTAssertFalse(option.de.isEmpty, "question \(q.id) has an empty German option")
                XCTAssertFalse(option.en.isEmpty, "question \(q.id) has an empty English option")
            }
        }
    }

    func testExamConfigMatchesOfficialRule() {
        XCTAssertEqual(EinbuergerungstestBank.examQuestionCount, 33)
        XCTAssertEqual(EinbuergerungstestBank.passMark, 17)
    }

    // MARK: - round

    func testRoundReturnsRequestedCount() {
        XCTAssertEqual(EinbuergerungstestEngine.round(from: bank, size: 5).count, 5)
        XCTAssertEqual(EinbuergerungstestEngine.round(from: bank, size: 1).count, 1)
    }

    func testRoundCapsAtBankSizeWhenSizeIsLarger() {
        let round = EinbuergerungstestEngine.round(from: bank, size: bank.count + 50)
        XCTAssertEqual(round.count, bank.count)
    }

    func testRoundIsDeterministicAndPreservesOrder() {
        let a = EinbuergerungstestEngine.round(from: bank, size: 6)
        let b = EinbuergerungstestEngine.round(from: bank, size: 6)
        XCTAssertEqual(a.map(\.id), b.map(\.id))
        XCTAssertEqual(a.map(\.id), Array(bank.prefix(6)).map(\.id))
    }

    func testRoundDefaultSizeIsFullExamOrWholeBank() {
        let round = EinbuergerungstestEngine.round(from: bank)
        XCTAssertEqual(round.count, min(EinbuergerungstestBank.examQuestionCount, bank.count))
    }

    func testRoundWithZeroOrNegativeSizeIsEmpty() {
        XCTAssertTrue(EinbuergerungstestEngine.round(from: bank, size: 0).isEmpty)
        XCTAssertTrue(EinbuergerungstestEngine.round(from: bank, size: -3).isEmpty)
    }

    // MARK: - requiredCorrect

    func testRequiredCorrectForFullExamIsSeventeen() {
        XCTAssertEqual(EinbuergerungstestEngine.requiredCorrect(forTotal: 33), 17)
    }

    func testRequiredCorrectScalesAndRoundsUp() {
        // 10 * 17/33 = 5.15 → 6
        XCTAssertEqual(EinbuergerungstestEngine.requiredCorrect(forTotal: 10), 6)
        // 1 * 17/33 = 0.51 → 1
        XCTAssertEqual(EinbuergerungstestEngine.requiredCorrect(forTotal: 1), 1)
        XCTAssertEqual(EinbuergerungstestEngine.requiredCorrect(forTotal: 0), 0)
    }

    // MARK: - scoring

    private func sample(_ count: Int) -> [EinbuergerungstestQuestion] {
        EinbuergerungstestEngine.round(from: bank, size: count)
    }

    func testAllCorrectPasses() {
        let qs = sample(bank.count)
        let answers = Dictionary(uniqueKeysWithValues: qs.map { ($0.id, $0.answerIndex) })
        let r = EinbuergerungstestEngine.score(questions: qs, answers: answers)
        XCTAssertEqual(r.correct, r.total)
        XCTAssertEqual(r.correct, bank.count)
        XCTAssertTrue(r.passed)
    }

    func testAllWrongFails() {
        let qs = sample(10)
        // pick a deliberately wrong index for each
        let answers = Dictionary(uniqueKeysWithValues: qs.map { q in
            (q.id, q.answerIndex == 0 ? 1 : 0)
        })
        let r = EinbuergerungstestEngine.score(questions: qs, answers: answers)
        XCTAssertEqual(r.correct, 0)
        XCTAssertFalse(r.passed)
    }

    func testUnansweredQuestionsCountAsWrong() {
        let qs = sample(5)
        let r = EinbuergerungstestEngine.score(questions: qs, answers: [:])
        XCTAssertEqual(r.correct, 0)
        XCTAssertFalse(r.passed)
    }

    func testBoundaryExactlyRequiredPassesAndOneFewerFails() {
        let qs = sample(bank.count)
        let required = EinbuergerungstestEngine.requiredCorrect(forTotal: qs.count)
        func answers(correct n: Int) -> [Int: Int] {
            var dict: [Int: Int] = [:]
            for (i, q) in qs.enumerated() {
                dict[q.id] = i < n ? q.answerIndex : (q.answerIndex == 0 ? 1 : 0)
            }
            return dict
        }
        let pass = EinbuergerungstestEngine.score(questions: qs, answers: answers(correct: required))
        XCTAssertEqual(pass.correct, required)
        XCTAssertTrue(pass.passed)

        let fail = EinbuergerungstestEngine.score(questions: qs, answers: answers(correct: required - 1))
        XCTAssertEqual(fail.correct, required - 1)
        XCTAssertFalse(fail.passed)
    }

    func testResultReportsTotalAndRequired() {
        let qs = sample(10)
        let r = EinbuergerungstestEngine.score(questions: qs, answers: [:])
        XCTAssertEqual(r.total, 10)
        XCTAssertEqual(r.requiredCorrect, 6)
    }
}
