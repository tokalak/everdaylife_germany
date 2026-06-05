import Foundation

/// GKV vs PKV decision tree (P6-W5).
///
/// Pure, tested logic (A-05): map (status, income) → a neutral, informational
/// recommendation. The compulsory-insurance threshold
/// (Jahresarbeitsentgeltgrenze) is injected (defaulting to the current year) so
/// the rule is independent of the yearly figure. **Information only** — the
/// screen carries the RDG note and the affiliate disclosure.
enum HealthDecisionEngine {

    /// The recommendation for this input.
    ///
    /// - employee at/below the threshold → `.mustBeGKV`
    /// - employee above the threshold → `.gkvOrPkvChoice`
    /// - self-employed / civil servant → `.gkvOrPkvChoice`
    /// - student → `.studentGKV`
    /// - other → `.dependsOnCase`
    static func recommendation(
        for input: HealthDecisionInput,
        threshold: HealthInsuranceThreshold = .current
    ) -> HealthRecommendation? {
        guard let status = input.status else { return nil }
        switch status {
        case .employee:
            return input.grossAnnualIncome > threshold.compulsoryInsuranceLimit
                ? .gkvOrPkvChoice
                : .mustBeGKV
        case .selfEmployed, .civilServant:
            return .gkvOrPkvChoice
        case .student:
            return .studentGKV
        case .other:
            return .dependsOnCase
        }
    }
}
