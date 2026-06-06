import SwiftUI

/// Kindergeld (child benefit) application guide (P6-F5): a plain-language how-to
/// for claiming the monthly child-benefit payment from the Familienkasse — what
/// Kindergeld is and who can claim it, how much per child, where and how to
/// apply, when it is paid — followed by the documents to gather and the ordered
/// application steps.
///
/// The current monthly amount per child comes from the versioned
/// `KindergeldRate`; the rest of the content comes from `KindergeldContent`.
/// This screen is presentation only and carries the standard RDG note —
/// entitlement depends on status and individual circumstances, so it informs,
/// never decides (RDG / D9).
struct KindergeldView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// Ids of the documents/steps the user has ticked off. **Session-only by
    /// design:** a packing-list feel, not a tracker — held in `@State` and
    /// deliberately NOT persisted (no `@AppStorage`/SwiftData/file write).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    /// Guide opened from the "learn more" link — the tax-ID is central to the
    /// application, so the taxes guide is a natural next read.
    private let guideId = "how_taxes_work"

    init(
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var sections: [KindergeldSection] { KindergeldContent.sections }
    private var documents: [KindergeldDocument] { KindergeldContent.documents }
    private var steps: [KindergeldStep] { KindergeldContent.steps }
    private var rate: KindergeldRate { KindergeldContent.rate }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_kindergeld_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_kindergeld_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            amountCallout

            DisclaimerNote()

            sectionsView
            documentsSection
            stepsSection
            learnMore
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Current amount

    private var amountCallout: some View {
        Text(amountLine)
            .appText(.cardTitle)
            .foregroundStyle(AppColor.primaryDeep)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
            .background(
                AppColor.primaryWash,
                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(AppColor.primary.opacity(0.3), lineWidth: 1))
            .accessibilityElement(children: .combine)
    }

    private var amountLine: String {
        String(
            format: String(localized: "tool_kindergeld_amount_fmt"),
            money(rate.monthlyPerChild))
    }

    // MARK: - Explainer sections

    private var sectionsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(sections) { section in
                sectionCard(section)
            }
        }
    }

    private func sectionCard(_ section: KindergeldSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(LocalizedStringKey(section.headingKey))
                .appText(.cardTitle)
                .foregroundStyle(AppColor.ink)
            ForEach(section.bodyKeys, id: \.self) { bodyKey in
                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Text(verbatim: "•")
                        .appText(.label)
                        .foregroundStyle(AppColor.inkFaint)
                    Text(LocalizedStringKey(bodyKey))
                        .appText(.label)
                        .foregroundStyle(AppColor.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Documents

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_kindergeld_documents_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Session-only ticks (see `ticked`) — a packing-list feel, not a tracker.
            ForEach(documents) { doc in
                checkRow(id: doc.id, titleKey: doc.titleKey)
            }
        }
    }

    private func checkRow(id: String, titleKey: String) -> some View {
        let isTicked = ticked.contains(id)
        return Button {
            if isTicked { ticked.remove(id) } else { ticked.insert(id) }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isTicked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isTicked ? AppColor.primary : AppColor.inkFaint)
                Text(LocalizedStringKey(titleKey))
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.ink)
                    .strikethrough(isTicked, color: AppColor.inkSoft)
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

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_kindergeld_steps_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                stepRow(number: index + 1, step: step)
            }
        }
    }

    private func stepRow(number: Int, step: KindergeldStep) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Text("\(number)")
                .appText(.cardTitle)
                .foregroundStyle(AppColor.primaryDeep)
                .frame(width: 24, height: 24)
                .background(AppColor.primaryWash, in: Circle())
            Text(LocalizedStringKey(step.titleKey))
                .appText(.label)
                .foregroundStyle(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Learn more

    private var learnMore: some View {
        Button { onOpenGuide(guideId) } label: {
            HStack(spacing: AppSpacing.xxs) {
                Text("tool_kindergeld_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "EUR").precision(.fractionLength(0)))
    }
}

#Preview {
    NavigationStack { KindergeldView() }
        .appFontDesign()
}
