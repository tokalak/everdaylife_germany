import SwiftUI
import UIKit

/// A thin SwiftUI wrapper over `UIActivityViewController` for the system share
/// sheet, presented via `.sheet`.
///
/// Used instead of SwiftUI's `ShareLink` so the host screens stay renderable by
/// `ImageRenderer` (our snapshot harness can't render `ShareLink`), and so the
/// same share entry point can carry richer payloads (text now; PDFs when Vault
/// export lands, P3-05). Reusable across Decoder, Vault, and Settings export.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
