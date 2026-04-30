import Foundation

struct CalendarEvent: Identifiable {
    var id: String
    var title: String
    var start: Date
    var end: Date
    var isAllDay: Bool
    var calendarName: String
    var colorHex: String?

    var timeRangeString: String {
        if isAllDay { return "All day" }
        return "\(start.toTimeString()) – \(end.toTimeString())"
    }

    var dateLabel: String {
        start.relativeLabel()
    }
}
