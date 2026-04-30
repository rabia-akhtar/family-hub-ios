import SwiftUI

struct CalendarView: View {

    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var calendarVM: CalendarViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date strip
                dateStrip

                Divider()

                if calendarVM.isLoading {
                    Spacer()
                    ProgressView("Loading events...")
                    Spacer()
                } else {
                    eventsList
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await calendarVM.load(appVM: appVM)
            }
        }
    }

    // MARK: - Date Strip

    private var dateStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(calendarVM.dateStripDays, id: \.self) { date in
                        DateStripCell(
                            date: date,
                            isSelected: date.isSameDay(as: calendarVM.selectedDate),
                            hasEvents: calendarVM.hasEvents(on: date)
                        )
                        .onTapGesture { calendarVM.selectedDate = date }
                        .id(date.toDateKey())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.cardBackground)
            .onAppear {
                proxy.scrollTo(Date().toDateKey(), anchor: .center)
            }
        }
    }

    // MARK: - Events List

    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let events = calendarVM.eventsForSelectedDate
                if events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 48))
                            .foregroundColor(.secondaryText.opacity(0.5))
                        Text("No events on \(calendarVM.selectedDate.relativeLabel())")
                            .foregroundColor(.secondaryText)
                    }
                    .padding(.top, 80)
                } else {
                    Text(calendarVM.selectedDate.relativeLabel())
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    ForEach(events) { event in
                        CalendarEventRow(event: event)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Date Strip Cell

private struct DateStripCell: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isSelected ? .white : .secondaryText)
            Text(dayNumber)
                .font(.system(size: 17, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (date.isToday ? .primaryPurple : .primaryText))

            Circle()
                .fill(hasEvents ? (isSelected ? Color.white : Color.primaryPurple) : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(width: 44, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.primaryPurple : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(date.isToday && !isSelected ? Color.primaryPurple.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Calendar Event Row

private struct CalendarEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 14) {
            // Color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(colorFromHex(event.colorHex) ?? .accentBlue)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primaryText)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(event.timeRangeString, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondaryText)

                    if !event.calendarName.isEmpty {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 3, height: 3)
                        Text(event.calendarName)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }

    private func colorFromHex(_ hex: String?) -> Color? {
        guard let hex = hex else { return nil }
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard h.count == 6, let rgb = UInt64(h, radix: 16) else { return nil }
        return Color(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}
