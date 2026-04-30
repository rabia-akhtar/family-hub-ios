import Foundation

struct GroceryItem: Identifiable, Codable {
    var id: String
    var name: String
    var quantity: String
    var unit: String
    var checked: Bool
    var addedAt: Date

    var displayQuantity: String {
        if unit.isEmpty { return quantity }
        if quantity.isEmpty { return unit }
        return "\(quantity) \(unit)"
    }

    // MARK: - Sheet encoding / decoding
    // Columns: [id, name, quantity, unit, checked, addedAt]

    func toSheetRow() -> [String] {
        let iso = ISO8601DateFormatter()
        return [id, name, quantity, unit, checked ? "TRUE" : "FALSE", iso.string(from: addedAt)]
    }

    static func fromSheetRow(_ row: [String]) -> GroceryItem? {
        guard row.count >= 6, !row[0].isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        return GroceryItem(
            id: row[0],
            name: row[1],
            quantity: row[2],
            unit: row[3],
            checked: row[4].uppercased() == "TRUE",
            addedAt: iso.date(from: row[5]) ?? Date()
        )
    }

    static func new(name: String, quantity: String, unit: String) -> GroceryItem {
        GroceryItem(
            id: UUID().uuidString,
            name: name,
            quantity: quantity,
            unit: unit,
            checked: false,
            addedAt: Date()
        )
    }
}
