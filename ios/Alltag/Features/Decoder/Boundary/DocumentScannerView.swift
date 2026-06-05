import SwiftUI
import VisionKit
import UIKit

/// Wraps `VNDocumentCameraViewController` so a captured letter becomes page
/// images for OCR (P3-01).
///
/// VisionKit gives us edge detection, perspective correction, and multi-page
/// capture for free — far better source images for OCR than a raw camera frame.
/// Scanned pages are handed back as JPEG `Data` (the same currency the Vault's
/// `EncryptedFileStore` speaks), or the flow is cancelled.
///
/// `VNDocumentCameraViewController.isSupported` is `false` on the Simulator and
/// camera-less devices; callers check ``isSupported`` and offer an alternative
/// (e.g. pick-from-library) instead of presenting this.
struct DocumentScannerView: UIViewControllerRepresentable {
    /// Called with the captured pages (JPEG bytes), in scan order.
    var onScan: ([Data]) -> Void
    /// Called when the user cancels or scanning fails.
    var onCancel: () -> Void

    static var isSupported: Bool { VNDocumentCameraViewController.isSupported }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) { self.parent = parent }

        // VisionKit invokes these delegate callbacks on the main queue; assert
        // that isolation so the main-actor-isolated closures can be called.
        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var pages: [Data] = []
            for index in 0..<scan.pageCount {
                if let data = scan.imageOfPage(at: index).jpegData(compressionQuality: 0.85) {
                    pages.append(data)
                }
            }
            MainActor.assumeIsolated { parent.onScan(pages) }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            MainActor.assumeIsolated { parent.onCancel() }
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            MainActor.assumeIsolated { parent.onCancel() }
        }
    }
}
