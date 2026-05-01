import Foundation

enum CalendarError: LocalizedError {
    case invalidURL
    case requestFailed(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid Calendar API URL."
        case .requestFailed(let c): return "Calendar API request failed with status \(c)."
        case .decodingFailed:       return "Failed to decode Calendar API response."
        }
    }
}

final class CalendarService {

    private let baseURL = AppConfig.calendarAPIBaseURL
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Fetch Calendar List

    func fetchCalendars(token: String) async throws -> [(id: String, name: String, colorHex: String?)] {
        guard let url = URL(string: "\(baseURL)/users/me/calendarList") else {
            throw CalendarError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            throw CalendarError.decodingFailed
        }

        return items.compactMap { item in
            guard let id = item["id"] as? String,
                  let name = item["summary"] as? String else { return nil }
            let colorHex = item["backgroundColor"] as? String
            return (id: id, name: name, colorHex: colorHex)
        }
    }

    // MARK: - Fetch Events

    func fetchEvents(token: String, daysAhead: Int = 30) async throws -> [CalendarEvent] {
        let calendars = try await fetchCalendars(token: token)
        var allEvents: [CalendarEvent] = []

        let now = Date()
        let future = Calendar.current.date(byAdding: .day, value: daysAhead, to: now) ?? now

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plainFormatter = ISO8601DateFormatter()

        let timeMin = now.toISO8601()
        let timeMax = future.toISO8601()

        for cal in calendars {
            var components = URLComponents(string: "\(baseURL)/calendars/\(cal.id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? cal.id)/events")
            components?.queryItems = [
                URLQueryItem(name: "timeMin", value: timeMin),
                URLQueryItem(name: "timeMax", value: timeMax),
                URLQueryItem(name: "singleEvents", value: "true"),
                URLQueryItem(name: "orderBy", value: "startTime"),
                URLQueryItem(name: "maxResults", value: "250")
            ]
            guard let url = components?.url else { continue }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            guard let (data, response) = try? await session.data(for: request),
                  let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let items = json["items"] as? [[String: Any]] else {
                continue
            }

            for item in items {
                guard let id = item["id"] as? String else { continue }

                let title = (item["summary"] as? String) ?? "No Title"

                // Parse start
                var startDate: Date
                var isAllDay = false
                if let startObj = item["start"] as? [String: Any] {
                    if let dateStr = startObj["date"] as? String {
                        isAllDay = true
                        startDate = Date.from(dateKey: dateStr) ?? now
                    } else if let dtStr = startObj["dateTime"] as? String {
                        startDate = isoFormatter.date(from: dtStr) ?? plainFormatter.date(from: dtStr) ?? now
                    } else {
                        startDate = now
                    }
                } else {
                    startDate = now
                }

                // Parse end
                var endDate: Date
                if let endObj = item["end"] as? [String: Any] {
                    if let dateStr = endObj["date"] as? String {
                        endDate = Date.from(dateKey: dateStr) ?? startDate
                    } else if let dtStr = endObj["dateTime"] as? String {
                        endDate = isoFormatter.date(from: dtStr) ?? plainFormatter.date(from: dtStr) ?? startDate
                    } else {
                        endDate = startDate
                    }
                } else {
                    endDate = startDate
                }

                // Suppress the "id" warning — we know id is set
                let _ = id
                let event = CalendarEvent(
                    id: id,
                    title: title,
                    start: startDate,
                    end: endDate,
                    isAllDay: isAllDay,
                    calendarName: cal.name,
                    colorHex: cal.colorHex
                )
                allEvents.append(event)
            }
        }

        // Sort by start date
        allEvents.sort { $0.start < $1.start }
        return allEvents
    }

    // MARK: - Private Helpers

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            print("[CalendarService] HTTP \(http.statusCode): \(body)")
            throw CalendarError.requestFailed(http.statusCode)
        }
    }
}
