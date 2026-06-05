import Foundation

/// Ranking + filtering for the bank-account comparison (P6-W4).
///
/// Pure, tested logic (A-05). The catalog is injected (defaulting to the current
/// one) so the rule is independent of the often-changing provider list. The
/// P6-A1 invariant — **always 3+ ranked options, transparently** — is enforced
/// here: filtering never drops the result below `minimumOptions`; if a filter
/// would, it is ignored and the full ranked list is returned. **Information
/// only** — the screen carries the RDG note and the affiliate disclosure.
enum BankCompareEngine {

    /// The transparency invariant from P6-A1.
    static let minimumOptions = 3

    /// The ranked options to show. When `englishSupportOnly` is set, options
    /// without English support are dropped — unless that would leave fewer than
    /// `minimumOptions`, in which case the full ranked list is returned so the
    /// transparency invariant always holds.
    static func rankedOptions(
        from catalog: ComparisonCatalog = BankCompareCatalog.current,
        englishSupportOnly: Bool = false
    ) -> [ComparisonOption] {
        let ranked = catalog.options
        guard englishSupportOnly else { return ranked }

        let filtered = ranked.filter(\.englishSupport)
        return filtered.count >= minimumOptions ? filtered : ranked
    }
}
