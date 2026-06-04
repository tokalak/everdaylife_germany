import SwiftUI
import XCTest
@testable import Alltag

/// A-12…A-14: language model, RTL, and the selectable-set policy.
final class AppLanguageTests: XCTestCase {
    func testShipsTheNineV1Languages() {
        XCTAssertEqual(
            Set(AppLanguage.allCases.map(\.rawValue)),
            ["de", "en", "tr", "fr", "es", "it", "ar", "ru", "zh"])
    }

    func testGermanIsDefault() {
        XCTAssertEqual(AppLanguage.default, .de)
    }

    func testOnlyGermanAndEnglishAreSelectableNow() {
        XCTAssertEqual(AppLanguage.selectable, [.de, .en])
        XCTAssertTrue(AppLanguage.de.isSelectable)
        XCTAssertTrue(AppLanguage.en.isSelectable)
        XCTAssertFalse(AppLanguage.ar.isSelectable)
    }

    func testOnlyArabicIsRTL() {
        for language in AppLanguage.allCases {
            XCTAssertEqual(
                language.isRTL, language == .ar,
                "\(language.rawValue) RTL classification")
            XCTAssertEqual(
                language.layoutDirection,
                language == .ar ? .rightToLeft : .leftToRight)
        }
    }

    func testEveryLanguageHasAnEndonym() {
        for language in AppLanguage.allCases {
            XCTAssertFalse(language.endonym.isEmpty)
        }
    }
}
