import SwiftUI

/// A tappable tile for the Home "Tools for your mode" grid (DS-04): a colored
/// rounded-square icon, a title, and a one-line description.
struct ToolTile: View {
    let titleKey: LocalizedStringKey
    var subtitleKey: LocalizedStringKey?
    let systemImage: String
    /// Accent for the icon chip; defaults to the brand teal.
    var tint: Color = AppColor.primary
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppColor.onPrimary)
                    .frame(width: 42, height: 42)
                    .background(tint, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                Text(titleKey)
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitleKey {
                    Text(subtitleKey)
                        .appText(.label)
                        .foregroundStyle(AppColor.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
            ToolTile(titleKey: "Visa-fit tool", subtitleKey: "Which permit suits you",
                     systemImage: "location.north.circle.fill")
            ToolTile(titleKey: "Blue Card check", subtitleKey: "Salary threshold 2026",
                     systemImage: "creditcard.fill", tint: AppColor.severityLegal)
        }
        .padding()
    }
    .appFontDesign()
}
