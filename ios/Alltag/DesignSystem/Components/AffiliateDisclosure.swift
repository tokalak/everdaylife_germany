import SwiftUI

/// The reusable affiliate transparency disclosure (P6-A1, brief §7).
///
/// Every comparison tool (bank, travel insurance, blocked account, student
/// health, GKV/PKV insurers) shows this single, shared note instead of a
/// duplicated per-tool string + inline view. It states plainly that some links
/// may earn a commission and that this never affects the ranking or the price
/// the user pays. Styled with the *action* (amber) tokens to read as a visible,
/// honest disclosure — information only.
struct AffiliateDisclosure: View {
    var messageKey: LocalizedStringKey = "affiliate_disclosure"
    var systemImage: String = "info.circle.fill"

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(AppColor.amber)
            Text(messageKey)
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.md)
        .background(
            AppColor.amberWash,
            in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColor.amber.opacity(0.4), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// The reusable per-option affiliate marker (P6-A1, brief §7).
///
/// Shown next to any option whose link is an affiliate link, so the affiliate
/// relationship is disclosed transparently on each row (not only in the
/// top-level note). One shared `affiliate_tag` string across all tools.
struct AffiliateTag: View {
    var labelKey: LocalizedStringKey = "affiliate_tag"

    var body: some View {
        Text(labelKey)
            .appText(.caption)
            .foregroundStyle(AppColor.severityAction)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xxs)
            .background(AppColor.amberWash, in: Capsule())
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        VStack(spacing: AppSpacing.md) {
            AffiliateDisclosure()
            AffiliateTag()
        }
        .padding()
    }
    .appFontDesign()
}
