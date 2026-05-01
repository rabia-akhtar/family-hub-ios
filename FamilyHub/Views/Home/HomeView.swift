import SwiftUI

struct HomeView: View {

    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var tasksVM:    TasksViewModel
    @ObservedObject var calendarVM: CalendarViewModel
    @ObservedObject var weatherVM:  WeatherViewModel
    @ObservedObject var rewardsVM:  RewardsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header
                    headerSection

                    // Weather Card
                    weatherCard

                    // Today's Tasks
                    todayTasksSection

                    // Upcoming Events
                    upcomingEventsSection

                    // Points Leaderboard
                    pointsSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable {
                await refresh()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryText)
                Text(appVM.userDisplayName)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryText)
            }
            Spacer()
            Text(Date().toDisplayString())
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .padding(.top, 8)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default:     return "Good evening,"
        }
    }

    // MARK: - Weather Card

    private var weatherCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.weatherGradient)

            if let weather = weatherVM.weatherData {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(weather.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(Int(weather.temperature))°F")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        HStack(spacing: 12) {
                            Label("UV \(Int(weather.uvIndex))", systemImage: "sun.max")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                            Label("\(Int(weather.windSpeed)) mph", systemImage: "wind")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                    Image(systemName: weather.systemImageName)
                        .font(.system(size: 56))
                        .foregroundColor(.white.opacity(0.9))
                        .symbolRenderingMode(.hierarchical)
                }
                .padding(20)
            } else if weatherVM.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(20)
            } else {
                HStack {
                    Image(systemName: "cloud.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Weather unavailable")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(20)
            }
        }
        .frame(height: 130)
    }

    // MARK: - Today's Tasks

    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today's Tasks", systemImage: "checkmark.circle")

            let todayTasks = tasksVM.todayIncompleteTasks
            if todayTasks.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.seal.fill",
                    message: "All caught up for today!",
                    color: .accentGreen
                )
            } else {
                ForEach(todayTasks.prefix(5)) { task in
                    HomeTaskRow(task: task) {
                        Task { await tasksVM.toggleComplete(task, appVM: appVM) }
                    }
                }
                if todayTasks.count > 5 {
                    Text("+ \(todayTasks.count - 5) more tasks")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .padding(.leading, 4)
                }
            }
        }
    }

    // MARK: - Upcoming Events

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Upcoming Events", systemImage: "calendar")

            let events = calendarVM.upcomingEvents
            if events.isEmpty {
                EmptyStateCard(icon: "calendar.badge.plus", message: "No upcoming events", color: .accentBlue)
            } else {
                ForEach(events) { event in
                    HomeEventRow(event: event)
                }
            }
        }
    }

    // MARK: - Points Leaderboard

    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Points Leaderboard", systemImage: "trophy.fill")

            let sorted = rewardsVM.pointsEntries.sorted { $0.totalPoints > $1.totalPoints }
            if sorted.isEmpty {
                EmptyStateCard(icon: "star", message: "Complete tasks to earn points!", color: .accentOrange)
            } else {
                ForEach(Array(sorted.enumerated()), id: \.element.userId) { idx, entry in
                    HomeLeaderboardRow(rank: idx + 1, entry: entry)
                }
            }
        }
    }

    // MARK: - Refresh

    private func refresh() async {
        async let t: () = tasksVM.load(appVM: appVM)
        async let r: () = rewardsVM.load(appVM: appVM)
        async let c: () = calendarVM.load(appVM: appVM)
        async let w: () = weatherVM.fetchWeather()
        _ = await (t, r, c, w)
    }
}

// MARK: - Sub-components

private struct SectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primaryPurple)
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primaryText)
        }
    }
}

private struct EmptyStateCard: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

private struct HomeTaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.completed ? .accentGreen : .secondaryText)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primaryText)
                    .strikethrough(task.completed)
                HStack(spacing: 6) {
                    Text(task.assignee)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Circle().fill(Color.secondary).frame(width: 3, height: 3)
                    Text("\(task.pointsValue) pts")
                        .font(.caption)
                        .foregroundColor(.accentOrange)
                }
            }
            Spacer()
            if task.isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.accentRed)
                    .font(.system(size: 14))
            }
            CategoryBadge(category: task.category)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

private struct HomeEventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(colorFromHex(event.colorHex) ?? .accentBlue)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                Text("\(event.dateLabel) • \(event.timeRangeString)")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    private func colorFromHex(_ hex: String?) -> Color? {
        guard let hex = hex else { return nil }
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard h.count == 6,
              let rgb = UInt64(h, radix: 16) else { return nil }
        return Color(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}

private struct HomeLeaderboardRow: View {
    let rank: Int
    let entry: PointsEntry

    var body: some View {
        HStack(spacing: 12) {
            Text(rankEmoji)
                .font(.system(size: 20))
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primaryText)
                Text(entry.email)
                    .font(.caption2)
                    .foregroundColor(.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.milestoneEmoji) \(entry.totalPoints)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.accentOrange)
                Text(entry.milestoneName)
                    .font(.caption2)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }

    private var rankEmoji: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
}

