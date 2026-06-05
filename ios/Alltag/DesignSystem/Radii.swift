import CoreGraphics

/// Corner-radius scale (DS-03). Mirrors the prototype's `--r-lg/md/sm`.
enum AppRadius {
    /// 14 — pills' siblings, small tiles, inner chips.
    static let sm: CGFloat = 14
    /// 20 — default card / row radius.
    static let md: CGFloat = 20
    /// 26 — hero cards (e.g. "Up next").
    static let lg: CGFloat = 26
    /// A large value that renders as a fully-rounded capsule on any height.
    static let pill: CGFloat = 999
}
