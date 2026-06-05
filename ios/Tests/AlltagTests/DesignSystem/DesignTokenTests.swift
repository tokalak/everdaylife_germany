import SwiftUI
import XCTest
@testable import Alltag

/// Value-level tests for the design tokens (P1-01 / DS-01…03). These are pure
/// and deterministic — no rendering — so they pin the scales and the severity
/// mapping against accidental change.
final class DesignTokenTests: XCTestCase {

    // MARK: Radii (DS-03)

    func testRadiiMatchPrototypeAndAreOrdered() {
        XCTAssertEqual(AppRadius.sm, 14)
        XCTAssertEqual(AppRadius.md, 20)
        XCTAssertEqual(AppRadius.lg, 26)
        XCTAssertLessThan(AppRadius.sm, AppRadius.md)
        XCTAssertLessThan(AppRadius.md, AppRadius.lg)
        XCTAssertGreaterThan(AppRadius.pill, AppRadius.lg)
    }

    // MARK: Spacing (DS-03)

    func testSpacingScaleIsStrictlyIncreasing() {
        let scale: [CGFloat] = [
            AppSpacing.xxxs, AppSpacing.xxs, AppSpacing.xs, AppSpacing.sm,
            AppSpacing.md, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
            AppSpacing.xxxl,
        ]
        for (a, b) in zip(scale, scale.dropFirst()) {
            XCTAssertLessThan(a, b, "spacing scale must be strictly increasing")
        }
        XCTAssertEqual(AppSpacing.md, 16, "default content padding is 16")
    }

    // MARK: Shadows (DS-03)

    func testEveryShadowLevelHasLayers() {
        XCTAssertEqual(AppShadow.allCases.count, 3)
        for level in AppShadow.allCases {
            XCTAssertFalse(
                level.layers.isEmpty, "\(level) must define at least one layer")
        }
    }

    // MARK: Severity system (DS-01)

    func testSeverityHasFourDistinctLevels() {
        XCTAssertEqual(Severity.allCases.count, 4)
        XCTAssertEqual(
            Severity.allCases.map(\.rawValue),
            ["info", "action", "urgent", "legal"])
    }

    func testSeveritySymbolsAreDistinct() {
        let symbols = Severity.allCases.map(\.symbol)
        XCTAssertEqual(Set(symbols).count, symbols.count, "each severity needs its own symbol")
    }
}
