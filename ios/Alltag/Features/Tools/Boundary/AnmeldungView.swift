import SwiftUI

/// Anmeldung guide (P6-S4, shared with the Worker persona): a plain-language
/// how-to for registering your home address at the local Bürgeramt — what the
/// Anmeldung is and why it matters, the deadline, where to do it, what you
/// receive, the documents to bring, and the ordered steps.
///
/// Content comes from the versioned `AnmeldungContent`; this screen is
/// presentation only. Carries the standard RDG note — deadlines and procedures
/// vary by city, so it informs, never decides (RDG / D9).
struct AnmeldungView: View {
    /// Ids of the documents the user has ticked off. **Session-only by design:**
    /// a satisfying packing-list feel, not a tracker — held in `@State` and
    /// deliberately NOT persisted (no `@AppStorage`/SwiftData/file write).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    init(embedInScrollView: Bool = true) {
        self.embedInScrollView = embedInScrollView
    }

    private var sections: [AnmeldungSection] { AnmeldungContent.sections }
    private var documents: [AnmeldungDocument] { AnmeldungContent.documents }
    private var steps: [AnmeldungStep] { AnmeldungContent.steps }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_anmeldung_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_anmeldung_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            sectionsView
            documentsSection
            stepsSection
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Explainer sections

    private var sectionsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(sections) { section in
                sectionCard(section)
            }
        }
    }

    private func sectionCard(_ section: AnmeldungSection) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(LocalizedStringKey(section.headingKey))
                .appText(.cardTitle)
                .foregroundStyle(AppColor.ink)
            ForEach(section.bodyKeys, id: \.self) { bodyKey in
                Text(LocalizedStringKey(bodyKey))
                    .appText(.label)
                    .foregroundStyle(AppColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            Text("tool_anmeldung_documents_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Interactive packing-list ticks — session-only by design (see `ticked`).
            ForEach(documents) { doc in
                documentRow(doc)
            }
        }
    }

    private func documentRow(_ doc: AnmeldungDocument) -> some View {
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

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_anmeldung_steps_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                stepRow(number: index + 1, step: step)
            }
        }
    }

    private func stepRow(number: Int, step: AnmeldungStep) -> some View {
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
}

#Preview {
    NavigationStack { AnmeldungView() }
        .appFontDesign()
}
