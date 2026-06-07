import SwiftUI

/// Model readiness for the Decoder (P3-00).
///
/// The model is **bundled in the app** and never downloaded at runtime, so on a
/// supported device this is effectively always ready and the flow view takes
/// over immediately. This screen therefore only renders the rare non-ready
/// states: an unsupported device, or — a build/packaging error — missing bundled
/// weights. It reassures that everything stays on-device (D4/X-03): the Decoder
/// works fully offline.
struct DecoderReadinessView: View {
    @Environment(AppEnvironment.self) private var env

    private var controller: DecoderReadinessController { env.decoderReadiness }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            switch controller.readiness {
            case .ready:
                // The flow view takes over once ready; show nothing meaningful.
                ProgressView()
            case let .unsupported(reason):
                EmptyState(
                    systemImage: "iphone.slash",
                    titleKey: "decoder_unsupported_title",
                    messageKey: LocalizedStringKey(reason))
            case .unavailable:
                EmptyState(
                    systemImage: "exclamationmark.triangle.fill",
                    titleKey: "decoder_model_missing_title",
                    messageKey: "decoder_model_missing")
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.paper)
        .onAppear { controller.start() }
    }
}
