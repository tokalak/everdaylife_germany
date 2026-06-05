import SwiftUI

/// Verpflichtungserklärung explainer (P6-T3): plain-language explanation of the
/// formal "declaration of commitment" — what it is, who needs it, where & how to
/// get it, what the sponsor must prove, its cost & validity, and the crucial
/// caveat that it is **legally binding** — plus a checklist of what the sponsor
/// brings to the appointment.
///
/// Content comes from the versioned `VerpflichtungContent`; this screen is
/// presentation only. Because the declaration is legally binding and
/// consequential, it carries the standard RDG note **and** a legal-severity
/// caution routing the user to the responsible authority (RDG / D9).
struct VerpflichtungView: View {
    /// The sponsor's checklist items ticked off. **Session-only by design:** a
    /// satisfying packing-list feel, not a tracker — held in `@State` and
    /// deliberately NOT persisted (no `@AppStorage`/SwiftData/file write).
    @State private var ticked: Set<String> = []

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    init(embedInScrollView: Bool = true) {
        self.embedInScrollView = embedInScrollView
    }

    private var sections: [VerpflichtungSection] { VerpflichtungContent.sections }
    private var checklist: [VerpflichtungItem] { VerpflichtungContent.checklist }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_verpflichtung_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_verpflichtung_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()
            bindingCaution

            sectionsView
            checklistSection
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Legally-binding caution

    /// A legal-severity callout: this is a binding obligation with real financial
    /// liability — check the details with the responsible authority.
    private var bindingCaution: some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .imageScale(.small)
                .foregroundStyle(AppColor.severityLegal)
            Text("tool_verpflichtung_binding_caution")
                .appText(.caption)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.sm)
        .background(AppColor.severityLegalWash)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Explainer sections

    private var sectionsView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(sections) { section in
                sectionCard(section)
            }
        }
    }

    private func sectionCard(_ section: VerpflichtungSection) -> some View {
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

    // MARK: - Sponsor checklist

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_verpflichtung_checklist_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Interactive packing-list ticks — session-only by design (see `ticked`).
            ForEach(checklist) { item in
                itemRow(item)
            }
        }
    }

    private func itemRow(_ item: VerpflichtungItem) -> some View {
        let isTicked = ticked.contains(item.id)
        return Button {
            if isTicked { ticked.remove(item.id) } else { ticked.insert(item.id) }
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: isTicked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isTicked ? AppColor.primary : AppColor.inkFaint)
                Text(LocalizedStringKey(item.titleKey))
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
}

#Preview {
    NavigationStack { VerpflichtungView() }
        .appFontDesign()
}
