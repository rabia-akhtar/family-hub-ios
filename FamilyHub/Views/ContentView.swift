import SwiftUI

struct ContentView: View {

    @EnvironmentObject var appVM:      AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel

    @StateObject private var tasksVM     = TasksViewModel()
    @StateObject private var rewardsVM   = RewardsViewModel()
    @StateObject private var calendarVM  = CalendarViewModel()
    @StateObject private var weatherVM   = WeatherViewModel()
    @StateObject private var groceriesVM = GroceriesViewModel()
    @StateObject private var budgetVM    = BudgetViewModel()

    @State private var selectedTab: Int = 0
    @State private var showSetupOverlay: Bool = true   // auto-clears after timeout

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView(
                tasksVM: tasksVM,
                calendarVM: calendarVM,
                weatherVM: weatherVM,
                rewardsVM: rewardsVM
            )
            .tabItem {
                Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
            }
            .tag(0)

            TasksView(tasksVM: tasksVM)
                .tabItem {
                    Label("Tasks", systemImage: selectedTab == 1 ? "checkmark.circle.fill" : "checkmark.circle")
                }
                .tag(1)

            RewardsView(rewardsVM: rewardsVM)
                .tabItem {
                    Label("Rewards", systemImage: selectedTab == 2 ? "gift.fill" : "gift")
                }
                .tag(2)

            CalendarView(calendarVM: calendarVM)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(3)

            WeatherView(weatherVM: weatherVM)
                .tabItem {
                    Label("Weather", systemImage: selectedTab == 4 ? "cloud.sun.fill" : "cloud.sun")
                }
                .tag(4)

            GroceriesView(groceriesVM: groceriesVM)
                .tabItem {
                    Label("Groceries", systemImage: selectedTab == 5 ? "cart.fill" : "cart")
                }
                .tag(5)

            BudgetView(budgetVM: budgetVM)
                .tabItem {
                    Label("Budget", systemImage: selectedTab == 6 ? "dollarsign.circle.fill" : "dollarsign.circle")
                }
                .tag(6)

            SettingsView(weatherVM: weatherVM)
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 7 ? "gearshape.fill" : "gearshape")
                }
                .tag(7)
        }
        .environmentObject(appVM)
        .environmentObject(settingsVM)
        .tint(.primaryPurple)
        .task {
            // Auto-dismiss the setup overlay after 10 seconds no matter what
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                showSetupOverlay = false
            }
            await waitForSpreadsheet()
            showSetupOverlay = false
            await loadAllData()
        }
        .alert("Error", isPresented: Binding(
            get: { appVM.errorMessage != nil },
            set: { if !$0 { appVM.errorMessage = nil } }
        )) {
            Button("OK") { appVM.errorMessage = nil }
        } message: {
            Text(appVM.errorMessage ?? "")
        }
        .overlay {
            if showSetupOverlay && appVM.isLoading && appVM.spreadsheetId == nil {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Setting up your Family Hub...")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }

    private func waitForSpreadsheet() async {
        // Poll until spreadsheet is available (setup runs in parallel)
        var attempts = 0
        while appVM.spreadsheetId == nil && attempts < 20 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            attempts += 1
        }
    }

    private func loadAllData() async {
        async let t: () = tasksVM.load(appVM: appVM)
        async let r: () = rewardsVM.load(appVM: appVM)
        async let c: () = calendarVM.load(appVM: appVM)
        async let g: () = groceriesVM.load(appVM: appVM)
        async let b: () = budgetVM.load(appVM: appVM)
        _ = await (t, r, c, g, b)
    }
}
