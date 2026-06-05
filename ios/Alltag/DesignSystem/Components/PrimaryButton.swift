import SwiftUI

/// Filled primary call-to-action button style (DS-04): teal fill, rounded,
/// soft colored shadow, gentle press scale.
struct PrimaryButtonStyle: ButtonStyle {
    var fill: Color = AppColor.primary
    var foreground: Color = AppColor.onPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appText(.bodyEmphasis)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.lg)
            .background(fill, in: RoundedRectangle(cornerRadius: AppRadius.sm + 4, style: .continuous))
            .shadow(color: fill.opacity(0.34), radius: 12, x: 0, y: 8)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Secondary / ghost button style: card surface, hairline border, no fill.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appText(.bodyEmphasis)
            .foregroundStyle(AppColor.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.lg)
            .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.sm + 4, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm + 4, style: .continuous)
                    .strokeBorder(AppColor.line, lineWidth: 1))
            .appShadow(.sm)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

/// Convenience CTA: a labeled button already wearing `PrimaryButtonStyle`.
struct PrimaryButton: View {
    let titleKey: LocalizedStringKey
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(titleKey)
            }
        }
        .buttonStyle(.primary)
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        VStack(spacing: AppSpacing.md) {
            PrimaryButton(titleKey: "Scan a letter", systemImage: "camera.fill") {}
            Button("Maybe later") {}
                .buttonStyle(.secondary)
        }
        .padding()
    }
    .appFontDesign()
}
