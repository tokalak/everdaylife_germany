import SwiftUI

/// In-app search across the guides and the active persona's tools (P6-G6).
///
/// The index (`items`) is built from the catalog; matching (`filter`) is pure
/// and takes an injected `localize` so it can be tested without the string
/// catalog or a locale. Guides are cross-persona; tools are the active mode's.
@MainActor
enum HomeSearch {

    /// Everything searchable for a persona: all cross-persona guides plus that
    /// persona's tools (none if no mode is active yet).
    static func items(for persona: Persona?) -> [SearchItem] {
        let guides = PersonaCatalog.guides.map {
            SearchItem(kind: .guide, targetId: $0.id, titleKey: $0.titleKey,
                       subtitleKey: $0.subtitleKey, systemImage: $0.systemImage, tint: $0.tint)
        }
        let tools = (persona.map(PersonaCatalog.tools(for:)) ?? []).map {
            SearchItem(kind: .tool, targetId: $0.id, titleKey: $0.titleKey,
                       subtitleKey: $0.subtitleKey, systemImage: $0.systemImage, tint: $0.tint)
        }
        return guides + tools
    }

    /// Items whose title or subtitle contains `query`, case- and
    /// diacritic-insensitive. A blank query returns everything (browse mode).
    static func filter(
        _ items: [SearchItem], query: String, localize: (String) -> String
    ) -> [SearchItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }
        return items.filter { item in
            let haystacks = [localize(item.titleKey), item.subtitleKey.map(localize) ?? ""]
            return haystacks.contains {
                $0.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }
    }

    /// Resolves a String-Catalog key to display text in the given locale.
    static func resolve(_ key: String, locale: Locale) -> String {
        String(localized: String.LocalizationValue(key), locale: locale)
    }
}
