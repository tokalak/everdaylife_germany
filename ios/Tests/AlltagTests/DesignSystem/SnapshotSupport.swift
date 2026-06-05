import SwiftUI
import UIKit
import XCTest
@testable import Alltag

/// Lightweight snapshot support for the component library (P1-02).
///
/// Rather than pull in a third-party snapshot framework and commit reference
/// images (fragile across machines/Xcode versions, and A-03 keeps dependencies
/// out), we render each component with `ImageRenderer` across the trait
/// combinations the design system must survive — light/dark, Dynamic Type
/// accessibility sizes, and RTL (A-06) — and assert it produces a **non-blank,
/// correctly-sized** bitmap. This catches layout crashes, constraint failures
/// and accidentally-invisible content without brittle pixel baselines.
enum SnapshotSupport {

    /// The trait axes every component is exercised against.
    struct Trait: CustomStringConvertible {
        let colorScheme: ColorScheme
        let dynamicType: DynamicTypeSize
        let layoutDirection: LayoutDirection

        var description: String {
            "\(colorScheme)/\(dynamicType)/\(layoutDirection)"
        }

        static let matrix: [Trait] = [
            Trait(colorScheme: .light, dynamicType: .large, layoutDirection: .leftToRight),
            Trait(colorScheme: .dark, dynamicType: .large, layoutDirection: .leftToRight),
            // A-06: Dynamic Type XXL / accessibility sizing.
            Trait(colorScheme: .light, dynamicType: .accessibility3, layoutDirection: .leftToRight),
            // A-06 / X-02: right-to-left mirroring.
            Trait(colorScheme: .light, dynamicType: .large, layoutDirection: .rightToLeft),
        ]
    }

    /// Renders `view` at the given width under `trait` and returns the bitmap.
    @MainActor
    static func render<V: View>(
        _ view: V, width: CGFloat = 320, trait: Trait
    ) -> UIImage? {
        let content = view
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .background(AppColor.paper)
            .environment(\.colorScheme, trait.colorScheme)
            .environment(\.dynamicTypeSize, trait.dynamicType)
            .environment(\.layoutDirection, trait.layoutDirection)
            .appFontDesign()

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        renderer.scale = 2
        return renderer.uiImage
    }

    /// True if the bitmap is non-empty and not a single uniform color
    /// (i.e. something actually drew).
    static func isNonBlank(_ image: UIImage) -> Bool {
        guard let cg = image.cgImage, cg.width > 0, cg.height > 0 else { return false }
        let width = cg.width, height = cg.height
        let bytesPerRow = width * 4
        var data = [UInt8](repeating: 0, count: bytesPerRow * height)
        guard let ctx = CGContext(
            data: &data, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return false }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        let first = data[0..<4]
        for i in stride(from: 4, to: data.count, by: 4) where data[i..<(i + 4)] != first {
            return true
        }
        return false
    }

    /// Asserts `view` renders to a non-blank, correctly-sized bitmap across the
    /// whole trait matrix.
    @MainActor
    static func assertRenders<V: View>(
        _ view: @autoclosure () -> V,
        width: CGFloat = 320,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        for trait in Trait.matrix {
            guard let image = render(view(), width: width, trait: trait) else {
                XCTFail("nil render for trait \(trait)", file: file, line: line)
                continue
            }
            XCTAssertGreaterThan(
                image.size.width, 0,
                "zero-width render for trait \(trait)", file: file, line: line)
            XCTAssertTrue(
                isNonBlank(image),
                "blank render for trait \(trait)", file: file, line: line)
        }
    }
}
