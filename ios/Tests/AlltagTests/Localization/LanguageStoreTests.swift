import SwiftUI
import XCTest
@testable import Alltag

@MainActor
final class LanguageStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "alltag.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsToGerman() {
        let store = LanguageStore(defaults: defaults)
        XCTAssertEqual(store.language, .de)
        XCTAssertEqual(store.decoderOutputLanguage, .de) // A-15
    }

    func testSelectingEnglishPersistsAcrossInstances() {
        LanguageStore(defaults: defaults).select(.en)
        let reopened = LanguageStore(defaults: defaults)
        XCTAssertEqual(reopened.language, .en)
        XCTAssertEqual(reopened.locale.identifier, "en")
    }

    func testSelectingNonSelectableLanguageIsIgnored() {
        let store = LanguageStore(defaults: defaults)
        store.select(.ar) // not enabled until Phase 8
        XCTAssertEqual(store.language, .de)
    }

    func testLayoutDirectionFollowsLanguage() {
        let store = LanguageStore(defaults: defaults)
        XCTAssertEqual(store.layoutDirection, .leftToRight)
        // Arabic is non-selectable today, so direction stays LTR — verifying the
        // guard holds end-to-end. (Arabic RTL itself is covered in AppLanguageTests.)
        store.select(.ar)
        XCTAssertEqual(store.layoutDirection, .leftToRight)
    }

    func testDecoderOutputLanguageFollowsSelection() {
        let store = LanguageStore(defaults: defaults)
        store.select(.en)
        XCTAssertEqual(store.decoderOutputLanguage, .en)
    }
}
