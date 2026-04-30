import Foundation

struct TaskItem: Identifiable, Codable {
    var id: String
    var name: String
    var category: String   // "chore", "house", "cats", "other"
    var assignee: String
    var pointsValue: Int
    var completed: Bool
    var dueDate: Date?
    var createdAt: Date

    // MARK: - Computed Properties

    var categoryDisplayName: String {
        switch category.lowercased() {
        case "chore":  return "Chore"
        case "house":  return "House"
        case "cats":   return "Cats"
        default:       return "Other"
        }
    }

    var milestoneEmoji: String {
        AppConfig.milestone(for: pointsValue).emoji
    }

    var isOverdue: Bool {
        guard let due = dueDate else { return false }
        return !completed && due < Date() && !due.isToday
    }

    var isDueToday: Bool {
        guard let due = dueDate else { return false }
        return due.isToday
    }

    // MARK: - Encoding to Sheet Row

    /// Returns values in sheet column order:
    /// [id, name, category, assignee, pointsValue, completed, dueDate, createdAt]
    func toSheetRow() -> [String] {
        let iso = ISO8601DateFormatter()
        return [
            id,
            name,
            category,
            assignee,
            String(pointsValue),
            completed ? "TRUE" : "FALSE",
            dueDate.map { iso.string(from: $0) } ?? "",
            iso.string(from: createdAt)
        ]
    }

    // MARK: - Decoding from Sheet Row

    static func fromSheetRow(_ row: [String]) -> TaskItem? {
        guard row.count >= 8, !row[0].isEmpty else { return nil }
        let iso = ISO8601DateFormatter()
        let id         = row[0]
        let name       = row[1]
        let category   = row[2]
        let assignee   = row[3]
        let points     = Int(row[4]) ?? 3
        let completed  = row[5].uppercased() == "TRUE"
        let dueDate    = row[6].isEmpty ? nil : iso.date(from: row[6])
        let createdAt  = iso.date(from: row[7]) ?? Date()
        return TaskItem(
            id: id,
            name: name,
            category: category,
            assignee: assignee,
            pointsValue: points,
            completed: completed,
            dueDate: dueDate,
            createdAt: createdAt
        )
    }

    // MARK: - Factory

    static func new(name: String, category: String, assignee: String, dueDate: Date? = nil) -> TaskItem {
        let points = AppConfig.pointsForCategory[category.lowercased()] ?? 3
        return TaskItem(
            id: UUID().uuidString,
            name: name,
            category: category,
            assignee: assignee,
            pointsValue: points,
            completed: false,
            dueDate: dueDate,
            createdAt: Date()
        )
    }
}
