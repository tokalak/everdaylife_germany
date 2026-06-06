import SwiftUI

/// Pre-arrival checklist by nationality (P6-S1): pick your nationality and see
/// which of the three student entry routes applies and the ordered steps to take
/// before (and right after) arriving to study in Germany.
///
/// The route comes from the pure `StudentPrearrivalEngine`; this screen is
/// selection + presentation. Country names come from `Locale` (localized by the
/// OS), never from the catalog. Always carries the RDG note — it informs, never
/// decides.
struct StudentPrearrivalView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// Selected nationality as an ISO 3166-1 alpha-2 region code.
    @State private var regionCode: String

    /// Ids of the steps the user has ticked off. **Session-only by design:**
    /// held in `@State` and deliberately NOT persisted (no `@AppStorage`/file).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    /// Guide opened from the "learn more" link.
    private let guideId = "residence_permit"

    init(
        regionCode: String = "US",
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._regionCode = State(initialValue: regionCode)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    /// Selectable ISO 3166-1 alpha-2 codes, sorted by their localized name.
    /// (Reuses `VisaNeedView`'s list — DRY.)
    private let countries: [String] = VisaNeedView.selectableCountries()

    private var route: StudentEntryRoute { StudentPrearrivalEngine.route(for: regionCode) }
    private var steps: [PrearrivalStep] { StudentPrearrivalEngine.steps(for: route) }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_prearrival_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_prearrival_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            pickerSection
            routeBanner
            stepsSection
            learnMore
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Picker

    private var pickerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_prearrival_picker_label")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            Picker("tool_prearrival_picker_label", selection: $regionCode) {
                ForEach(countries, id: \.self) { code in
                    Text(VisaNeedView.name(for: code)).tag(code)
                }
            }
            .pickerStyle(.menu)
            .tint(AppColor.primaryDeep)
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColor.line, lineWidth: 1))
        }
    }

    // MARK: - Route banner

    private var routeBanner: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label {
                Text(LocalizedStringKey(titleKey))
            } icon: {
                Image(systemName: icon)
            }
            .appText(.cardTitle)
            .foregroundStyle(tint)

            Text(LocalizedStringKey(detailKey))
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(tint.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_prearrival_steps_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Session-only ticks (see `ticked`) — a packing-list feel, not a tracker.
            ForEach(steps) { step in
                stepRow(step)
            }
        }
    }

    private func stepRow(_ step: PrearrivalStep) -> some View {
        let isTicked = ticked.contains(step.id)
        return Button {
            if isTicked { ticked.remove(step.id) } else { ticked.insert(step.id) }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isTicked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isTicked ? AppColor.primary : AppColor.inkFaint)
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(LocalizedStringKey(step.titleKey))
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                        .strikethrough(isTicked, color: AppColor.inkSoft)
                    if let detailKey = step.detailKey {
                        Text(LocalizedStringKey(detailKey))
                            .appText(.label)
                            .foregroundStyle(AppColor.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .strokeBorder(AppColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isTicked ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Learn more

    private var learnMore: some View {
        Button { onOpenGuide(guideId) } label: {
            HStack(spacing: AppSpacing.xxs) {
                Text("tool_prearrival_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Route presentation

    private var tint: Color {
        switch route {
        case .freeMovement:            return AppColor.primary
        case .visaFreeEntryThenPermit: return AppColor.severityInfo
        case .nationalVisaRequired:    return AppColor.severityUrgent
        }
    }

    private var icon: String {
        switch route {
        case .freeMovement:            return "checkmark.seal.fill"
        case .visaFreeEntryThenPermit: return "airplane.circle.fill"
        case .nationalVisaRequired:    return "exclamationmark.triangle.fill"
        }
    }

    private var titleKey: String {
        switch route {
        case .freeMovement:            return "tool_prearrival_route_free_title"
        case .visaFreeEntryThenPermit: return "tool_prearrival_route_visafree_title"
        case .nationalVisaRequired:    return "tool_prearrival_route_visa_title"
        }
    }

    private var detailKey: String {
        switch route {
        case .freeMovement:            return "tool_prearrival_route_free_detail"
        case .visaFreeEntryThenPermit: return "tool_prearrival_route_visafree_detail"
        case .nationalVisaRequired:    return "tool_prearrival_route_visa_detail"
        }
    }
}

#Preview {
    NavigationStack { StudentPrearrivalView(regionCode: "US") }
        .appFontDesign()
}
