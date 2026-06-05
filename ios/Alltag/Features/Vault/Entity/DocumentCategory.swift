import Foundation

/// How a Vault document is filed (P3-05). Kept small and concrete — these are
/// the buckets a newcomer's paperwork actually falls into. Stored as the raw
/// string on `DocumentRecord.category`; see the typed accessor extension.
enum DocumentCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case identity    // passport, ID card, residence permit, visa
    case official    // Behörden letters, decoded letters, certificates
    case finance     // bank, tax, payslips
    case insurance   // health/liability/etc. policies
    case housing     // Anmeldung, rental contract, utilities
    case other

    var id: String { rawValue }

    /// Localized label key.
    var titleKey: String {
        switch self {
        case .identity:  "doc_category_identity"
        case .official:  "doc_category_official"
        case .finance:   "doc_category_finance"
        case .insurance: "doc_category_insurance"
        case .housing:   "doc_category_housing"
        case .other:     "doc_category_other"
        }
    }

    var systemImage: String {
        switch self {
        case .identity:  "person.text.rectangle"
        case .official:  "building.columns"
        case .finance:   "banknote"
        case .insurance: "cross.case"
        case .housing:   "house"
        case .other:     "doc"
        }
    }
}

/// Typed category over `DocumentRecord`'s raw string. In an extension (the
/// `@Model` macro scans only the primary declaration) so persistence stays on
/// the existing `category: String`.
extension DocumentRecord {
    var categoryValue: DocumentCategory {
        get { DocumentCategory(rawValue: category) ?? .other }
        set { category = newValue.rawValue }
    }

    /// Days until expiry (nil if no expiry); negative once expired.
    func daysUntilExpiry(from now: Date = .now, calendar: Calendar = .current) -> Int? {
        guard let expiresAt else { return nil }
        return calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: expiresAt)).day
    }
}
