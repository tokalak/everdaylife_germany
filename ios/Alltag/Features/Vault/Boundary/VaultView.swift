import SwiftUI
import UniformTypeIdentifiers

/// The Docs/Vault tab (P3-05): the user's documents, grouped by category, stored
/// **only on this device** (D4/X-03). Add by scanning a letter or importing a
/// file; export/share any document; expiries surface in Dates (P3-06/08).
struct VaultView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showScanner = false
    @State private var showImporter = false
    @State private var pending: PendingDocument?
    @State private var shareURL: URL?
    @State private var toast = false
    @State private var toastMessage: LocalizedStringKey = ""

    private var store: VaultStore { env.vault }

    var body: some View {
        NavigationStack {
            Group {
                if store.isEmpty {
                    empty
                } else {
                    list
                }
            }
            .background(AppColor.paper)
            .navigationTitle("tab_docs")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { addMenu } }
            .sheet(isPresented: $showScanner) { scannerSheet }
            .sheet(item: $pending) { pending in
                AddDocumentSheet(defaultName: pending.defaultName) { name, category, expiry in
                    save(pending.data, name: name, category: category, expiry: expiry)
                }
            }
            .sheet(item: $shareURL) { url in ShareSheet(items: [url]) }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.pdf, .image],
                allowsMultipleSelection: false
            ) { handleImport($0) }
            .appToast(isPresented: $toast, toastMessage)
        }
    }

    // MARK: - States

    private var empty: some View {
        VStack(spacing: AppSpacing.lg) {
            EmptyState(
                systemImage: "folder.badge.plus",
                titleKey: "vault_empty_title",
                messageKey: "vault_empty_message")
            TrustBanner(messageKey: "vault_trust", systemImage: "lock.fill")
                .padding(.horizontal, AppSpacing.lg)
        }
        .padding(AppSpacing.lg)
    }

    private var list: some View {
        List {
            Section {
                TrustBanner(messageKey: "vault_trust", systemImage: "lock.fill")
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            ForEach(store.grouped(), id: \.category) { group in
                Section {
                    ForEach(group.documents) { document in
                        DocumentRow(document: document)
                            .listRowInsets(EdgeInsets(
                                top: AppSpacing.xxs, leading: AppSpacing.md,
                                bottom: AppSpacing.xxs, trailing: AppSpacing.md))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .onTapGesture { share(document) }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.remove(document)
                                } label: {
                                    Label("vault_delete", systemImage: "trash")
                                }
                                Button { share(document) } label: {
                                    Label("vault_share", systemImage: "square.and.arrow.up")
                                }
                                .tint(AppColor.primary)
                            }
                    }
                } header: {
                    Text(LocalizedStringKey(group.category.titleKey))
                        .appText(.sectionHeader)
                        .foregroundStyle(AppColor.inkSoft)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var addMenu: some View {
        Menu {
            if DocumentScannerView.isSupported {
                Button { showScanner = true } label: {
                    Label("vault_scan", systemImage: "doc.text.viewfinder")
                }
            }
            Button { showImporter = true } label: {
                Label("vault_import", systemImage: "tray.and.arrow.down")
            }
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("vault_add")
    }

    private var scannerSheet: some View {
        DocumentScannerView(
            onScan: { pages in
                showScanner = false
                guard let pdf = DocumentPDF.make(from: pages) else { return }
                pending = PendingDocument(
                    data: pdf, defaultName: String(localized: "vault_default_scan_name"))
            },
            onCancel: { showScanner = false })
        .ignoresSafeArea()
    }

    // MARK: - Actions

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else { return }
        let needsStop = url.startAccessingSecurityScopedResource()
        defer { if needsStop { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else {
            present("vault_toast_import_failed"); return
        }
        pending = PendingDocument(
            data: data, defaultName: url.deletingPathExtension().lastPathComponent)
    }

    private func save(_ data: Data, name: String, category: DocumentCategory, expiry: Date?) {
        do {
            try store.add(data: data, fileName: name, category: category, expiresAt: expiry)
            present("vault_toast_saved")
        } catch {
            present("vault_toast_save_failed")
        }
    }

    private func share(_ document: DocumentRecord) {
        guard let data = store.data(for: document) else {
            present("vault_toast_open_failed"); return
        }
        // Write to a temp file named after the document so the share sheet shows a
        // sensible filename; the bytes are already decrypted in memory only.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(document.fileName)
            .appendingPathExtension("pdf")
        do {
            try data.write(to: url)
            shareURL = url
        } catch {
            present("vault_toast_open_failed")
        }
    }

    private func present(_ message: LocalizedStringKey) {
        toastMessage = message
        toast = true
    }
}

/// A scanned/imported document awaiting naming + filing.
private struct PendingDocument: Identifiable {
    let id = UUID()
    let data: Data
    let defaultName: String
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
