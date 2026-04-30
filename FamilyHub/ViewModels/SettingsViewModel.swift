import Foundation

// MARK: - Supporting Types

struct TaskCategoryConfig: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var emoji: String
    var pointValue: Int

    init(id: UUID = UUID(), name: String, emoji: String, pointValue: Int) {
        self.id = id; self.name = name; self.emoji = emoji; self.pointValue = pointValue
    }
}

struct MilestoneConfig: Identifiable, Codable, Equatable {
    var id: UUID
    var threshold: Int
    var emoji: String
    var label: String

    init(id: UUID = UUID(), threshold: Int, emoji: String, label: String) {
        self.id = id; self.threshold = threshold; self.emoji = emoji; self.label = label
    }
}

// MARK: - SettingsViewModel

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: Family

    @Published var familyName: String {
        didSet { UserDefaults.standard.set(familyName, forKey: Keys.familyName) }
    }

    @Published var familyMembers: [String] {
        didSet { persist(familyMembers, key: Keys.familyMembers) }
    }

    // MARK: Tasks

    @Published var taskCategories: [TaskCategoryConfig] {
        didSet { persist(taskCategories, key: Keys.taskCategories) }
    }

    // MARK: Milestones

    @Published var milestones: [MilestoneConfig] {
        didSet { persist(milestones, key: Keys.milestones) }
    }

    // MARK: Budget

    @Published var budgetCategories: [String] {
        didSet { persist(budgetCategories, key: Keys.budgetCategories) }
    }

    // MARK: Location

    @Published var locationLatitude: Double {
        didSet { UserDefaults.standard.set(locationLatitude, forKey: Keys.locationLatitude) }
    }

    @Published var locationLongitude: Double {
        didSet { UserDefaults.standard.set(locationLongitude, forKey: Keys.locationLongitude) }
    }

    @Published var locationLabel: String {
        didSet { UserDefaults.standard.set(locationLabel, forKey: Keys.locationLabel) }
    }

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let familyName        = "settings_familyName"
        static let familyMembers     = "settings_familyMembers"
        static let taskCategories    = "settings_taskCategories"
        static let milestones        = "settings_milestones"
        static let budgetCategories  = "settings_budgetCategories"
        static let locationLatitude  = "locationLatitude"
        static let locationLongitude = "locationLongitude"
        static let locationLabel     = "settings_locationLabel"
    }

    // MARK: - Defaults

    static let defaultTaskCategories: [TaskCategoryConfig] = [
        .init(name: "Chore",  emoji: "🧹", pointValue: 5),
        .init(name: "House",  emoji: "🏠", pointValue: 5),
        .init(name: "Cats",   emoji: "🐱", pointValue: 5),
        .init(name: "Other",  emoji: "📌", pointValue: 3)
    ]

    static let defaultMilestones: [MilestoneConfig] = [
        .init(threshold: 0,   emoji: "✨", label: "Getting Started"),
        .init(threshold: 250, emoji: "⭐", label: "Star"),
        .init(threshold: 500, emoji: "🥇", label: "Gold"),
        .init(threshold: 750, emoji: "🏆", label: "Champion")
    ]

    static let defaultBudgetCategories = [
        "Groceries", "Dining", "Entertainment", "Transport",
        "Health", "Shopping", "Utilities", "Other"
    ]

    // MARK: - Init

    init() {
        let ud = UserDefaults.standard
        familyName    = ud.string(forKey: Keys.familyName)   ?? "My Family"
        locationLabel = ud.string(forKey: Keys.locationLabel) ?? "New York, NY"

        familyMembers    = Self.restore([String].self,               key: Keys.familyMembers)    ?? ["Me"]
        taskCategories   = Self.restore([TaskCategoryConfig].self,   key: Keys.taskCategories)   ?? Self.defaultTaskCategories
        milestones       = Self.restore([MilestoneConfig].self,      key: Keys.milestones)       ?? Self.defaultMilestones
        budgetCategories = Self.restore([String].self,               key: Keys.budgetCategories) ?? Self.defaultBudgetCategories

        let lat = ud.double(forKey: Keys.locationLatitude)
        locationLatitude  = lat == 0 ? AppConfig.defaultLatitude  : lat
        let lon = ud.double(forKey: Keys.locationLongitude)
        locationLongitude = lon == 0 ? AppConfig.defaultLongitude : lon
    }

    // MARK: - Convenience Helpers

    func pointValue(for category: String) -> Int {
        taskCategories.first { $0.name.lowercased() == category.lowercased() }?.pointValue ?? 3
    }

    func emoji(for category: String) -> String {
        taskCategories.first { $0.name.lowercased() == category.lowercased() }?.emoji ?? "📌"
    }

    func milestone(for points: Int) -> MilestoneConfig {
        let sorted = milestones.sorted { $0.threshold < $1.threshold }
        return sorted.last(where: { points >= $0.threshold }) ?? sorted.first
            ?? .init(threshold: 0, emoji: "✨", label: "Start")
    }

    func nextMilestoneThreshold(for points: Int) -> Int {
        let sorted = milestones.sorted { $0.threshold < $1.threshold }
        return sorted.first(where: { points < $0.threshold })?.threshold
            ?? (sorted.last?.threshold ?? 1000)
    }

    func milestoneProgress(for points: Int) -> Double {
        let sorted = milestones.sorted { $0.threshold < $1.threshold }
        guard let currentM = sorted.last(where: { points >= $0.threshold }),
              let nextM    = sorted.first(where: { points < $0.threshold }) else { return 1.0 }
        let range = Double(nextM.threshold - currentM.threshold)
        guard range > 0 else { return 1.0 }
        return min(1.0, Double(points - currentM.threshold) / range)
    }

    // MARK: - Persistence

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func restore<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
