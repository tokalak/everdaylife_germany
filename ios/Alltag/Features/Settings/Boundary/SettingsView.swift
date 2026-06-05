import SwiftUI
import UIKit

/// The Settings tab (P3-09, D10): a native grouped list where **every row
/// explains itself** — appearance, language, mode, reminders, an on-device
/// storage explainer, GDPR export/delete, and help/legal.
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.openURL) private var openURL

    @State private var showDeleteConfirm = false
    @State private var exportURLs: [URL]?
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                setupSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(AppColor.paper)
            .navigationTitle("tab_settings")
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(item: Binding(
                get: { exportURLs.map { ExportPayload(urls: $0) } },
                set: { exportURLs = $0?.urls }
            )) { payload in
                ShareSheet(items: payload.urls)
            }
            .alert("settings_delete_confirm_title", isPresented: $showDeleteConfirm) {
                Button("settings_delete_confirm", role: .destructive) {
                    env.dataManagement.deleteAllData()
                }
                Button("settings_cancel", role: .cancel) {}
            } message: {
                Text("settings_delete_confirm_message")
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("settings_appearance") {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                explain("settings_theme_title", "settings_theme_explanation", "paintpalette")
                Picker("settings_appearance", selection: themeBinding) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.labelKey).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, AppSpacing.xxs)
        }
    }

    // MARK: - Your setup

    private var setupSection: some View {
        Section("settings_setup") {
            Picker(selection: languageBinding) {
                ForEach(AppLanguage.selectable) { Text($0.endonym).tag($0) }
            } label: {
                explain("settings_language_title", "settings_language_explanation", "globe")
            }

            NavigationLink {
                ModePickerView()
            } label: {
                explain("settings_mode_title", "settings_mode_explanation", "person.crop.circle",
                        value: env.personas.activePersona?.displayName)
            }

            Button { openSystemSettings() } label: {
                explain("settings_reminders_title", "settings_reminders_explanation", "bell.badge", chevron: true)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Documents & data

    private var dataSection: some View {
        Section("settings_data") {
            explain("settings_storage_title", "settings_storage_explanation",
                    "internaldrive", value: storageText)

            Button { exportURLs = env.dataManagement.exportItems() } label: {
                explain("settings_export_title", "settings_export_explanation",
                        "square.and.arrow.up", chevron: true)
            }
            .buttonStyle(.plain)

            Button { showDeleteConfirm = true } label: {
                explain("settings_delete_title", "settings_delete_explanation",
                        "trash", tint: AppColor.severityUrgent, chevron: true)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("settings_about") {
            Button { contactSupport() } label: {
                explain("settings_help_title", "settings_help_explanation",
                        "questionmark.circle", chevron: true)
            }
            .buttonStyle(.plain)

            Button { showAbout = true } label: {
                explain("settings_legal_title", "settings_legal_explanation",
                        "scale.3d", tint: AppColor.severityLegal, chevron: true)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Row helper

    /// A "speaking" row: tinted icon + title + one-line explanation, optional
    /// trailing value or chevron (D10).
    private func explain(
        _ titleKey: LocalizedStringKey,
        _ explanationKey: LocalizedStringKey,
        _ systemImage: String,
        tint: Color = AppColor.primary,
        value: String? = nil,
        chevron: Bool = false
    ) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.14), in: RoundedRectangle(
                    cornerRadius: AppRadius.sm, style: .continuous))
            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                Text(titleKey)
                    .appText(.bodyEmphasis)
                    .foregroundStyle(AppColor.ink)
                Text(explanationKey)
                    .appText(.label)
                    .foregroundStyle(AppColor.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let value {
                Text(value).appText(.callout).foregroundStyle(AppColor.inkSoft)
            }
            if chevron {
                Image(systemName: "chevron.forward")
                    .appText(.label).foregroundStyle(AppColor.inkFaint)
            }
        }
    }

    // MARK: - Bindings + actions

    private var themeBinding: Binding<AppTheme> {
        Binding(get: { env.theme.theme }, set: { env.theme.select($0) })
    }
    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { env.language.language }, set: { env.language.select($0) })
    }

    private var storageText: String {
        let bytes = env.vault.totalBytesUsed() + env.llm.store.totalBytesUsed()
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
    }

    private func contactSupport() {
        if let url = URL(string: "mailto:support@everydaygermany.de") { openURL(url) }
    }
}

/// Wrapper so `[URL]` can drive a `.sheet(item:)`.
private struct ExportPayload: Identifiable {
    let id = UUID()
    let urls: [URL]
}
