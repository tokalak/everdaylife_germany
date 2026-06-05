import Foundation

/// Chancenkarte (Opportunity Card) points scoring (P6-W3).
///
/// Pure, exhaustively tested logic (A-05): full recognition qualifies directly;
/// otherwise sum the criterion points and compare to the threshold. Point values
/// are injected (defaulting to the current year) so the rule is independent of
/// the yearly figures. **Information only** — the screen carries the RDG note.
enum ChancenkarteEngine {

    /// Points scored from the criteria (ignores the direct-recognition path).
    static func total(
        for input: ChancenkarteInput, points: ChancenkartePoints = .current
    ) -> Int {
        var sum = 0
        sum += points.german[input.german] ?? 0
        sum += points.english[input.english] ?? 0
        sum += points.age[input.age] ?? 0
        sum += points.experience[input.experience] ?? 0
        if input.isShortageOccupation { sum += points.shortageOccupation }
        if input.hadPreviousStay { sum += points.previousStay }
        if input.partnerApplying { sum += points.partnerApplying }
        return sum
    }

    static func evaluate(
        _ input: ChancenkarteInput, points: ChancenkartePoints = .current
    ) -> ChancenkarteResult {
        if input.hasFullRecognition { return .qualifiesDirectly }

        let scored = total(for: input, points: points)
        if scored >= points.threshold {
            return .meetsThreshold(total: scored, threshold: points.threshold)
        }
        return .belowThreshold(
            total: scored, threshold: points.threshold, shortfall: points.threshold - scored)
    }
}
