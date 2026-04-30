import Foundation

struct PointsEntry: Identifiable {
    var id: String { userId }
    var userId: String
    var displayName: String
    var email: String
    var totalPoints: Int

    // MARK: - Milestone info

    var milestoneEmoji: String {
        AppConfig.milestone(for: totalPoints).emoji
    }

    var milestoneName: String {
        AppConfig.milestone(for: totalPoints).label
    }

    var nextMilestone: Int {
        AppConfig.nextMilestone(for: totalPoints)
    }

    /// Progress from current milestone threshold to next (0.0 – 1.0)
    var milestoneProgress: Double {
        let current = AppConfig.milestone(for: totalPoints).threshold
        let next = nextMilestone
        if next == current { return 1.0 }
        return Double(totalPoints - current) / Double(next - current)
    }

    // MARK: - Sheet encoding / decoding
    // Columns: [userId, displayName, email, totalPoints]

    func toSheetRow() -> [String] {
        [userId, displayName, email, String(totalPoints)]
    }

    static func fromSheetRow(_ row: [String]) -> PointsEntry? {
        guard row.count >= 4, !row[0].isEmpty else { return nil }
        return PointsEntry(
            userId: row[0],
            displayName: row[1],
            email: row[2],
            totalPoints: Int(row[3]) ?? 0
        )
    }

    static func new(userId: String, displayName: String, email: String) -> PointsEntry {
        PointsEntry(userId: userId, displayName: displayName, email: email, totalPoints: 0)
    }
}
