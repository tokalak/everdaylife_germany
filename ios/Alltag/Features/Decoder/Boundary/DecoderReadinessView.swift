import SwiftUI

/// First-run model readiness for the Decoder (P3-00).
///
/// Binds to ``DecoderReadinessController`` and renders exactly one state: the
/// consent gate (Gemma terms + the ~3 GB download explained), live download
/// progress, verification, the unsupported-device message, or a retryable
/// failure. It reassures throughout that everything stays on-device (D4/X-03):
/// once downloaded the Decoder works fully offline.
struct DecoderReadinessView: View {
    @Environment(AppEnvironment.self) private var env

    private var controller: DecoderReadinessController { env.decoderReadiness }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            switch controller.readiness {
            case .idle, .needsConsent:
                consent
            case .checkingDevice:
                progress(titleKey: "decoder_setup_checking", fraction: nil)
            case let .downloading(fraction):
                progress(titleKey: "decoder_setup_downloading", fraction: fraction)
            case .verifying:
                progress(titleKey: "decoder_setup_verifying", fraction: nil)
            case .ready:
                // The flow view takes over once ready; show nothing meaningful.
                ProgressView()
            case let .unsupported(reason):
                unsupported(reason)
            case let .failed(message):
                failed(message)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.paper)
        .onAppear { controller.start() }
    }

    // MARK: - States

    private var consent: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppColor.primary)
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: AppSpacing.sm) {
                Text("decoder_setup_title")
                    .appText(.title)
                    .foregroundStyle(AppColor.ink)
                    .multilineTextAlignment(.center)
                Text("decoder_setup_subtitle")
                    .appText(.body)
                    .foregroundStyle(AppColor.inkSoft)
                    .multilineTextAlignment(.center)
            }
            TrustBanner(messageKey: "decoder_setup_trust", systemImage: "wifi.slash")
            Spacer()
            VStack(spacing: AppSpacing.xs) {
                PrimaryButton(titleKey: "decoder_setup_download") {
                    controller.acceptTermsAndDownload()
                }
                Text("decoder_setup_terms")
                    .appText(.caption)
                    .foregroundStyle(AppColor.inkFaint)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func progress(titleKey: LocalizedStringKey, fraction: Double?) -> some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            if let fraction {
                ProgressView(value: fraction) {
                    Text(titleKey).appText(.cardTitle)
                } currentValueLabel: {
                    Text(fraction.formatted(.percent.precision(.fractionLength(0))))
                        .appText(.caption)
                        .foregroundStyle(AppColor.inkSoft)
                }
                .tint(AppColor.primary)
            } else {
                ProgressView().controlSize(.large)
                Text(titleKey)
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
            }
            Text("decoder_setup_offline_hint")
                .appText(.caption)
                .foregroundStyle(AppColor.inkFaint)
                .multilineTextAlignment(.center)
            Spacer()
            Button("decoder_setup_cancel") { controller.cancel() }
                .buttonStyle(.secondary)
        }
    }

    private func unsupported(_ reason: String) -> some View {
        EmptyState(
            systemImage: "iphone.slash",
            titleKey: "decoder_unsupported_title",
            messageKey: LocalizedStringKey(reason))
    }

    private func failed(_ message: String) -> some View {
        EmptyState(
            systemImage: "exclamationmark.triangle.fill",
            titleKey: "decoder_failed_title",
            messageKey: LocalizedStringKey(message),
            actionTitleKey: "decoder_retry",
            action: { controller.retry() })
    }
}
