import Foundation

struct BudgetEntry: Identifiable, Codable {
    var id: String
    var category: String
    var amount: Double
    var description: String
    var date: Date

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }

    // MARK: - Sheet encoding / decoding
    // Columns: [id, category, amount, description, date]

    func toSheetRow() -> [String] {
        let iso = ISO8601DateFormatter()
        return [id, category, String(amount), description, iso.string(from: date)]
    }

    static func fromSheetRow(_ row: [String]) -> BudgetEntry? {
        guard row.count >= 5, !row[0].isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        return BudgetEntry(
            id: row[0],
            category: row[1],
            amount: Double(row[2]) ?? 0,
            description: row[3],
            date: iso.date(from: row[4]) ?? Date()
        )
    }

    static func new(category: String, amount: Double, description: String, date: Date = Date()) -> BudgetEntry {
        BudgetEntry(
            id: UUID().uuidString,
            category: category,
            amount: amount,
            description: description,
            date: date
        )
    }
}
