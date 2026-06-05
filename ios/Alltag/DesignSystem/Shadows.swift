import SwiftUI

/// Soft elevation shadows (DS-03). Mirrors the prototype's `--shadow-sm/md/lg`.
///
/// The prototype layers two shadows (a tight contact shadow + a wide ambient
/// one). SwiftUI's `.shadow` is single-layer, so each level is expressed as a
/// composition of one or two `.shadow` passes applied through `appShadow(_:)`.
/// Shadows are warm-tinted in light mode and plain black in dark mode.
enum AppShadow: CaseIterable {
    case sm, md, lg

    struct Layer {
        let radius: CGFloat
        let y: CGFloat
        let lightOpacity: Double
        let darkOpacity: Double
    }

    var layers: [Layer] {
        switch self {
        case .sm:
            return [
                Layer(radius: 1, y: 1, lightOpacity: 0.05, darkOpacity: 0.30),
                Layer(radius: 7, y: 4, lightOpacity: 0.05, darkOpacity: 0.25),
            ]
        case .md:
            return [
                Layer(radius: 9, y: 6, lightOpacity: 0.08, darkOpacity: 0.35),
                Layer(radius: 20, y: 18, lightOpacity: 0.07, darkOpacity: 0.0),
            ]
        case .lg:
            return [
                Layer(radius: 15, y: 12, lightOpacity: 0.12, darkOpacity: 0.45),
                Layer(radius: 35, y: 30, lightOpacity: 0.12, darkOpacity: 0.0),
            ]
        }
    }
}

private struct AppShadowModifier: ViewModifier {
    let shadow: AppShadow
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        // Warm shadow tint in light mode (matches prototype rgba(60,48,30));
        // neutral black in dark mode.
        let tint: Color = scheme == .dark
            ? .black
            : Color(red: 60 / 255, green: 48 / 255, blue: 30 / 255)
        shadow.layers.reduce(AnyView(content)) { view, layer in
            let opacity = scheme == .dark ? layer.darkOpacity : layer.lightOpacity
            guard opacity > 0 else { return view }
            return AnyView(
                view.shadow(
                    color: tint.opacity(opacity),
                    radius: layer.radius, x: 0, y: layer.y))
        }
    }
}

extension View {
    /// Applies a Warm-Companion elevation shadow (DS-03).
    func appShadow(_ shadow: AppShadow) -> some View {
        modifier(AppShadowModifier(shadow: shadow))
    }
}
