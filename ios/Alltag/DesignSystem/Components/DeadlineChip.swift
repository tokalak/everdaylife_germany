import SwiftUI

/// A compact deadline indicator (DS-04): a calendar glyph with month/day plus a
/// short relative label (e.g. "Due in 6 days"), tinted by `severity`. Used on
/// Home "Up next", Decoder results and the Dates agenda.
struct DeadlineChip: View {
    let date: Date
    /// e.g. "Due in 6 days". Caller supplies the (already localized) text.
    var relativeLabel: String?
    var severity: Severity = .action

    private var monthText: String {
        date.formatted(.dateTime.month(.abbreviated)).uppercased()
    }
    private var dayText: String {
        date.formatted(.dateTime.day())
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            VStack(spacing: 0) {
                Text(monthText)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(AppColor.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                    .background(severity.color)
                Text(dayText)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColor.ink)
                    .padding(.vertical, 1)
            }
            .frame(width: 38)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.xs, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.xs, style: .continuous)
                    .strokeBorder(AppColor.line, lineWidth: 1))

            if let relativeLabel {
                Text(relativeLabel)
                    .appText(.label)
                    .foregroundStyle(severity.color)
            }
        }
        .padding(AppSpacing.xs)
        .padding(.trailing, relativeLabel == nil ? 0 : AppSpacing.xs)
        .background(severity.wash, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(relativeLabel ?? "\(monthText) \(dayText)"))
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            DeadlineChip(date: .now, relativeLabel: "Due in 6 days · Jun 20")
            DeadlineChip(date: .now, relativeLabel: "Overdue", severity: .urgent)
            DeadlineChip(date: .now, severity: .info)
        }
        .padding()
    }
    .appFontDesign()
}
