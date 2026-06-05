import SwiftUI
import XCTest
@testable import Alltag

/// Guide reader (P6-G6): render-smoke across the trait matrix (light/dark ·
/// Dynamic Type accessibility · RTL) for every shipped guide — proves the
/// section/bullet/source layout survives long German copy and mirroring (A-06).
@MainActor
final class GuideReaderViewTests: XCTestCase {

    func testEveryGuideRenders() {
        for guide in GuideLibrary.all {
            SnapshotSupport.assertRenders(
                GuideReaderView(content: guide, embedInScrollView: false),
                height: 2200)
        }
    }
}
