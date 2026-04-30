import Foundation

@MainActor
final class CalendarViewModel: ObservableObject {

    @Published var events: [CalendarEvent] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()

    // MARK: - Grouped Events

    /// All events grouped by day (date key → events)
    var eventsByDate: [String: [CalendarEvent]] {
        Dictionary(grouping: events) { $0.start.toDateKey() }
    }

    /// Events for the currently selected date
    var eventsForSelectedDate: [CalendarEvent] {
        let key = selectedDate.toDateKey()
        return eventsByDate[key] ?? []
    }

    /// Next 3 upcoming events from today
    var upcomingEvents: [CalendarEvent] {
        let now = Date()
        return events.filter { $0.start >= now }.prefix(3).map { $0 }
    }

    // MARK: - Date Strip

    var dateStripDays: [Date] {
        (0..<14).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: Calendar.current.startOfDay(for: Date()))
        }
    }

    func hasEvents(on date: Date) -> Bool {
        eventsByDate[date.toDateKey()] != nil
    }

    // MARK: - Load

    func load(appVM: AppViewModel) async {
        isLoading = true
        errorMessage = nil
        do {
            let token = try await appVM.accessToken()
            events = try await appVM.calendarService.fetchEvents(token: token, daysAhead: 30)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
