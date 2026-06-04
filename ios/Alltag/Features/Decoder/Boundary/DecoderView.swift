import SwiftUI

/// Decode tab placeholder (P0-06) — the center anchor of the app. The capture →
/// on-device explain → result flow lands in P3-00…P3-04 on local Gemma.
struct DecoderView: View {
    var body: some View {
        PlaceholderScreen(titleKey: "tab_decode", systemImage: "doc.text.viewfinder")
    }
}
