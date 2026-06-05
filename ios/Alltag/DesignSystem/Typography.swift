import SwiftUI

/// Warm-Companion typography (DS-02).
///
/// The design uses SF Pro **Rounded** with heavy display weights. We never
/// hard-code point sizes — every style is built from a *relative* system text
/// style (`.title`, `.body`, …) so it scales with **Dynamic Type**, then given a
/// rounded design and a weight. Applying `.appFontDesign()` once at the root
/// cascades the rounded design; the `AppText` styles below add the matching
/// weight per role.
enum AppText {
    case display        // big greeting / hero numbers
    case title          // screen titles
    case sectionHeader  // "Up next", "Your checklist"
    case cardTitle      // emphasis inside a card/row
    case body           // default reading text
    case bodyEmphasis   // emphasized body
    case callout        // secondary supporting text
    case label          // dense labels / sub-labels
    case caption        // smallest meta / timestamps
    case pill           // uppercase chip / tab labels

    var font: Font {
        switch self {
        case .display:       return .system(.largeTitle, design: .rounded).weight(.black)
        case .title:         return .system(.title, design: .rounded).weight(.bold)
        case .sectionHeader: return .system(.headline, design: .rounded).weight(.heavy)
        case .cardTitle:     return .system(.callout, design: .rounded).weight(.bold)
        case .body:          return .system(.body, design: .rounded).weight(.medium)
        case .bodyEmphasis:  return .system(.body, design: .rounded).weight(.semibold)
        case .callout:       return .system(.subheadline, design: .rounded).weight(.medium)
        case .label:         return .system(.footnote, design: .rounded).weight(.bold)
        case .caption:       return .system(.caption, design: .rounded).weight(.semibold)
        case .pill:          return .system(.caption2, design: .rounded).weight(.heavy)
        }
    }
}

extension View {
    /// Applies the app's rounded type design to this subtree (root-level use).
    func appFontDesign() -> some View {
        fontDesign(.rounded)
    }

    /// Applies a semantic `AppText` style (font + weight). Dynamic Type aware.
    func appText(_ style: AppText) -> some View {
        font(style.font)
    }
}

extension Text {
    /// Convenience for styling a `Text` with an `AppText` role.
    func appText(_ style: AppText) -> Text {
        font(style.font)
    }
}
