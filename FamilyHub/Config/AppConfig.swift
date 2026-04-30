import Foundation

enum AppConfig {
    // MARK: - API Base URLs
    static let openMeteoBaseURL = "https://api.open-meteo.com/v1/forecast"
    static let sheetsAPIBaseURL = "https://sheets.googleapis.com/v4/spreadsheets"
    static let calendarAPIBaseURL = "https://www.googleapis.com/calendar/v3"

    // MARK: - Default Location (NYC)
    static let defaultLatitude: Double = 40.7128
    static let defaultLongitude: Double = -74.0060

    // MARK: - Drive API Base URL
    static let driveAPIBaseURL = "https://www.googleapis.com/drive/v3"

    // MARK: - UserDefaults Keys
    enum UserDefaultsKey {
        static let spreadsheetId = "spreadsheetId"
        static let budgetSpreadsheetId = "budgetSpreadsheetId"
        static let locationLatitude = "locationLatitude"
        static let locationLongitude = "locationLongitude"
    }

    // MARK: - Points per Category
    static let pointsForCategory: [String: Int] = [
        "chore": 5,
        "house": 5,
        "cats": 5,
        "other": 3
    ]

    // MARK: - Task Categories
    static let taskCategories = ["chore", "house", "cats", "other"]

    // MARK: - Budget Categories
    static let budgetCategories = [
        "Groceries",
        "Dining",
        "Entertainment",
        "Transport",
        "Health",
        "Shopping",
        "Utilities",
        "Other"
    ]

    // MARK: - Milestones
    struct Milestone {
        let threshold: Int
        let emoji: String
        let label: String
    }

    static let milestones: [Milestone] = [
        Milestone(threshold: 0,   emoji: "✨", label: "Getting Started"),
        Milestone(threshold: 250, emoji: "⭐", label: "Star"),
        Milestone(threshold: 500, emoji: "🥇", label: "Gold"),
        Milestone(threshold: 750, emoji: "🏆", label: "Champion")
    ]

    static func milestone(for points: Int) -> Milestone {
        var current = milestones[0]
        for milestone in milestones {
            if points >= milestone.threshold {
                current = milestone
            }
        }
        return current
    }

    static func nextMilestone(for points: Int) -> Int {
        for milestone in milestones {
            if points < milestone.threshold {
                return milestone.threshold
            }
        }
        return milestones.last!.threshold
    }

    // MARK: - Google Sheets Sheet Names
    enum SheetName {
        static let tasks = "Tasks"
        static let rewards = "Rewards"
        static let points = "Points"
        static let groceries = "Groceries"
        static let budget = "Budget"
    }

    // MARK: - Budget spreadsheet name (separate spreadsheet from main data)
    static let budgetSpreadsheetTitle = "Family Hub Budget"

    // MARK: - Google OAuth Scopes
    // drive.readonly: search Drive for existing spreadsheets (enables multi-device)
    // drive.file: create new spreadsheets
    // spreadsheets: read/write spreadsheet data
    static let googleScopes = [
        "https://www.googleapis.com/auth/spreadsheets",
        "https://www.googleapis.com/auth/drive.file",
        "https://www.googleapis.com/auth/drive.readonly",
        "https://www.googleapis.com/auth/calendar.readonly"
    ]
}
