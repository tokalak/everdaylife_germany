import SwiftUI

/// Birth-registration (Standesamt) sub-flow (P6-F7): a plain-language walk-through
/// for registering a newborn's birth — what birth registration is and its
/// deadline, the documents the parents bring, and the ordered follow-up
/// registrations that cascade afterwards (birth certificate copies, health
/// insurance, Kindergeld, residence permit, Anmeldung).
///
/// Content comes from the versioned `BirthRegistrationContent`; this screen is
/// presentation only. Carries the standard RDG note — deadlines and document
/// requirements vary by city's Standesamt and the family's situation, so it
/// informs, never decides (RDG / D9).
struct BirthRegistrationView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// Ids of the documents/steps the user has ticked off. **Session-only by
    /// design:** a packing-list feel, not a tracker — held in `@State` and
    /// deliberately NOT persisted (no `@AppStorage`/SwiftData/file write).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    /// Guide opened from the "learn more" link — a non-EU baby needs its own
    /// residence permit, so the residence-permit guide is a natural next read.
    private let guideId = "residence_permit"

    init(
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var sections: [BirthRegistrationSection] { BirthRegistrationContent.sections }
    private var documents: [BirthRegistrationDocument] { BirthRegistrationContent.documents }
    private var steps: [BirthRegistrationStep] { BirthRegistrationContent.steps }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_birth_reg_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_birth_reg_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            sectionsView
            documentsSection
            stepsSection
            learnMore
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

    private func sectionCard(_ section: BirthRegistrationSection) -> some View {
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
            Text("tool_birth_reg_documents_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Interactive packing-list ticks — session-only by design (see `ticked`).
            ForEach(documents) { doc in
                documentRow(doc)
            }
        }
    }

    private func documentRow(_ doc: BirthRegistrationDocument) -> some View {
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

    // MARK: - Follow-up steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_birth_reg_steps_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                stepRow(number: index + 1, step: step)
            }
        }
    }

    private func stepRow(number: Int, step: BirthRegistrationStep) -> some View {
        let isTicked = ticked.contains(step.id)
        return Button {
            if isTicked { ticked.remove(step.id) } else { ticked.insert(step.id) }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Text("\(number)")
                    .appText(.cardTitle)
                    .foregroundStyle(AppColor.primaryDeep)
                    .frame(width: 24, height: 24)
                    .background(AppColor.primaryWash, in: Circle())
                Text(LocalizedStringKey(step.titleKey))
                    .appText(.label)
                    .foregroundStyle(AppColor.ink)
                    .strikethrough(isTicked, color: AppColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isTicked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isTicked ? AppColor.primary : AppColor.inkFaint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
                Text("tool_birth_reg_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { BirthRegistrationView() }
        .appFontDesign()
}
