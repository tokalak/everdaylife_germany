import SwiftUI
import UIKit

/// Warm-Companion semantic color tokens (DS-01).
///
/// This is the *foundation* slice referenced by P0-06 — enough to theme the tab
/// shell. The full token set, components, and snapshot tests land in Phase 1
/// (P1-01/02). Values mirror the prototype.
///
/// Colors are defined in code (not asset catalogs) as light/dark dynamic pairs
/// so the palette is reviewable in one place; they resolve automatically to the
/// active `ColorScheme`.
enum AppColor {
    // Surfaces
    static let paper = dynamic(light: 0xFAF8F4, dark: 0x1B1916)
    static let card = dynamic(light: 0xFFFFFF, dark: 0x252320)

    // Text / ink
    static let ink = dynamic(light: 0x2B2722, dark: 0xF2EEE6)
    static let inkSoft = dynamic(light: 0x6B6259, dark: 0xB8AFA3)
    static let inkFaint = dynamic(light: 0x9C9286, dark: 0x9C9286, lightAlpha: 0.6)

    // Brand
    static let primary = dynamic(light: 0x2BA39A, dark: 0x35B6AC)       // teal
    static let primaryDeep = dynamic(light: 0x1C7E76, dark: 0x2BA39A)
    static let amber = dynamic(light: 0xE8A13C, dark: 0xF0B055)         // action

    // Severity system (reused across Decoder / Dates / Vault — DS-01)
    static let severityInfo = dynamic(light: 0x2F9E6F, dark: 0x46B889)
    static let severityAction = dynamic(light: 0xE8A13C, dark: 0xF0B055)
    static let severityUrgent = dynamic(light: 0xD2553E, dark: 0xE8765E)
    static let severityLegal = dynamic(light: 0x4C5BC4, dark: 0x6E7CE0)

    // MARK: - Helpers

    private static func dynamic(
        light: Int, dark: Int, lightAlpha: Double = 1
    ) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(rgb: dark)
                : UIColor(rgb: light, alpha: lightAlpha)
        })
    }
}

private extension UIColor {
    /// Builds a color from a 0xRRGGBB integer.
    convenience init(rgb: Int, alpha: Double = 1) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: CGFloat(alpha))
    }
}
