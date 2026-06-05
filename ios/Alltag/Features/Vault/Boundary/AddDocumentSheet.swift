import SwiftUI

/// Names, files, and optionally dates a freshly scanned/imported document before
/// it's saved to the Vault (P3-05).
struct AddDocumentSheet: View {
    let defaultName: String
    /// Called with the chosen metadata on save.
    var onSave: (_ name: String, _ category: DocumentCategory, _ expiresAt: Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var category: DocumentCategory = .official
    @State private var hasExpiry = false
    @State private var expiry = Date()

    init(
        defaultName: String,
        onSave: @escaping (String, DocumentCategory, Date?) -> Void
    ) {
        self.defaultName = defaultName
        self.onSave = onSave
        _name = State(initialValue: defaultName)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("vault_field_name", text: $name)
                    Picker("vault_field_category", selection: $category) {
                        ForEach(DocumentCategory.allCases) { cat in
                            Label(LocalizedStringKey(cat.titleKey), systemImage: cat.systemImage)
                                .tag(cat)
                        }
                    }
                }
                Section {
                    Toggle("vault_field_has_expiry", isOn: $hasExpiry.animation())
                    if hasExpiry {
                        DatePicker(
                            "vault_field_expiry", selection: $expiry,
                            displayedComponents: .date)
                    }
                } footer: {
                    Text("vault_expiry_help")
                }
            }
            .navigationTitle("vault_add_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("vault_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("vault_save") {
                        onSave(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            category, hasExpiry ? expiry : nil)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
