import SwiftUI

/// Embassy document checklist (P6-T2): pick what you are applying for and get the
/// documents to bring to your German embassy/consulate appointment, as an
/// interactive "packing list".
///
/// The documents come from the pure `EmbassyChecklistEngine`; this screen is
/// selection + presentation. Always carries the RDG note — requirements vary by
/// consulate, so it informs, never decides. Defaults to the short-stay purpose so
/// a checklist is visible immediately (KISS).
struct EmbassyChecklistView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// The chosen visa purpose. Seedable for previews/tests.
    @State private var purpose: VisaPurpose

    /// Ids of the documents the user has ticked off. **Session-only by design:**
    /// this is a satisfying packing-list feel, not a tracker — it is held in
    /// `@State` and deliberately NOT persisted (no `@AppStorage`/SwiftData/file).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    /// Guide opened from the "learn more" link (long-stay purposes only).
    private let guideId = "residence_permit"

    init(
        purpose: VisaPurpose = .shortStay,
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._purpose = State(initialValue: purpose)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var documents: [ChecklistDocument] { EmbassyChecklistEngine.documents(for: purpose) }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_embassy_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_embassy_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            purposeSelector
            documentsSection
            if purpose.isLongStay { learnMore }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Purpose selector

    private var purposeSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_embassy_purpose_question")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(VisaPurpose.allCases) { p in
                purposeRow(p)
            }
        }
    }

    private func purposeRow(_ p: VisaPurpose) -> some View {
        let isSelected = purpose == p
        return Button { purpose = p } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkFaint)
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(LocalizedStringKey(p.titleKey))
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(LocalizedStringKey(p.subtitleKey))
                        .appText(.label)
                        .foregroundStyle(AppColor.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.md)
            .background(
                (isSelected ? AppColor.primaryWash : AppColor.card),
                in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(isSelected ? AppColor.primary.opacity(0.5) : AppColor.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Documents

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_embassy_documents_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Interactive packing-list ticks — session-only by design (see `ticked`).
            ForEach(documents) { doc in
                documentRow(doc)
            }
        }
    }

    private func documentRow(_ doc: ChecklistDocument) -> some View {
        let isTicked = ticked.contains(doc.id)
        return Button {
            if isTicked { ticked.remove(doc.id) } else { ticked.insert(doc.id) }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isTicked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isTicked ? AppColor.primary : AppColor.inkFaint)
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(LocalizedStringKey(doc.titleKey))
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                        .strikethrough(isTicked, color: AppColor.inkSoft)
                    if let hintKey = doc.hintKey {
                        Text(LocalizedStringKey(hintKey))
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
                Text("tool_embassy_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { EmbassyChecklistView(purpose: .study) }
        .appFontDesign()
}
