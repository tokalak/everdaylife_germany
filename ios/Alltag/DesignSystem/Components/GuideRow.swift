import SwiftUI

/// A list row linking to a cross-persona guide (DS-04): leading tinted icon,
/// title + one-line summary, trailing chevron.
struct GuideRow: View {
    let titleKey: LocalizedStringKey
    var subtitleKey: LocalizedStringKey?
    let systemImage: String
    var tint: Color = AppColor.primary
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(titleKey)
                        .appText(.bodyEmphasis)
                        .foregroundStyle(AppColor.ink)
                    if let subtitleKey {
                        Text(subtitleKey)
                            .appText(.label)
                            .foregroundStyle(AppColor.inkSoft)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.forward")
                    .appText(.label)
                    .foregroundStyle(AppColor.inkFaint)
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
            GuideRow(titleKey: "Residence permit",
                     subtitleKey: "Aufenthaltstitel basics",
                     systemImage: "doc.text.fill")
            GuideRow(titleKey: "How taxes work",
                     subtitleKey: "Steuern, simply explained",
                     systemImage: "eurosign.circle.fill",
                     tint: AppColor.amber)
        }
        .padding()
    }
    .appFontDesign()
}
