import SwiftUI

struct AddExpenseView: View {

    @EnvironmentObject var appVM:      AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @ObservedObject var budgetVM: BudgetViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var category: String = ""
    @State private var amountText: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var isSaving: Bool = false

    private var amount: Double? { Double(amountText) }
    private var canSave: Bool { amount != nil && amount! > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Details") {
                    Picker("Category", selection: $category) {
                        ForEach(settingsVM.budgetCategories, id: \.self) { cat in
                            Label {
                                Text(cat)
                            } icon: {
                                Circle()
                                    .fill(Color.budgetColor(for: cat))
                                    .frame(width: 10, height: 10)
                            }
                            .tag(cat)
                        }
                    }
                    .onAppear {
                        if category.isEmpty {
                            category = settingsVM.budgetCategories.first ?? "Other"
                        }
                    }

                    HStack {
                        Text("$")
                            .foregroundColor(.secondaryText)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Description (optional)", text: $description)
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task { await save() }
                        }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func save() async {
        guard let amount = amount else { return }
        isSaving = true
        let entry = BudgetEntry.new(
            category: category,
            amount: amount,
            description: description.trimmingCharacters(in: .whitespaces),
            date: date
        )
        await budgetVM.addEntry(entry, appVM: appVM)
        isSaving = false
        dismiss()
    }
}
