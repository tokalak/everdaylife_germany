import Foundation
import Observation
import SwiftUI

/// Holds and persists the user's chosen app language, and exposes the derived
/// `Locale` / `LayoutDirection` that the root view applies (A-12…A-15).
///
/// Selecting a language drives:
/// - UI strings, via `.environment(\.locale)` on the root (String Catalog).
/// - RTL mirroring, via `.environment(\.layoutDirection)` (A-14).
/// - Decoder output language (A-15) through `decoderOutputLanguage`.
@MainActor
@Observable
final class LanguageStore {
    private static let storageKey = "alltag.language"

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var language: AppLanguage

    /// - Parameter defaults: injected so tests use an isolated suite.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Self.storageKey),
           let stored = AppLanguage(rawValue: raw) {
            language = stored
        } else {
            language = .default
        }
    }

    /// Selects a language. Guards against enabling not-yet-localized languages
    /// (everything outside `AppLanguage.selectable`) so we never strand the UI
    /// in an untranslated locale before Phase 8.
    func select(_ language: AppLanguage) {
        guard language.isSelectable else { return }
        self.language = language
        defaults.set(language.rawValue, forKey: Self.storageKey)
    }

    var locale: Locale { language.locale }

    var layoutDirection: LayoutDirection { language.layoutDirection }

    /// The language the Decoder should produce its explanation in (A-15) — it
    /// follows the app language.
    var decoderOutputLanguage: AppLanguage { language }
}
