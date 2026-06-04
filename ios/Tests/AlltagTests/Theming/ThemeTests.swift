import SwiftUI
import XCTest
@testable import Alltag

@MainActor
final class ThemeTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "alltag.tests.theme.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testColorSchemeMapping() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }

    func testDefaultsToSystem() {
        XCTAssertEqual(ThemeController(defaults: defaults).theme, .system)
    }

    func testSelectionPersistsAcrossInstances() {
        ThemeController(defaults: defaults).select(.dark)
        XCTAssertEqual(ThemeController(defaults: defaults).theme, .dark)
    }
}

/// D10: the five tabs, in order, with Decode in the center.
final class AppTabTests: XCTestCase {
    func testFiveTabsInExpectedOrder() {
        XCTAssertEqual(
            AppTab.allCases, [.home, .docs, .decode, .dates, .settings])
    }

    func testDecodeIsTheCenterTab() {
        XCTAssertEqual(AppTab.allCases[AppTab.allCases.count / 2], .decode)
    }
}
