import SwiftUI

/// A "speaking" settings row (DS-04, D10): icon + title + one-line explanation,
/// with a trailing value and/or chevron. Every settings entry explains itself.
struct SettingsRow: View {
    let titleKey: LocalizedStringKey
    var explanationKey: LocalizedStringKey?
    let systemImage: String
    var tint: Color = AppColor.primary
    /// Optional trailing value (e.g. the current selection).
    var valueKey: LocalizedStringKey?
    var showsDisclosure: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppSpacing.xs + 2, style: .continuous))
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(titleKey)
                        .appText(.bodyEmphasis)
                        .foregroundStyle(AppColor.ink)
                    if let explanationKey {
                        Text(explanationKey)
                            .appText(.label)
                            .foregroundStyle(AppColor.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let valueKey {
                    Text(valueKey)
                        .appText(.callout)
                        .foregroundStyle(AppColor.inkSoft)
                }
                if showsDisclosure {
                    Image(systemName: "chevron.forward")
                        .appText(.label)
                        .foregroundStyle(AppColor.inkFaint)
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColor.line, lineWidth: 1))
            .appShadow(.sm)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        VStack(spacing: AppSpacing.xs) {
            SettingsRow(titleKey: "Appearance",
                        explanationKey: "Light, dark, or follow the system",
                        systemImage: "circle.lefthalf.filled",
                        valueKey: "System")
            SettingsRow(titleKey: "Delete all data",
                        explanationKey: "Remove every document and reset the app",
                        systemImage: "trash.fill",
                        tint: AppColor.severityUrgent,
                        showsDisclosure: false)
        }
        .padding()
    }
    .appFontDesign()
}
