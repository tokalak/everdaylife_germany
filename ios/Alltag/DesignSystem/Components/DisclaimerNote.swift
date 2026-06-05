import SwiftUI

/// The reusable "information, not legal advice" note (DS-06, RDG / D9).
///
/// Shown on anything legally or tax consequential. Uses the *legal* severity
/// tint (indigo). Default copy is localized; callers can supply specific wording
/// (e.g. routing to a lawyer on a legal item).
struct DisclaimerNote: View {
    var messageKey: LocalizedStringKey = "disclaimer_not_legal_advice"
    var systemImage: String = "info.circle.fill"

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Image(systemName: systemImage)
                .imageScale(.small)
                .foregroundStyle(AppColor.severityLegal)
            Text(messageKey)
                .appText(.caption)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.severityLegalWash)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        DisclaimerNote().padding()
    }
    .appFontDesign()
}
