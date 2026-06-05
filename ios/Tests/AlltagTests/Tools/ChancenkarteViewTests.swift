import SwiftUI
import XCTest
@testable import Alltag

/// Chancenkarte points calculator screen (P6-W3): render-smoke across the trait
/// matrix for a qualifying score, a below-threshold score, and the direct
/// full-recognition path (A-06).
@MainActor
final class ChancenkarteViewTests: XCTestCase {

    func testRendersQualifying() {
        SnapshotSupport.assertRenders(
            ChancenkarteView(
                input: ChancenkarteInput(german: .b2, age: .under35, experience: .from2),
                embedInScrollView: false),
            height: 1600)
    }

    func testRendersBelowThreshold() {
        SnapshotSupport.assertRenders(
            ChancenkarteView(input: ChancenkarteInput(), embedInScrollView: false),
            height: 1600)
    }

    func testRendersDirectRecognition() {
        SnapshotSupport.assertRenders(
            ChancenkarteView(
                input: ChancenkarteInput(hasFullRecognition: true),
                embedInScrollView: false),
            height: 800)
    }
}
