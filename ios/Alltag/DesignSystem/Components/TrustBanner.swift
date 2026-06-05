import SwiftUI

/// A reassurance banner (DS-04): teal-wash strip with a lock icon affirming that
/// documents stay on the device (privacy is the product — D4/X-03). Default copy
/// is localized; callers may override.
struct TrustBanner: View {
    var messageKey: LocalizedStringKey = "trust_on_device"
    var systemImage: String = "lock.fill"

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: systemImage)
                .imageScale(.small)
            Text(messageKey)
                .appText(.label)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(AppColor.primaryDeep)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.primaryWash)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .strokeBorder(AppColor.primary.opacity(0.25), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        TrustBanner().padding()
    }
    .appFontDesign()
}
