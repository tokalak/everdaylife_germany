import SwiftUI
import XCTest
@testable import Alltag

/// Render-smoke "snapshot" coverage for the Decoder result screen across the
/// trait matrix (light/dark · Dynamic Type accessibility · RTL) — A-06 / X-02.
@MainActor
final class DecoderResultRenderTests: XCTestCase {

    private func letter(
        severity: Severity, deadline: Date? = .now,
        reply: String? = "Sehr geehrte Damen und Herren, …",
        needsLawyer: Bool = false
    ) -> DecodedLetter {
        DecodedLetter(
            summary: "The tax office needs you to confirm your current address and return the form.",
            severity: severity,
            sender: "Finanzamt Berlin-Mitte",
            deadline: deadline,
            asks: ["Confirm the address matches your Anmeldung", "Sign and return the form"],
            replyTemplate: reply,
            needsLawyer: needsLawyer,
            originalText: "Bitte bestätigen Sie Ihre derzeitige Anschrift …")
    }

    // `embedInScrollView: false` — ImageRenderer renders ScrollView content
    // blank, so we render the content directly (see DecoderResultView).

    func testRendersActionLetter() {
        SnapshotSupport.assertRenders(
            DecoderResultView(
                letter: letter(severity: .action), onDone: {}, embedInScrollView: false))
    }

    func testRendersLegalLetterWithLawyerNote() {
        SnapshotSupport.assertRenders(
            DecoderResultView(
                letter: letter(severity: .legal, reply: nil, needsLawyer: true),
                onDone: {}, embedInScrollView: false))
    }

    func testRendersInfoLetterWithoutDeadlineOrReply() {
        SnapshotSupport.assertRenders(
            DecoderResultView(
                letter: letter(severity: .info, deadline: nil, reply: nil),
                onDone: {}, embedInScrollView: false))
    }
}
