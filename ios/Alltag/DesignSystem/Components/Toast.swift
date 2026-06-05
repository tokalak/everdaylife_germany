import SwiftUI

/// A transient confirmation message (DS-04): a dark rounded pill that slides up
/// from the bottom, then auto-dismisses. Present it with `.appToast(...)`.
struct Toast: View {
    let messageKey: LocalizedStringKey
    var systemImage: String = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: systemImage)
                .imageScale(.small)
            Text(messageKey)
                .appText(.label)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.ink.opacity(0.92), in: Capsule())
        .appShadow(.lg)
        .accessibilityElement(children: .combine)
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let messageKey: LocalizedStringKey
    var systemImage: String
    var duration: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if isPresented {
                Toast(messageKey: messageKey, systemImage: systemImage)
                    .padding(.bottom, AppSpacing.xxxl)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(duration))
                        withAnimation(.easeOut(duration: 0.25)) { isPresented = false }
                    }
            }
        }
        .animation(.snappy(duration: 0.3), value: isPresented)
    }
}

extension View {
    /// Presents an auto-dismissing toast above this view (DS-04).
    func appToast(
        isPresented: Binding<Bool>,
        _ messageKey: LocalizedStringKey,
        systemImage: String = "checkmark.circle.fill",
        duration: Double = 2.2
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented, messageKey: messageKey,
            systemImage: systemImage, duration: duration))
    }
}

#Preview {
    struct Demo: View {
        @State private var show = true
        var body: some View {
            ZStack {
                AppColor.paper.ignoresSafeArea()
                Button("Show toast") { show = true }
                    .buttonStyle(.secondary)
                    .padding()
            }
            .appToast(isPresented: $show, "Added to your calendar")
            .appFontDesign()
        }
    }
    return Demo()
}
