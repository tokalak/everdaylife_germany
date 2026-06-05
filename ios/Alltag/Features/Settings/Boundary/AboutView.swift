import SwiftUI

/// About & legal (P3-09): app identity, version, and the always-on RDG
/// "information, not advice" disclaimer (D9/X-04).
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 52))
                            .foregroundStyle(AppColor.primary)
                            .symbolRenderingMode(.hierarchical)
                        Text("app_name").appText(.title).foregroundStyle(AppColor.ink)
                        Text(verbatim: version)
                            .appText(.caption).foregroundStyle(AppColor.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppSpacing.lg)

                    DisclaimerNote(messageKey: "settings_legal_body",
                                   systemImage: "scale.3d")

                    Text("settings_legal_privacy")
                        .appText(.body)
                        .foregroundStyle(AppColor.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColor.paper)
            .navigationTitle("settings_legal_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("settings_done") { dismiss() }
                }
            }
        }
    }
}
