import SwiftUI

/// Renewal tracker (P6-R4): lists the Vault documents that carry an expiry date,
/// soonest/most-overdue first, so a long-term resident can renew passports,
/// residence permits and the like before they lapse.
///
/// All ranking lives in the pure `RenewalTracker` engine. The documents are
/// **injected** (the Home `toolDestination` passes `env.vault.documents`; tests
/// pass a seeded array) — this view deliberately reads no `@Environment`, so its
/// snapshots stay environment-free and deterministic.
struct RenewalTrackerView: View {

    /// Vault documents to scan, injected from the caller.
    private let documents: [DocumentRecord]
    /// The "as of" date the countdowns are measured from. Defaults to today at
    /// runtime but is injectable so snapshot tests pass a fixed date.
    private let asOf: Date
    /// Embed in a `ScrollView` (shipping default); `false` for snapshots.
    private let embedInScrollView: Bool

    init(documents: [DocumentRecord], asOf: Date = .now, embedInScrollView: Bool = true) {
        self.documents = documents
        self.asOf = asOf
        self.embedInScrollView = embedInScrollView
    }

    private var renewals: [Renewal] {
        RenewalTracker.upcoming(documents: documents, asOf: asOf)
    }

    var body: some View {
        Group {
            if embedInScrollView { ScrollView { content } } else { content }
        }
        .background(AppColor.paper)
        .navigationTitle("tool_renewal_title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("tool_renewal_intro")
                .appText(.body)
                .foregroundStyle(AppColor.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            DisclaimerNote()

            if renewals.isEmpty {
                EmptyState(
                    systemImage: "arrow.clockwise.circle",
                    titleKey: "tool_renewal_empty_title",
                    messageKey: "tool_renewal_empty_message")
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(renewals) { renewal in
                        row(renewal)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ renewal: Renewal) -> some View {
        let tint = tint(for: renewal.status)
        return HStack(spacing: AppSpacing.sm) {
            Image(systemName: renewal.category.systemImage)
                .font(.system(size: 22))
                .foregroundStyle(tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(renewal.name)
                    .appText(.bodyEmphasis)
                    .foregroundStyle(AppColor.ink)
                HStack(spacing: AppSpacing.xs) {
                    Text(statusLabel(renewal.status))
                        .appText(.label)
                        .foregroundStyle(tint)
                    Text("· \(DatesFormat.countdown(for: renewal.expiresAt, now: asOf))")
                        .appText(.label)
                        .foregroundStyle(tint)
                    Text("· \(renewal.expiresAt, format: .dateTime.day().month(.abbreviated).year())")
                        .appText(.label)
                        .foregroundStyle(AppColor.inkFaint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppSpacing.md)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .strokeBorder(AppColor.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    /// Expired and due-soon are time-critical (urgent); upcoming is calm (teal).
    private func tint(for status: RenewalStatus) -> Color {
        switch status {
        case .expired, .dueSoon: return AppColor.severityUrgent
        case .upcoming:          return AppColor.primary
        }
    }

    private func statusLabel(_ status: RenewalStatus) -> String {
        switch status {
        case .expired:  return String(localized: "tool_renewal_status_expired")
        case .dueSoon:  return String(localized: "tool_renewal_status_due_soon")
        case .upcoming: return String(localized: "tool_renewal_status_upcoming")
        }
    }
}

#Preview {
    NavigationStack {
        RenewalTrackerView(documents: [
            DocumentRecord(fileName: "Reisepass", category: "identity",
                           expiresAt: Calendar.current.date(byAdding: .day, value: -5, to: .now)),
            DocumentRecord(fileName: "Aufenthaltstitel", category: "identity",
                           expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: .now)),
            DocumentRecord(fileName: "Haftpflichtversicherung", category: "insurance",
                           expiresAt: Calendar.current.date(byAdding: .day, value: 200, to: .now)),
        ])
    }
    .appFontDesign()
}
