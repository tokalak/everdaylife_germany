import SwiftUI

/// A compact capsule that communicates a `Severity` with its symbol, color and
/// wash (DS-04). Used on Decoder results, deadlines and vault items.
struct SeverityPill: View {
    let severity: Severity
    /// Optional label override; defaults to the severity's own localized name.
    var titleKey: LocalizedStringKey?

    init(_ severity: Severity, titleKey: LocalizedStringKey? = nil) {
        self.severity = severity
        self.titleKey = titleKey
    }

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: severity.symbol)
                .imageScale(.small)
            Text(titleKey ?? severity.labelKey)
                .appText(.pill)
                .textCase(.uppercase)
        }
        .foregroundStyle(severity.color)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs - 2)
        .background(severity.wash, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(Severity.allCases) { SeverityPill($0) }
        }
        .padding()
    }
    .appFontDesign()
}
