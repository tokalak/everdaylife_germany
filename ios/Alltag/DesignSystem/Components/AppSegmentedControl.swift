import SwiftUI

/// A Warm-Companion segmented control (DS-04).
///
/// Generic over any `Hashable` option set. The selected segment slides a teal
/// "thumb" behind it (animated, reduced-motion safe via SwiftUI's implicit
/// animation honoring the system setting). Used for Appearance and other small
/// either/or choices.
struct AppSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> LocalizedStringKey
    @Namespace private var thumb

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.snappy(duration: 0.25)) { selection = option }
                } label: {
                    Text(label(option))
                        .appText(.label)
                        .foregroundStyle(isSelected ? AppColor.onPrimary : AppColor.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.xs + 2)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(AppColor.primary)
                                    .matchedGeometryEffect(id: "thumb", in: thumb)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(AppColor.paperSink, in: Capsule())
    }
}

#Preview {
    struct Demo: View {
        @State private var value = "System"
        var body: some View {
            ZStack {
                AppColor.paper.ignoresSafeArea()
                AppSegmentedControl(
                    options: ["System", "Light", "Dark"],
                    selection: $value,
                    label: { LocalizedStringKey($0) })
                .padding()
            }
            .appFontDesign()
        }
    }
    return Demo()
}
