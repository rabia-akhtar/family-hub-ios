import SwiftUI

struct GroceriesView: View {

    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var groceriesVM: GroceriesViewModel

    @State private var showAddItem = false
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if groceriesVM.isLoading && groceriesVM.items.isEmpty {
                    VStack { Spacer(); ProgressView("Loading groceries..."); Spacer() }
                } else {
                    groceryList
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Groceries")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddItem = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primaryPurple)
                    }
                }
                if !groceriesVM.checkedItems.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Clear Checked") {
                            showClearConfirm = true
                        }
                        .foregroundColor(.accentRed)
                        .font(.system(size: 14))
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddGroceryView(groceriesVM: groceriesVM)
            }
            .confirmationDialog("Clear checked items?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear Checked", role: .destructive) {
                    Task { await groceriesVM.clearChecked(appVM: appVM) }
                }
                Button("Cancel", role: .cancel) {}
            }
            .refreshable {
                await groceriesVM.load(appVM: appVM)
            }
        }
    }

    private var groceryList: some View {
        List {
            // Unchecked items
            if !groceriesVM.uncheckedItems.isEmpty {
                Section("Items (\(groceriesVM.uncheckedItems.count))") {
                    ForEach(groceriesVM.uncheckedItems) { item in
                        GroceryRow(item: item) {
                            Task { await groceriesVM.toggleChecked(item, appVM: appVM) }
                        }
                        .listRowBackground(Color.cardBackground)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await groceriesVM.deleteItem(item, appVM: appVM) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            // Checked items
            if !groceriesVM.checkedItems.isEmpty {
                Section("In Cart (\(groceriesVM.checkedItems.count))") {
                    ForEach(groceriesVM.checkedItems) { item in
                        GroceryRow(item: item) {
                            Task { await groceriesVM.toggleChecked(item, appVM: appVM) }
                        }
                        .listRowBackground(Color.cardBackground)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await groceriesVM.deleteItem(item, appVM: appVM) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if groceriesVM.items.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 48))
                            .foregroundColor(.secondaryText)
                        Text("Your grocery list is empty")
                            .foregroundColor(.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - GroceryRow

private struct GroceryRow: View {
    let item: GroceryItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(item.checked ? .accentGreen : .secondaryText)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.checked ? .secondaryText : .primaryText)
                    .strikethrough(item.checked)

                if !item.displayQuantity.isEmpty {
                    Text(item.displayQuantity)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .opacity(item.checked ? 0.65 : 1.0)
    }
}
