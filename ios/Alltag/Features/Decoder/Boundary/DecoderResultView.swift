import SwiftUI

/// The decoded-letter result screen (P3-03).
///
/// Renders the validated ``DecodedLetter`` in the Warm-Companion language: a
/// severity pill, a plain-language summary, the RDG "information, not advice"
/// frame, the deadline (with add-to-calendar), the list of asks, a copyable
/// German reply, the collapsible original, and save/share actions. Legal letters
/// surface a prominent "talk to a lawyer" note (D9/X-04).
///
/// Calendar and Vault wiring arrive with those features (P3-08 / P3-05); until
/// then their buttons call the injected closures, which default to a toast.
struct DecoderResultView: View {
    let letter: DecodedLetter
    /// "Decode another letter."
    var onDone: () -> Void
    var onAddToCalendar: (() -> Void)?
    var onSaveToVault: (() -> Void)?

    /// Embed the content in a `ScrollView` (the shipping default). The snapshot
    /// harness sets this `false`: `ImageRenderer` renders `ScrollView` content
    /// blank, so tests render the content directly to exercise its layout (RTL,
    /// Dynamic Type) across the trait matrix.
    var embedInScrollView = true

    @State private var showOriginal = false
    @State private var showShare = false
    @State private var toast = false
    @State private var toastMessage: LocalizedStringKey = ""

    var body: some View {
        Group {
            if embedInScrollView {
                ScrollView { content }
            } else {
                content
            }
        }
        .background(AppColor.paper)
        .appToast(isPresented: $toast, toastMessage)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [shareText])
        }
    }

    // MARK: - Content

    /// The full result, laid out top-to-bottom. Wrapped in a `ScrollView` for the
    /// shipping screen; rendered directly by the snapshot harness.
    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            header
            SeverityPill(letter.severity)
                .appReveal(index: 0)
            Text(letter.summary)
                .appText(.body)
                .foregroundStyle(AppColor.ink)
                .appReveal(index: 1)
            DisclaimerNote(messageKey: "decoder_translated_note",
                           systemImage: "character.book.closed.fill")
                .appReveal(index: 2)

            if let deadline = letter.deadline {
                deadlineCard(deadline).appReveal(index: 3)
            }
            if !letter.asks.isEmpty {
                asksCard.appReveal(index: 4)
            }
            if let reply = letter.replyTemplate {
                replyCard(reply).appReveal(index: 5)
            }
            if letter.needsLawyer {
                DisclaimerNote(messageKey: "decoder_lawyer_note",
                               systemImage: "building.columns.fill")
                    .appReveal(index: 6)
            }
            if !letter.originalText.isEmpty {
                originalDisclosure.appReveal(index: 7)
            }
            actions.appReveal(index: 8)
        }
        .padding(AppSpacing.md)
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text("decoder_result_title")
                .appText(.title)
                .foregroundStyle(AppColor.ink)
            if !letter.sender.isEmpty {
                Text(letter.sender)
                    .appText(.caption)
                    .foregroundStyle(AppColor.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func deadlineCard(_ date: Date) -> some View {
        Card {
            HStack(spacing: AppSpacing.sm) {
                DeadlineChip(date: date, severity: letter.severity)
                VStack(alignment: .leading, spacing: 2) {
                    Text("decoder_deadline_title")
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                    Text("decoder_deadline_reminders")
                        .appText(.caption)
                        .foregroundStyle(AppColor.inkSoft)
                }
                Spacer()
                Button {
                    if let onAddToCalendar {
                        onAddToCalendar()
                        present("decoder_toast_calendar_added")
                    } else {
                        present("decoder_toast_calendar_soon")
                    }
                } label: {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(letter.severity.color)
                }
                .accessibilityLabel(Text("decoder_add_to_calendar"))
            }
        }
    }

    private var asksCard: some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("decoder_asks_title")
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
                ForEach(Array(letter.asks.enumerated()), id: \.offset) { index, ask in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Text("\(index + 1)")
                            .appText(.label)
                            .foregroundStyle(AppColor.onPrimary)
                            .frame(width: 22, height: 22)
                            .background(AppColor.primary, in: Circle())
                        Text(ask)
                            .appText(.body)
                            .foregroundStyle(AppColor.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func replyCard(_ reply: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("decoder_reply_title")
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = reply
                        present("decoder_toast_copied")
                    } label: {
                        Label("decoder_copy", systemImage: "doc.on.doc")
                            .appText(.label)
                            .foregroundStyle(AppColor.primary)
                    }
                }
                Text(reply)
                    .appText(.body)
                    .foregroundStyle(AppColor.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.sm)
                    .background(AppColor.paperSink, in: RoundedRectangle(
                        cornerRadius: AppRadius.sm, style: .continuous))
            }
        }
    }

    private var originalDisclosure: some View {
        Card {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Button {
                    withAnimation(.snappy(duration: 0.3)) { showOriginal.toggle() }
                } label: {
                    HStack {
                        Text("decoder_original_title")
                            .appText(.cardTitle)
                            .foregroundStyle(AppColor.ink)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppColor.inkFaint)
                            .rotationEffect(.degrees(showOriginal ? 180 : 0))
                    }
                }
                if showOriginal {
                    Text(letter.originalText)
                        .appText(.caption)
                        .foregroundStyle(AppColor.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Button {
                    if let onSaveToVault {
                        onSaveToVault()
                        present("decoder_toast_vault_saved")
                    } else {
                        present("decoder_toast_vault_soon")
                    }
                } label: {
                    Label("decoder_save_vault", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.secondary)

                Button {
                    showShare = true
                } label: {
                    Label("decoder_share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.onPrimary)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColor.primary, in: RoundedRectangle(
                            cornerRadius: AppRadius.md, style: .continuous))
                }
            }
            PrimaryButton(titleKey: "decoder_decode_another", action: onDone)
                .padding(.top, AppSpacing.xxs)
        }
    }

    // MARK: - Helpers

    private var shareText: String {
        var lines = [letter.summary]
        if !letter.asks.isEmpty {
            lines.append("")
            lines.append(contentsOf: letter.asks.map { "• \($0)" })
        }
        return lines.joined(separator: "\n")
    }

    private func fire(_ action: (() -> Void)?, fallback: LocalizedStringKey) {
        if let action { action() } else { present(fallback) }
    }

    private func present(_ message: LocalizedStringKey) {
        toastMessage = message
        toast = true
    }
}

#Preview("Action") {
    DecoderResultView(
        letter: DecodedLetter(
            summary: "The tax office needs you to confirm your current address and return the form by June 20.",
            severity: .action,
            sender: "Finanzamt Berlin-Mitte",
            deadline: Calendar.current.date(byAdding: .day, value: 12, to: .now),
            asks: ["Confirm the address matches your Anmeldung",
                   "Sign and date the enclosed form",
                   "Return it by post or via ELSTER before the deadline"],
            replyTemplate: "Sehr geehrte Damen und Herren, hiermit bestätige ich meine aktuelle Anschrift: …",
            originalText: "Bitte bestätigen Sie Ihre derzeitige Anschrift und senden Sie das beigefügte Formular bis zum 20. Juni 2026 unterschrieben zurück."),
        onDone: {})
    .appFontDesign()
}

#Preview("Legal") {
    DecoderResultView(
        letter: DecodedLetter(
            summary: "This is a court notice about an unpaid fine. A hearing is scheduled and you may need legal help.",
            severity: .legal,
            sender: "Amtsgericht München",
            deadline: Calendar.current.date(byAdding: .day, value: 4, to: .now),
            asks: ["Read the enclosed notice carefully", "Consider contacting a lawyer"],
            replyTemplate: nil,
            originalText: "Ladung zur mündlichen Verhandlung …"),
        onDone: {})
    .appFontDesign()
}
