import Foundation

@MainActor
final class GroceriesViewModel: ObservableObject {

    @Published var items: [GroceryItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Computed

    var uncheckedItems: [GroceryItem] {
        items.filter { !$0.checked }.sorted { $0.addedAt < $1.addedAt }
    }

    var checkedItems: [GroceryItem] {
        items.filter { $0.checked }.sorted { $0.addedAt > $1.addedAt }
    }

    // MARK: - Load

    func load(appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        isLoading = true
        errorMessage = nil
        do {
            let token = try await appVM.accessToken()
            items = try await appVM.sheetsService.fetchGroceries(spreadsheetId: sid, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Add Item

    func addItem(_ item: GroceryItem, appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        isLoading = true
        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.appendRow(
                spreadsheetId: sid,
                sheet: AppConfig.SheetName.groceries,
                values: [item.toSheetRow()],
                token: token
            )
            items.append(item)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Toggle Checked

    func toggleChecked(_ item: GroceryItem, appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId,
              let idx = items.firstIndex(where: { $0.id == item.id }) else { return }

        items[idx].checked.toggle()

        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.saveGroceries(items, spreadsheetId: sid, token: token)
        } catch {
            // revert
            items[idx].checked = item.checked
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete

    func deleteItem(_ item: GroceryItem, appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        items.removeAll { $0.id == item.id }
        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.saveGroceries(items, spreadsheetId: sid, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Clear Checked Items

    func clearChecked(appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        items.removeAll { $0.checked }
        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.saveGroceries(items, spreadsheetId: sid, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
