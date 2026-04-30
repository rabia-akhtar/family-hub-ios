import Foundation

// MARK: - Error Types

enum SheetsError: LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed
    case noSpreadsheetID

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid Sheets API URL."
        case .requestFailed(let c): return "Sheets API request failed with status \(c)."
        case .decodingFailed:       return "Failed to decode Sheets API response."
        case .noSpreadsheetID:      return "No spreadsheet ID found."
        }
    }
}

// MARK: - SheetsService

final class SheetsService {

    private let baseURL = AppConfig.sheetsAPIBaseURL
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Ensure Spreadsheets Exist (multi-device: searches Drive by name)

    func ensureSpreadsheet(token: String) async throws -> String {
        // Check local cache first to avoid an extra Drive API call
        if let storedID = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKey.spreadsheetId),
           !storedID.isEmpty {
            return storedID
        }
        // Search Drive so any device finds the same spreadsheet (not just the one that created it)
        if let foundID = try await findSpreadsheetOnDrive(named: "Family Hub Data", token: token) {
            UserDefaults.standard.set(foundID, forKey: AppConfig.UserDefaultsKey.spreadsheetId)
            return foundID
        }
        let newID = try await createSpreadsheet(token: token)
        UserDefaults.standard.set(newID, forKey: AppConfig.UserDefaultsKey.spreadsheetId)
        return newID
    }

    func ensureBudgetSpreadsheet(token: String) async throws -> String {
        if let storedID = UserDefaults.standard.string(forKey: AppConfig.UserDefaultsKey.budgetSpreadsheetId),
           !storedID.isEmpty {
            return storedID
        }
        if let foundID = try await findSpreadsheetOnDrive(named: AppConfig.budgetSpreadsheetTitle, token: token) {
            UserDefaults.standard.set(foundID, forKey: AppConfig.UserDefaultsKey.budgetSpreadsheetId)
            return foundID
        }
        let newID = try await createBudgetSpreadsheet(token: token)
        UserDefaults.standard.set(newID, forKey: AppConfig.UserDefaultsKey.budgetSpreadsheetId)
        return newID
    }

    // MARK: - Search Drive for Spreadsheet by Name

    private func findSpreadsheetOnDrive(named title: String, token: String) async throws -> String? {
        let escaped = title.replacingOccurrences(of: "'", with: "\\'")
        let query = "name='\(escaped)' and mimeType='application/vnd.google-apps.spreadsheet' and trashed=false"
        guard var components = URLComponents(string: "\(AppConfig.driveAPIBaseURL)/files") else {
            throw SheetsError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: "files(id,name)"),
            URLQueryItem(name: "orderBy", value: "createdTime"),
            URLQueryItem(name: "pageSize", value: "1")
        ]
        guard let url = components.url else { throw SheetsError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [[String: Any]],
              let first = files.first,
              let fileId = first["id"] as? String else {
            return nil
        }
        return fileId
    }

    // MARK: - Create Spreadsheet

    func createSpreadsheet(token: String) async throws -> String {
        // Step 1: Create spreadsheet with all sheets
        let createBody: [String: Any] = [
            "properties": ["title": "Family Hub Data"],
            "sheets": [
                ["properties": ["title": AppConfig.SheetName.tasks]],
                ["properties": ["title": AppConfig.SheetName.rewards]],
                ["properties": ["title": AppConfig.SheetName.points]],
                ["properties": ["title": AppConfig.SheetName.groceries]]
            ]
        ]

        guard let url = URL(string: baseURL) else { throw SheetsError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: createBody)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let spreadsheetId = json["spreadsheetId"] as? String else {
            throw SheetsError.decodingFailed
        }

        // Step 2: Write headers to each sheet
        try await writeHeaders(spreadsheetId: spreadsheetId, token: token)

        return spreadsheetId
    }

    // MARK: - Create Budget Spreadsheet (separate from main data sheet)

    func createBudgetSpreadsheet(token: String) async throws -> String {
        let createBody: [String: Any] = [
            "properties": ["title": AppConfig.budgetSpreadsheetTitle],
            "sheets": [
                ["properties": ["title": AppConfig.SheetName.budget]]
            ]
        ]

        guard let url = URL(string: baseURL) else { throw SheetsError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: createBody)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let spreadsheetId = json["spreadsheetId"] as? String else {
            throw SheetsError.decodingFailed
        }

        try await updateRow(
            spreadsheetId: spreadsheetId,
            range: "Budget!A1:E1",
            values: [["id","category","amount","description","date"]],
            token: token
        )
        return spreadsheetId
    }

    private func writeHeaders(spreadsheetId: String, token: String) async throws {
        let headers: [(range: String, values: [String])] = [
            ("Tasks!A1:H1",     ["id","name","category","assignee","pointsValue","completed","dueDate","createdAt"]),
            ("Rewards!A1:E1",   ["id","name","pointsCost","description","redeemed"]),
            ("Points!A1:D1",    ["userId","displayName","email","totalPoints"]),
            ("Groceries!A1:F1", ["id","name","quantity","unit","checked","addedAt"])
        ]
        for header in headers {
            try await updateRow(spreadsheetId: spreadsheetId, range: header.range, values: [header.values], token: token)
        }
    }

    // MARK: - Get Values

    func getValues(spreadsheetId: String, range: String, token: String) async throws -> [[String]] {
        let encodedRange = range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? range
        guard let url = URL(string: "\(baseURL)/\(spreadsheetId)/values/\(encodedRange)") else {
            throw SheetsError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SheetsError.decodingFailed
        }
        // values may be absent if sheet is empty
        return (json["values"] as? [[Any]])?.map { row in
            row.map { "\($0)" }
        } ?? []
    }

    // MARK: - Append Row

    func appendRow(spreadsheetId: String, sheet: String, values: [[String]], token: String) async throws {
        let range = "\(sheet)!A1"
        let encodedRange = range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? range
        guard let url = URL(string: "\(baseURL)/\(spreadsheetId)/values/\(encodedRange):append?valueInputOption=RAW&insertDataOption=INSERT_ROWS") else {
            throw SheetsError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["values": values]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - Update Row (PUT)

    func updateRow(spreadsheetId: String, range: String, values: [[String]], token: String) async throws {
        let encodedRange = range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? range
        guard let url = URL(string: "\(baseURL)/\(spreadsheetId)/values/\(encodedRange)?valueInputOption=RAW") else {
            throw SheetsError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["values": values]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - Delete Row (batchUpdate DeleteDimensionRequest)

    func deleteRow(spreadsheetId: String, sheetId: Int, rowIndex: Int, token: String) async throws {
        guard let url = URL(string: "\(baseURL)/\(spreadsheetId):batchUpdate") else {
            throw SheetsError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "requests": [[
                "deleteDimension": [
                    "range": [
                        "sheetId": sheetId,
                        "dimension": "ROWS",
                        "startIndex": rowIndex,
                        "endIndex": rowIndex + 1
                    ]
                ]
            ]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - Get Sheet ID by Name

    func getSheetId(spreadsheetId: String, sheetName: String, token: String) async throws -> Int {
        guard let url = URL(string: "\(baseURL)/\(spreadsheetId)?fields=sheets.properties") else {
            throw SheetsError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sheets = json["sheets"] as? [[String: Any]] else {
            throw SheetsError.decodingFailed
        }

        for sheet in sheets {
            if let props = sheet["properties"] as? [String: Any],
               let title = props["title"] as? String,
               title == sheetName,
               let sheetId = props["sheetId"] as? Int {
                return sheetId
            }
        }
        return 0
    }

    // MARK: - Clear Sheet (data rows only, keep header)

    func clearSheet(spreadsheetId: String, sheet: String, token: String) async throws {
        let range = "\(sheet)!A2:Z10000"
        let encodedRange = range.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? range
        guard let url = URL(string: "\(baseURL)/\(spreadsheetId)/values/\(encodedRange):clear") else {
            throw SheetsError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }

    // MARK: - High-Level Helpers: Tasks

    func fetchTasks(spreadsheetId: String, token: String) async throws -> [TaskItem] {
        let rows = try await getValues(spreadsheetId: spreadsheetId, range: "Tasks!A2:H10000", token: token)
        return rows.compactMap { TaskItem.fromSheetRow($0) }
    }

    func saveTasks(_ tasks: [TaskItem], spreadsheetId: String, token: String) async throws {
        try await clearSheet(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.tasks, token: token)
        if !tasks.isEmpty {
            let rows = tasks.map { $0.toSheetRow() }
            try await appendRow(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.tasks, values: rows, token: token)
        }
    }

    // MARK: - High-Level Helpers: Rewards

    func fetchRewards(spreadsheetId: String, token: String) async throws -> [Reward] {
        let rows = try await getValues(spreadsheetId: spreadsheetId, range: "Rewards!A2:E10000", token: token)
        return rows.compactMap { Reward.fromSheetRow($0) }
    }

    func saveRewards(_ rewards: [Reward], spreadsheetId: String, token: String) async throws {
        try await clearSheet(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.rewards, token: token)
        if !rewards.isEmpty {
            let rows = rewards.map { $0.toSheetRow() }
            try await appendRow(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.rewards, values: rows, token: token)
        }
    }

    // MARK: - High-Level Helpers: Points

    func fetchPoints(spreadsheetId: String, token: String) async throws -> [PointsEntry] {
        let rows = try await getValues(spreadsheetId: spreadsheetId, range: "Points!A2:D10000", token: token)
        return rows.compactMap { PointsEntry.fromSheetRow($0) }
    }

    func updatePoints(userId: String, displayName: String, email: String, newTotal: Int, spreadsheetId: String, token: String) async throws {
        var entries = try await fetchPoints(spreadsheetId: spreadsheetId, token: token)
        if let idx = entries.firstIndex(where: { $0.userId == userId }) {
            entries[idx].totalPoints = newTotal
        } else {
            entries.append(PointsEntry(userId: userId, displayName: displayName, email: email, totalPoints: newTotal))
        }
        try await clearSheet(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.points, token: token)
        if !entries.isEmpty {
            let rows = entries.map { $0.toSheetRow() }
            try await appendRow(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.points, values: rows, token: token)
        }
    }

    // MARK: - High-Level Helpers: Groceries

    func fetchGroceries(spreadsheetId: String, token: String) async throws -> [GroceryItem] {
        let rows = try await getValues(spreadsheetId: spreadsheetId, range: "Groceries!A2:F10000", token: token)
        return rows.compactMap { GroceryItem.fromSheetRow($0) }
    }

    func saveGroceries(_ items: [GroceryItem], spreadsheetId: String, token: String) async throws {
        try await clearSheet(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.groceries, token: token)
        if !items.isEmpty {
            let rows = items.map { $0.toSheetRow() }
            try await appendRow(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.groceries, values: rows, token: token)
        }
    }

    // MARK: - High-Level Helpers: Budget

    func fetchBudget(spreadsheetId: String, token: String) async throws -> [BudgetEntry] {
        let rows = try await getValues(spreadsheetId: spreadsheetId, range: "Budget!A2:E10000", token: token)
        return rows.compactMap { BudgetEntry.fromSheetRow($0) }
    }

    func saveBudget(_ entries: [BudgetEntry], spreadsheetId: String, token: String) async throws {
        try await clearSheet(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.budget, token: token)
        if !entries.isEmpty {
            let rows = entries.map { $0.toSheetRow() }
            try await appendRow(spreadsheetId: spreadsheetId, sheet: AppConfig.SheetName.budget, values: rows, token: token)
        }
    }

    // MARK: - Private Helpers

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            print("[SheetsService] HTTP \(http.statusCode): \(body)")
            throw SheetsError.requestFailed(http.statusCode)
        }
    }
}
