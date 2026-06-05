import SwiftUI

/// A styled container for content presented in a bottom sheet (DS-04): a grabber
/// handle on the Warm-Companion paper surface with rounded top corners.
///
/// Use it inside SwiftUI's `.sheet`, paired with `.appBottomSheet(...)` which
/// applies sensible detents and the paper background.
struct BottomSheetContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Capsule()
                .fill(AppColor.inkFaint.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, AppSpacing.sm)
            content
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.bottom, AppSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

private struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    @ViewBuilder let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            BottomSheetContainer(content: { sheetContent() })
                .presentationDetents(detents)
                .presentationDragIndicator(.hidden)
                .presentationBackground(AppColor.paper)
                .presentationCornerRadius(AppRadius.lg + 2)
        }
    }
}

extension View {
    /// Presents `content` in a Warm-Companion bottom sheet (DS-04).
    func appBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium],
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(BottomSheetModifier(
            isPresented: isPresented, detents: detents, sheetContent: content))
    }
}

#Preview {
    struct Demo: View {
        @State private var show = false
        var body: some View {
            ZStack {
                AppColor.paper.ignoresSafeArea()
                Button("Open sheet") { show = true }
                    .buttonStyle(.primary)
                    .padding()
            }
            .appBottomSheet(isPresented: $show) {
                VStack(spacing: AppSpacing.md) {
                    Text("Add to calendar?")
                        .appText(.sectionHeader)
                        .foregroundStyle(AppColor.ink)
                    PrimaryButton(titleKey: "Add reminder") { show = false }
                }
            }
            .appFontDesign()
        }
    }
    return Demo()
}
