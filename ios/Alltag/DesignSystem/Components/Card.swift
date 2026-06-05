import SwiftUI

/// The base surface of the design system (DS-04): a rounded, bordered, softly
/// shadowed container on `card` background. Almost every grouped element sits in
/// a `Card`.
struct Card<Content: View>: View {
    var padding: CGFloat = AppSpacing.md
    var radius: CGFloat = AppRadius.md
    var shadow: AppShadow = .sm
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppColor.line, lineWidth: 1))
            .appShadow(shadow)
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        VStack(spacing: AppSpacing.md) {
            Card {
                Text("A warm, bordered surface")
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
            }
            Card(shadow: .md) {
                Text("Elevated card")
                    .appText(.body)
                    .foregroundStyle(AppColor.inkSoft)
            }
        }
        .padding()
    }
    .appFontDesign()
}
