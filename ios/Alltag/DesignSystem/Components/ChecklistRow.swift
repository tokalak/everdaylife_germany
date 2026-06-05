import SwiftUI

/// A checklist item (DS-04): a tappable check box, a title with optional
/// sub-label, and a trailing chevron for rows that deep-link into a tool/guide.
struct ChecklistRow: View {
    let titleKey: LocalizedStringKey
    var subtitleKey: LocalizedStringKey?
    var isDone: Bool = false
    /// Show the trailing chevron (the row navigates somewhere).
    var showsDisclosure: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                checkbox
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(titleKey)
                        .appText(.bodyEmphasis)
                        .foregroundStyle(AppColor.ink)
                        .strikethrough(isDone, color: AppColor.inkFaint)
                    if let subtitleKey {
                        Text(subtitleKey)
                            .appText(.label)
                            .foregroundStyle(AppColor.inkSoft)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityAddTraits(isDone ? [.isButton, .isSelected] : .isButton)
    }

    private var checkbox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppSpacing.xs, style: .continuous)
                .strokeBorder(isDone ? AppColor.primary : AppColor.line, lineWidth: 2.4)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.xs, style: .continuous)
                        .fill(isDone ? AppColor.primary : .clear))
                .frame(width: 24, height: 24)
            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(AppColor.onPrimary)
            }
        }
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        VStack(spacing: AppSpacing.xs) {
            ChecklistRow(
                titleKey: "Anmeldung (register your address)",
                subtitleKey: "Within 14 days of moving in")
            ChecklistRow(
                titleKey: "Open a bank account",
                subtitleKey: "Done", isDone: true)
        }
        .padding()
    }
    .appFontDesign()
}
