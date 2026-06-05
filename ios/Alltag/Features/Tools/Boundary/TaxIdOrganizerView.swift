import SwiftUI

/// Tax-ID & Steuernummer organizer (P6-W6): explains the German tax identifiers a
/// newcomer deals with (Steuer-ID, Steuernummer, USt-IdNr), an ordered organizer
/// checklist, and a **live Steuer-ID format validator**.
///
/// Content comes from the versioned `TaxIdentifierCatalog`; validation from the
/// pure `TaxIdValidator`. This screen is presentation only and carries the RDG
/// note. **Privacy (D4):** the number the user types is held in session-only
/// `@State` and is *never* persisted (no `@AppStorage`/SwiftData/file write) —
/// the organizer explains and validates locally without storing the number.
struct TaxIdOrganizerView: View {
    /// Opens a guide in the reader (provided by Home so results can deep-link).
    var onOpenGuide: (String) -> Void = { _ in }

    /// The Steuer-ID the user is checking. **Session-only, never persisted** —
    /// this is sensitive PII (D4); it lives only as long as the screen does.
    @State private var steuerIDInput: String

    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    var embedInScrollView: Bool

    /// Guide opened from the "learn more" link.
    private let guideId = "how_taxes_work"

    init(
        steuerIDInput: String = "",
        embedInScrollView: Bool = true,
        onOpenGuide: @escaping (String) -> Void = { _ in }
    ) {
        self._steuerIDInput = State(initialValue: steuerIDInput)
        self.embedInScrollView = embedInScrollView
        self.onOpenGuide = onOpenGuide
    }

    private var identifiers: [TaxIdentifier] { TaxIdentifierCatalog.identifiers }
    private var checklist: [TaxIdStep] { TaxIdentifierCatalog.checklist }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_taxid_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_taxid_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            identifiersSection
            checklistSection
            validatorSection
            learnMore
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Identifiers

    private var identifiersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_taxid_identifiers_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            ForEach(identifiers) { identifier in
                identifierCard(identifier)
            }
        }
    }

    private func identifierCard(_ identifier: TaxIdentifier) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(LocalizedStringKey(identifier.titleKey))
                .appText(.cardTitle)
                .foregroundStyle(AppColor.ink)
            detailRow("tool_taxid_what_label", body: identifier.whatKey)
            detailRow("tool_taxid_where_label", body: identifier.whereKey)
            detailRow("tool_taxid_when_label", body: identifier.whenKey)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func detailRow(_ labelKey: LocalizedStringKey, body bodyKey: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
            Text(labelKey)
                .appText(.caption)
                .foregroundStyle(AppColor.primaryDeep)
            Text(LocalizedStringKey(bodyKey))
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Organizer checklist

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_taxid_checklist_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            // Static, informational rows — deliberately NOT wired to the persisted
            // ChecklistStore (this is a guide-like reference list, not a tracker).
            ForEach(checklist) { step in
                ChecklistRow(
                    titleKey: LocalizedStringKey(step.titleKey),
                    subtitleKey: LocalizedStringKey(step.subtitleKey),
                    showsDisclosure: false)
            }
        }
    }

    // MARK: - Steuer-ID validator

    private var validatorSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("tool_taxid_validator_title")
                .appText(.sectionHeader)
                .foregroundStyle(AppColor.ink)
            Text("tool_taxid_validator_hint")
                .appText(.label)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            TextField("tool_taxid_validator_placeholder", text: $steuerIDInput)
                .keyboardType(.numberPad)
                .appText(.body)
                .padding(AppSpacing.md)
                .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .strokeBorder(AppColor.line, lineWidth: 1))
                .accessibilityLabel("tool_taxid_validator_title")

            feedbackRow

            // Privacy note: the number is checked on-device and never stored.
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                Image(systemName: "lock.fill")
                    .imageScale(.small)
                    .foregroundStyle(AppColor.inkSoft)
                Text("tool_taxid_privacy_note")
                    .appText(.caption)
                    .foregroundStyle(AppColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var feedbackRow: some View {
        let trimmed = steuerIDInput.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            feedback("tool_taxid_validator_empty", systemImage: "info.circle", color: AppColor.inkSoft)
        } else if TaxIdValidator.isValidSteuerID(steuerIDInput) {
            feedback("tool_taxid_validator_valid", systemImage: "checkmark.circle.fill", color: AppColor.severityInfo)
        } else {
            feedback("tool_taxid_validator_invalid", systemImage: "xmark.circle.fill", color: AppColor.severityUrgent)
        }
    }

    private func feedback(_ key: LocalizedStringKey, systemImage: String, color: Color) -> some View {
        Label(key, systemImage: systemImage)
            .appText(.label)
            .foregroundStyle(color)
            .accessibilityElement(children: .combine)
    }

    // MARK: - Learn more

    private var learnMore: some View {
        Button { onOpenGuide(guideId) } label: {
            HStack(spacing: AppSpacing.xxs) {
                Text("tool_taxid_learn_more")
                Image(systemName: "chevron.forward").imageScale(.small)
            }
            .appText(.label)
            .foregroundStyle(AppColor.primaryDeep)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { TaxIdOrganizerView(steuerIDInput: "02476291358") }
        .appFontDesign()
}
