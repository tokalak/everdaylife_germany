import SwiftUI

/// One document in the Vault list (P3-05): a category icon, the name, and an
/// expiry badge when the document lapses.
struct DocumentRow: View {
    let document: DocumentRecord

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: document.categoryValue.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColor.primary)
                .frame(width: 40, height: 40)
                .background(AppColor.primaryWash, in: RoundedRectangle(
                    cornerRadius: AppRadius.sm, style: .continuous))
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(document.fileName)
                    .appText(.bodyEmphasis)
                    .foregroundStyle(AppColor.ink)
                    .lineLimit(1)
                Text(LocalizedStringKey(document.categoryValue.titleKey))
                    .appText(.label)
                    .foregroundStyle(AppColor.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            expiryBadge
        }
        .padding(AppSpacing.sm)
        .background(AppColor.card, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .appShadow(.sm)
    }

    @ViewBuilder
    private var expiryBadge: some View {
        if let days = document.daysUntilExpiry() {
            let severity: Severity = days < 0 ? .urgent : (days <= 30 ? .action : .info)
            Text(VaultFormat.expiry(days: days))
                .appText(.label)
                .foregroundStyle(severity.color)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xxxs)
                .background(severity.wash, in: Capsule())
        }
    }
}

/// Localized expiry labels for the Vault (day-floored).
enum VaultFormat {
    /// "Expired" / "Expires today" / "Expires in N days".
    static func expiry(days: Int) -> String {
        switch days {
        case ..<0:  return String(localized: "vault_expired")
        case 0:     return String(localized: "vault_expires_today")
        default:    return String(format: String(localized: "vault_expires_in"), days)
        }
    }
}
