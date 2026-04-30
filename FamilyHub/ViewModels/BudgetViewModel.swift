import Foundation

@MainActor
final class BudgetViewModel: ObservableObject {

    @Published var entries: [BudgetEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Current Month Computed

    var currentMonthEntries: [BudgetEntry] {
        let start = Date.startOfMonth()
        let end   = Date.endOfMonth()
        return entries.filter { $0.date >= start && $0.date <= end }
    }

    var currentMonthTotal: Double {
        currentMonthEntries.reduce(0) { $0 + $1.amount }
    }

    var totalByCategory: [(category: String, total: Double)] {
        var map: [String: Double] = [:]
        for entry in currentMonthEntries {
            map[entry.category, default: 0] += entry.amount
        }
        return map.map { (category: $0.key, total: $0.value) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }

    var recentEntries: [BudgetEntry] {
        entries.sorted { $0.date > $1.date }.prefix(20).map { $0 }
    }

    // MARK: - Grouped by Month

    var groupedByMonth: [(month: String, entries: [BudgetEntry])] {
        let grouped = Dictionary(grouping: entries) { $0.date.toMonthYearString() }
        return grouped
            .map { (month: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { lhs, rhs in
                // Sort months descending
                let fmt = DateFormatter()
                fmt.dateFormat = "MMMM yyyy"
                let d1 = fmt.date(from: lhs.month) ?? Date.distantPast
                let d2 = fmt.date(from: rhs.month) ?? Date.distantPast
                return d1 > d2
            }
    }

    // MARK: - Load

    func load(appVM: AppViewModel) async {
        guard let sid = appVM.budgetSpreadsheetId else { return }
        isLoading = true
        errorMessage = nil
        do {
            let token = try await appVM.accessToken()
            entries = try await appVM.sheetsService.fetchBudget(spreadsheetId: sid, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Add Entry

    func addEntry(_ entry: BudgetEntry, appVM: AppViewModel) async {
        guard let sid = appVM.budgetSpreadsheetId else { return }
        isLoading = true
        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.appendRow(
                spreadsheetId: sid,
                sheet: AppConfig.SheetName.budget,
                values: [entry.toSheetRow()],
                token: token
            )
            entries.append(entry)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Delete Entry

    func deleteEntry(_ entry: BudgetEntry, appVM: AppViewModel) async {
        guard let sid = appVM.budgetSpreadsheetId else { return }
        entries.removeAll { $0.id == entry.id }
        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.saveBudget(entries, spreadsheetId: sid, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
