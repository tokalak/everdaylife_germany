import SwiftUI

/// Manual deadline entry (P3-07): title, date, and severity. Kept deliberately
/// small — most deadlines arrive auto-populated from decoded letters and
/// document expiries; this is the by-hand path.
struct AddDeadlineSheet: View {
    /// Called with the entered values on save.
    var onSave: (_ title: String, _ date: Date, _ severity: Severity) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date()
    @State private var severity: Severity = .action

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("dates_field_title", text: $title)
                    DatePicker(
                        "dates_field_date", selection: $date,
                        displayedComponents: .date)
                }
                Section("dates_field_severity") {
                    Picker("dates_field_severity", selection: $severity) {
                        ForEach([Severity.info, .action, .urgent, .legal]) { sev in
                            Text(sev.labelKey).tag(sev)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("dates_add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("dates_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("dates_save") {
                        onSave(
                            title.trimmingCharacters(in: .whitespacesAndNewlines),
                            date, severity)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
