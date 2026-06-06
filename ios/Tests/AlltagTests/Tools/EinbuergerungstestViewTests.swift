import SwiftUI
import XCTest
@testable import Alltag

/// Einbürgerungstest practice screen (P6-R3): render-smoke across the trait
/// matrix for the first question, an answered (feedback) state, and the result
/// card (A-06 / X-02).
@MainActor
final class EinbuergerungstestViewTests: XCTestCase {

    func testRendersFirstQuestion() {
        SnapshotSupport.assertRenders(
            EinbuergerungstestView(embedInScrollView: false), height: 900)
    }

    func testRendersAnsweredQuestionWithFeedback() {
        let q = EinbuergerungstestBank.questions
        SnapshotSupport.assertRenders(
            EinbuergerungstestView(
                current: 0,
                answers: [q[0].id: q[0].answerIndex],
                embedInScrollView: false),
            height: 1000)
    }

    func testRendersResultCard() {
        let q = EinbuergerungstestBank.questions
        let answers = Dictionary(uniqueKeysWithValues: q.map { ($0.id, $0.answerIndex) })
        SnapshotSupport.assertRenders(
            EinbuergerungstestView(answers: answers, finished: true, embedInScrollView: false),
            height: 700)
    }
}
