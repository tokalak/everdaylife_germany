import CoreGraphics

/// Spacing scale (DS-03) on a 4-pt grid.
///
/// Use these instead of literal paddings so rhythm stays consistent across
/// screens and is tunable in one place.
enum AppSpacing {
    /// 2 — hairline gaps (e.g. label/sub-label).
    static let xxxs: CGFloat = 2
    /// 4
    static let xxs: CGFloat = 4
    /// 8
    static let xs: CGFloat = 8
    /// 12
    static let sm: CGFloat = 12
    /// 16 — default content padding.
    static let md: CGFloat = 16
    /// 20
    static let lg: CGFloat = 20
    /// 24 — section gaps.
    static let xl: CGFloat = 24
    /// 32
    static let xxl: CGFloat = 32
    /// 40
    static let xxxl: CGFloat = 40
}
