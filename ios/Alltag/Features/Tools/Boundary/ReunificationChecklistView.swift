import SwiftUI

/// Family-reunification (Familiennachzug) visa checklist (P6-F1): pick which family
/// member is joining a relative in Germany and get the documents to gather for the
/// national (type-D) visa application, as an interactive "packing list".
///
/// The documents come from the pure `ReunificationChecklistEngine`; this screen is
/// selection + presentation. Always carries the RDG note — requirements vary by
/// case and consulate, so it informs, never decides. Defaults to the spouse
/// relation so a checklist is visible immediately (KISS).
struct ReunificationChecklistView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// The chosen family relation. Seedable for previews/tests.
    @State private var relation: FamilyRelation

    /// Ids of the documents the user has ticked off. **Session-only by design:**
    /// this is a satisfying packing-list feel, not a tracker — it is held in
    /// `@State` and deliberately NOT persisted (no `@AppStorage`/SwiftData/file).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    /// Guide opened from the "learn more" link.
    private let guideId = "residence_permit"

    init(
        relation: FamilyRelation = .spouse,
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._relation = State(initialValue: relation)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var documents: [ReunificationDocument] {
        ReunificationChecklistEngine.documents(for: relation)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_reunification_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_reunification_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            relationSelector
            documentsSection
            learnMore
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Relation selector

    private var relationSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_reunification_relation_question")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(FamilyRelation.allCases) { r in
                relationRow(r)
            }
        }
    }

    private func relationRow(_ r: FamilyRelation) -> some View {
        let isSelected = relation == r
        return Button { relation = r } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkFaint)
                VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                    Text(LocalizedStringKey(r.titleKey))
                        .appText(.cardTitle)
                        .foregroundStyle(AppColor.ink)
                    Text(LocalizedStringKey(r.subtitleKey))
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
            Text("tool_reunification_documents_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Interactive packing-list ticks — session-only by design (see `ticked`).
            ForEach(documents) { doc in
                documentRow(doc)
            }
        }
    }

    private func documentRow(_ doc: ReunificationDocument) -> some View {
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
                Text("tool_reunification_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { ReunificationChecklistView(relation: .spouse) }
        .appFontDesign()
}
