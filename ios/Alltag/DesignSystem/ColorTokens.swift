import SwiftUI
import UIKit

/// Warm-Companion semantic color tokens (DS-01).
///
/// The full token set for Phase 1: surfaces, ink, brand (teal + amber), and the
/// four-level **severity system** — each severity with a matching *wash* (tinted
/// background) reused across Decoder / Dates / Vault. Values mirror the
/// prototype's CSS custom properties (`prototype/index.html`).
///
/// Colors are defined in code (not asset catalogs) as light/dark dynamic pairs
/// so the palette is reviewable in one place; they resolve automatically to the
/// active `ColorScheme` via a trait-aware `UIColor`.
enum AppColor {
    // MARK: Surfaces
    static let paper = dynamic(light: 0xFAF8F4, dark: 0x1B1916)
    /// A slightly sunk paper tone for grouped backgrounds / pressed states.
    static let paperSink = dynamic(light: 0xF1ECE3, dark: 0x262320)
    static let card = dynamic(light: 0xFFFFFF, dark: 0x252320)
    /// Hairline separators and card borders.
    static let line = dynamic(light: 0xECE6DC, dark: 0x332F2A)

    // MARK: Text / ink
    static let ink = dynamic(light: 0x2B2722, dark: 0xF2EEE6)
    static let inkSoft = dynamic(light: 0x7C756A, dark: 0xA79E91)
    static let inkFaint = dynamic(light: 0xA8A096, dark: 0x6E665B)

    // MARK: Brand
    static let primary = dynamic(light: 0x2BA39A, dark: 0x34C2B6)        // teal
    static let primaryDeep = dynamic(light: 0x1C7E76, dark: 0x62D6CA)
    static let primaryWash = dynamic(light: 0xE4F3F1, dark: 0x173734)
    /// Foreground for content placed on a `primary`-filled surface.
    static let onPrimary = dynamic(light: 0xFFFFFF, dark: 0x0C1C1A)
    static let amber = dynamic(light: 0xE8A13C, dark: 0xE8A13C)          // action
    static let amberWash = dynamic(light: 0xFBEFD9, dark: 0x3A2E18)

    // MARK: Severity system (reused across Decoder / Dates / Vault — DS-01)
    static let severityInfo = dynamic(light: 0x3F9B6B, dark: 0x4FB47E)
    static let severityInfoWash = dynamic(light: 0xE6F2EA, dark: 0x16301F)
    static let severityAction = dynamic(light: 0xE0922C, dark: 0xE0A04A)
    static let severityActionWash = dynamic(light: 0xFBEED8, dark: 0x3A2C13)
    static let severityUrgent = dynamic(light: 0xDA5746, dark: 0xE8695A)
    static let severityUrgentWash = dynamic(light: 0xFBE6E2, dark: 0x3A1E1A)
    static let severityLegal = dynamic(light: 0x6E6BD6, dark: 0x8A87E6)
    static let severityLegalWash = dynamic(light: 0xEAE9FB, dark: 0x22214A)

    // MARK: - Helpers

    static func dynamic(
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
