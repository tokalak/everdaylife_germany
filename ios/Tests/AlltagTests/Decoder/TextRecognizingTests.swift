import XCTest
@testable import Alltag

/// The page-joining contract on ``TextRecognizing`` (P3-01) — the only OCR logic
/// that's device-independent and therefore unit-testable. Vision accuracy itself
/// is the A-28 eval harness's job.
final class TextRecognizingTests: XCTestCase {
    func testJoinsMultiplePagesInOrder() async throws {
        let p1 = StubTextRecognizer.page("Page one text")
        let p2 = StubTextRecognizer.page("Page two text")
        let recognizer = StubTextRecognizer(pages: [p1.data: p1.text, p2.data: p2.text])

        let text = try await recognizer.recognizeText(in: [p1.data, p2.data])

        XCTAssertEqual(text, "Page one text\n\nPage two text")
    }

    func testSkipsEmptyPagesButKeepsTheRest() async throws {
        let good = StubTextRecognizer.page("Real content")
        let blank = Data("blank".utf8) // not in the map → recognizer throws for it
        let recognizer = StubTextRecognizer(pages: [good.data: good.text])

        let text = try await recognizer.recognizeText(in: [blank, good.data])

        XCTAssertEqual(text, "Real content")
    }

    func testThrowsWhenAllPagesEmpty() async {
        let recognizer = StubTextRecognizer(pages: [:])
        do {
            _ = try await recognizer.recognizeText(in: [Data("a".utf8), Data("b".utf8)])
            XCTFail("expected noTextFound")
        } catch let error as TextRecognitionError {
            XCTAssertEqual(error, .noTextFound)
        } catch {
            XCTFail("unexpected \(error)")
        }
    }
}
