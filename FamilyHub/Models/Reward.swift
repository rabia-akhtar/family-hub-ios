import Foundation

struct Reward: Identifiable, Codable {
    var id: String
    var name: String
    var pointsCost: Int
    var description: String
    var redeemed: Bool

    // MARK: - Sheet encoding / decoding
    // Columns: [id, name, pointsCost, description, redeemed]

    func toSheetRow() -> [String] {
        [id, name, String(pointsCost), description, redeemed ? "TRUE" : "FALSE"]
    }

    static func fromSheetRow(_ row: [String]) -> Reward? {
        guard row.count >= 5, !row[0].isEmpty else { return nil }
        return Reward(
            id: row[0],
            name: row[1],
            pointsCost: Int(row[2]) ?? 0,
            description: row[3],
            redeemed: row[4].uppercased() == "TRUE"
        )
    }

    static func new(name: String, pointsCost: Int, description: String) -> Reward {
        Reward(
            id: UUID().uuidString,
            name: name,
            pointsCost: pointsCost,
            description: description,
            redeemed: false
        )
    }
}
