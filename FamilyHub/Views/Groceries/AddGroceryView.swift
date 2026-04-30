import SwiftUI

struct AddGroceryView: View {

    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var groceriesVM: GroceriesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var quantity: String = ""
    @State private var unit: String = ""
    @State private var isSaving: Bool = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private let commonUnits = ["", "pcs", "lbs", "oz", "kg", "g", "L", "mL", "cups", "tbsp", "tsp", "pkg", "box", "can", "bottle"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item name", text: $name)

                    HStack {
                        TextField("Qty", text: $quantity)
                            .keyboardType(.decimalPad)
                            .frame(width: 70)
                        Divider()
                        Picker("Unit", selection: $unit) {
                            ForEach(commonUnits, id: \.self) { u in
                                Text(u.isEmpty ? "—" : u).tag(u)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("Add Item")
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
        isSaving = true
        let item = GroceryItem.new(
            name: name.trimmingCharacters(in: .whitespaces),
            quantity: quantity.trimmingCharacters(in: .whitespaces),
            unit: unit
        )
        await groceriesVM.addItem(item, appVM: appVM)
        isSaving = false
        dismiss()
    }
}
