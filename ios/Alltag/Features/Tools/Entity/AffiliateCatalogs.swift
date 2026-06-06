import Foundation

/// Central registry of every affiliate comparison catalog (P6-A1, brief §7).
///
/// All comparison tools that show an affiliate-linked, ranked list register their
/// versioned `ComparisonCatalog` here. This is the single source of truth that
/// lets one compliance test (`AffiliateComplianceTests`) enforce the §7
/// invariants — **always 3+ ranked options, transparently disclosed, affiliate
/// links are real https URLs** — across all current *and* future comparison
/// tools. Adding a new comparison tool means adding one line here, and the
/// transparency guarantee is automatically extended to it.
enum AffiliateCatalogs {

    /// `(name, catalog)` for every registered affiliate comparison tool.
    static let all: [(name: String, catalog: ComparisonCatalog)] = [
        ("bank", BankCompareCatalog.current),
        ("travel", TravelInsuranceCatalog.current),
        ("blocked", BlockedAccountCatalog.current),
        ("studenthealth", StudentHealthCatalog.current),
        ("health_insurers", HealthInsurerCatalog.current),
    ]
}
