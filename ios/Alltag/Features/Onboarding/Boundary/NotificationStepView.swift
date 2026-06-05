import SwiftUI

/// Onboarding screen 3 — notification permission (P2-03).
///
/// Explains *why* reminders help (deadlines, document expiries) and reassures
/// that everything stays on-device, then requests permission. Either choice
/// finishes onboarding (P2-04) — permission is never a hard gate.
struct NotificationStepView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var isRequesting = false

    var body: some View {
        OnboardingScaffold(
            titleKey: "onboarding_notifications_title",
            subtitleKey: "onboarding_notifications_subtitle"
        ) {
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(AppColor.primary)
                    .symbolRenderingMode(.hierarchical)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                TrustBanner()
            }
        } footer: {
            VStack(spacing: AppSpacing.xs) {
                PrimaryButton(titleKey: "onboarding_notifications_allow") {
                    Task { await requestThenFinish() }
                }
                .disabled(isRequesting)
                Button("onboarding_notifications_skip") { finish() }
                    .buttonStyle(.secondary)
                    .disabled(isRequesting)
            }
        }
    }

    private func requestThenFinish() async {
        isRequesting = true
        _ = await env.notifications.requestAuthorization()
        isRequesting = false
        finish()
    }

    private func finish() {
        withAnimation(.snappy(duration: 0.35)) { env.onboarding.complete() }
    }
}
