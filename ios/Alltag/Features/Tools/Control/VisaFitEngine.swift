import Foundation

/// Maps Visa-fit answers to recommended residence routes (P6-W1).
///
/// Pure, exhaustively tested logic (A-05). The first route is the best fit; any
/// following routes are sensible alternatives. Returns `[]` until the input is
/// answerable. **Information only** — the screen always carries the RDG note.
enum VisaFitEngine {

    static func routes(for input: VisaFitInput) -> [VisaFitRoute] {
        guard let goal = input.goal, input.isAnswerable else { return [] }

        switch goal {
        case .visit:
            return [route("short_stay")]
        case .study:
            return [route("study", guide: "residence_permit")]
        case .family:
            return [route("family", guide: "residence_permit")]
        case .business:
            return [route("self_employment", guide: "register_business")]

        case .job:
            // isAnswerable guarantees a qualification here; default is defensive.
            switch input.qualification ?? .none {
            case .academic:
                // Blue Card is the strongest academic route; skilled-worker is the fallback.
                return [route("blue_card", guide: "residence_permit"),
                        route("skilled_worker", guide: "residence_permit")]
            case .vocational:
                return [route("skilled_worker", guide: "residence_permit")]
            case .none:
                return [route("recognition", guide: "diploma_recognition"),
                        route("skilled_worker", guide: "residence_permit")]
            }

        case .jobSeeking:
            switch input.qualification ?? .none {
            case .academic, .vocational:
                return [route("chancenkarte", guide: "residence_permit"),
                        route("job_seeker", guide: "residence_permit")]
            case .none:
                return [route("recognition", guide: "diploma_recognition")]
            }
        }
    }

    private static func route(_ id: String, guide: String? = nil) -> VisaFitRoute {
        VisaFitRoute(id: id, guideId: guide)
    }
}
