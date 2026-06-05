import SwiftUI

/// Visa-need decision tool (P6-T1): pick your nationality and see whether you
/// need a Schengen visa for a short stay (≤90 days) in Germany.
///
/// The verdict comes from the pure `VisaNeedEngine`; this screen is selection +
/// presentation. Country names come from `Locale` (localized by the OS), never
/// from the catalog. Always carries the RDG note — it informs, never decides.
struct VisaNeedView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// Selected nationality as an ISO 3166-1 alpha-2 region code.
    @State private var regionCode: String
    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

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
    private let countries: [String] = VisaNeedView.selectableCountries()

    private var result: VisaNeedResult { VisaNeedEngine.result(for: regionCode) }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_visa_need_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_visaneed_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            pickerSection
            resultCard

            Button { onOpenGuide("residence_permit") } label: {
                HStack(spacing: AppSpacing.xxs) {
                    Text("tool_visaneed_longer_stay")
                    Image(systemName: "chevron.forward").imageScale(.small)
                }
                .appText(.label)
                .foregroundStyle(AppColor.primaryDeep)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Picker

    private var pickerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_visaneed_picker_label")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            Picker("tool_visaneed_picker_label", selection: $regionCode) {
                ForEach(countries, id: \.self) { code in
                    Text(Self.name(for: code)).tag(code)
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

    // MARK: - Result

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label {
                Text(LocalizedStringKey(titleKey))
            } icon: {
                Image(systemName: icon)
            }
            .appText(.cardTitle)
            .foregroundStyle(tint)

            Text(rationale)
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let note {
                Text(LocalizedStringKey(note))
                    .appText(.label)
                    .foregroundStyle(AppColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppSpacing.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(tint.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    /// The localized rationale, with the selected country's localized name.
    private var rationale: String {
        String(format: String(localized: String.LocalizationValue(rationaleKey)),
               Self.name(for: regionCode))
    }

    // MARK: - Result presentation

    private var tint: Color {
        switch result {
        case .freeMovement:     return AppColor.primary
        case .visaFreeShortStay: return AppColor.severityInfo
        case .visaRequired:     return AppColor.severityUrgent
        }
    }

    private var icon: String {
        switch result {
        case .freeMovement:     return "checkmark.seal.fill"
        case .visaFreeShortStay: return "airplane.circle.fill"
        case .visaRequired:     return "exclamationmark.triangle.fill"
        }
    }

    private var titleKey: String {
        switch result {
        case .freeMovement:     return "tool_visaneed_free_title"
        case .visaFreeShortStay: return "tool_visaneed_visafree_title"
        case .visaRequired:     return "tool_visaneed_required_title"
        }
    }

    private var rationaleKey: String {
        switch result {
        case .freeMovement:     return "tool_visaneed_free_detail"
        case .visaFreeShortStay: return "tool_visaneed_visafree_detail"
        case .visaRequired:     return "tool_visaneed_required_detail"
        }
    }

    /// The extra reminder shown under the rationale (90-in-180 + ETIAS for
    /// visa-free; verify-with-Auswärtiges-Amt for visa-required).
    private var note: String? {
        switch result {
        case .freeMovement:     return nil
        case .visaFreeShortStay: return "tool_visaneed_etias_note"
        case .visaRequired:     return "tool_visaneed_verify_note"
        }
    }

    // MARK: - Country list

    /// All selectable 2-letter ISO region codes, sorted by localized name.
    static func selectableCountries() -> [String] {
        let codes = Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) }
            .filter { Locale.current.localizedString(forRegionCode: $0) != nil }
        return Array(Set(codes)).sorted { name(for: $0) < name(for: $1) }
    }

    static func name(for code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }
}

#Preview {
    NavigationStack { VisaNeedView(regionCode: "US") }
        .appFontDesign()
}
