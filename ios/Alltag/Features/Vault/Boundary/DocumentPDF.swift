import Foundation
import UIKit

/// Builds a single PDF from scanned page images (P3-05).
///
/// Scanned letters come back as per-page JPEGs (``DocumentScannerView``); the
/// Vault stores one PDF per document so export/share is a single, universally
/// readable file. Lives in Boundary as a UIKit/rendering edge.
enum DocumentPDF {
    /// Combine page images (JPEG/PNG bytes) into one PDF, one image per page at
    /// its natural size. Returns nil if no image decodes.
    static func make(from pages: [Data]) -> Data? {
        let images = pages.compactMap(UIImage.init(data:))
        guard !images.isEmpty else { return nil }

        let pdf = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdf, .zero, nil)
        defer { UIGraphicsEndPDFContext() }
        for image in images {
            let bounds = CGRect(origin: .zero, size: image.size)
            UIGraphicsBeginPDFPageWithInfo(bounds, nil)
            image.draw(in: bounds)
        }
        return pdf as Data
    }

    /// Render plain text into a simple A4 PDF (P3-03 "save to Vault" for a decoded
    /// letter, which has only the OCR'd text, not the original image).
    static func make(fromText text: String) -> Data? {
        guard !text.isEmpty else { return nil }
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 @72dpi
        let inset: CGFloat = 40
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black,
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            context.beginPage()
            (text as NSString).draw(
                in: pageRect.insetBy(dx: inset, dy: inset), withAttributes: attributes)
        }
    }
}
