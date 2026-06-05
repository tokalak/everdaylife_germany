import SwiftUI

/// A friendly empty state that teaches the next action (DS-04, X-05): an icon,
/// a title, a one-line explanation, and an optional primary action.
struct EmptyState: View {
    let systemImage: String
    let titleKey: LocalizedStringKey
    var messageKey: LocalizedStringKey?
    var actionTitleKey: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(AppColor.primary)
                .padding(.bottom, AppSpacing.xxs)
            Text(titleKey)
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
                .multilineTextAlignment(.center)
            if let messageKey {
                Text(messageKey)
                    .appText(.callout)
                    .foregroundStyle(AppColor.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let actionTitleKey, let action {
                PrimaryButton(titleKey: actionTitleKey, action: action)
                    .fixedSize()
                    .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        EmptyState(
            systemImage: "tray.fill",
            titleKey: "No documents yet",
            messageKey: "Scan or import a letter and it lands here — stored only on this device.",
            actionTitleKey: "Scan a letter",
            action: {})
        .padding()
    }
    .appFontDesign()
}
