import SwiftUI

/// The Decode tab — the app's center anchor and wedge feature (D10).
///
/// Two-layer gate: until the on-device model is ready it shows
/// ``DecoderReadinessView`` (P3-00); once ready it shows the capture → OCR →
/// explain → result flow (P3-01…P3-03). All inference is on-device — no letter
/// text or image ever leaves the phone (D4/X-03).
struct DecoderView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Group {
            if env.decoderReadiness.isReady {
                DecoderFlowView()
            } else {
                DecoderReadinessView()
            }
        }
    }
}

/// The capture → explain → result flow, shown once the model is ready (P3-03).
private struct DecoderFlowView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showScanner = false

    private var controller: DecoderController { env.decoder }

    var body: some View {
        Group {
            switch controller.phase {
            case .idle:
                idle
            case .recognizing:
                working(titleKey: "decoder_working_reading")
            case .decoding:
                working(titleKey: "decoder_working_explaining")
            case let .result(letter):
                DecoderResultView(
                    letter: letter,
                    onDone: { controller.reset() },
                    onAddToCalendar: letter.deadline.map { due in
                        { addToCalendar(letter, due: due) }
                    })
            case let .failed(failure):
                failed(failure)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.paper)
        .sheet(isPresented: $showScanner) { scannerSheet }
    }

    // MARK: - States

    private var idle: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(AppColor.primary)
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: AppSpacing.sm) {
                Text("decoder_idle_title")
                    .appText(.title)
                    .foregroundStyle(AppColor.ink)
                    .multilineTextAlignment(.center)
                Text("decoder_idle_subtitle")
                    .appText(.body)
                    .foregroundStyle(AppColor.inkSoft)
                    .multilineTextAlignment(.center)
            }
            TrustBanner(messageKey: "decoder_idle_trust", systemImage: "lock.fill")
            Spacer()
            if DocumentScannerView.isSupported {
                PrimaryButton(titleKey: "decoder_scan", systemImage: "camera.fill") {
                    showScanner = true
                }
            } else {
                // Simulator / camera-less device — scanning needs real hardware.
                DisclaimerNote(messageKey: "decoder_no_camera",
                               systemImage: "camera.metering.unknown")
            }
        }
        .padding(AppSpacing.lg)
    }

    private func working(titleKey: LocalizedStringKey) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            ProgressView().controlSize(.large)
            Text(titleKey)
                .appText(.cardTitle)
                .foregroundStyle(AppColor.ink)
            Text("decoder_working_hint")
                .appText(.caption)
                .foregroundStyle(AppColor.inkFaint)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(AppSpacing.lg)
    }

    private func failed(_ failure: DecoderFailure) -> some View {
        EmptyState(
            systemImage: "exclamationmark.bubble.fill",
            titleKey: LocalizedStringKey(failure.messageKey),
            messageKey: "decoder_error_hint",
            actionTitleKey: "decoder_try_again",
            action: { controller.reset() })
        .padding(AppSpacing.lg)
    }

    private var scannerSheet: some View {
        DocumentScannerView(
            onScan: { pages in
                showScanner = false
                let language = env.language.decoderOutputLanguage
                Task { await controller.decode(pages: pages, outputLanguage: language) }
            },
            onCancel: { showScanner = false })
        .ignoresSafeArea()
    }

    /// Persist the letter's deadline into the Dates agenda + schedule reminders
    /// (P3-08). Titled by the sender when known, else a generic label.
    private func addToCalendar(_ letter: DecodedLetter, due: Date) {
        let title = letter.sender.isEmpty
            ? String(localized: "decoder_deadline_generic_title")
            : letter.sender
        env.deadlines.add(
            title: title, dueDate: due, severity: letter.severity,
            note: letter.summary, source: .decoded)
    }
}
