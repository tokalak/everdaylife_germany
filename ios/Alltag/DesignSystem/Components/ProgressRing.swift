import SwiftUI

/// A circular progress ring with a centered percentage (DS — Home greeting,
/// P4-02). Mirrors the prototype's teal ring on the warm-paper track.
///
/// Pure presentation: pass a `fraction` in 0…1. The percentage uses
/// `.appText` so it scales with Dynamic Type, and the ring itself is
/// direction-agnostic (no leading/trailing), so it is RTL-safe. The fill is
/// drawn without an implicit animation so it renders deterministically in
/// snapshots and respects reduced-motion.
struct ProgressRing: View {
    /// Completion in 0…1 (clamped).
    let fraction: Double
    var size: CGFloat = 60
    var lineWidth: CGFloat = 7

    private var clamped: Double { min(max(fraction, 0), 1) }
    private var percent: Int { Int((clamped * 100).rounded()) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.line, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AppColor.primary,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(percent)%")
                .appText(.label)
                .foregroundStyle(AppColor.ink)
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(Text("home_progress_label"))
        .accessibilityValue(Text("\(percent)%"))
    }
}

#Preview {
    ZStack {
        AppColor.paper.ignoresSafeArea()
        HStack(spacing: AppSpacing.lg) {
            ProgressRing(fraction: 0)
            ProgressRing(fraction: 0.36)
            ProgressRing(fraction: 1)
        }
    }
    .appFontDesign()
}
