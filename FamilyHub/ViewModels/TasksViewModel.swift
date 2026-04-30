import Foundation

@MainActor
final class TasksViewModel: ObservableObject {

    @Published var tasks: [TaskItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Filters

    @Published var selectedFilter: TaskFilter = .all
    @Published var selectedAssignee: String = ""

    enum TaskFilter: String, CaseIterable {
        case all    = "All"
        case mine   = "Mine"
        case chore  = "Chores"
        case house  = "House"
        case cats   = "Cats"
        case other  = "Other"
    }

    // MARK: - Computed

    var filteredTasks: [TaskItem] {
        tasks.filter { task in
            switch selectedFilter {
            case .all:   return true
            case .mine:  return task.assignee.lowercased() == selectedAssignee.lowercased()
            case .chore: return task.category.lowercased() == "chore"
            case .house: return task.category.lowercased() == "house"
            case .cats:  return task.category.lowercased() == "cats"
            case .other: return task.category.lowercased() == "other"
            }
        }
    }

    var incompleteTasks: [TaskItem] {
        filteredTasks.filter { !$0.completed }
            .sorted { t1, t2 in
                // Overdue first, then by due date, then by creation
                if t1.isOverdue != t2.isOverdue { return t1.isOverdue }
                if let d1 = t1.dueDate, let d2 = t2.dueDate { return d1 < d2 }
                if t1.dueDate != nil { return true }
                if t2.dueDate != nil { return false }
                return t1.createdAt < t2.createdAt
            }
    }

    var completedTasks: [TaskItem] {
        filteredTasks.filter { $0.completed }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var todayIncompleteTasks: [TaskItem] {
        tasks.filter { !$0.completed && ($0.isDueToday || $0.isOverdue) }
    }

    // MARK: - Load

    func load(appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        isLoading = true
        errorMessage = nil
        do {
            let token = try await appVM.accessToken()
            tasks = try await appVM.sheetsService.fetchTasks(spreadsheetId: sid, token: token)
            selectedAssignee = appVM.userDisplayName
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Add Task

    func addTask(_ task: TaskItem, appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        isLoading = true
        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.appendRow(
                spreadsheetId: sid,
                sheet: AppConfig.SheetName.tasks,
                values: [task.toSheetRow()],
                token: token
            )
            tasks.append(task)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Toggle Complete

    func toggleComplete(_ task: TaskItem, appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId,
              let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        var updated = tasks[idx]
        let wasCompleted = updated.completed
        updated.completed = !wasCompleted
        tasks[idx] = updated

        do {
            let token = try await appVM.accessToken()

            // Save updated tasks
            try await appVM.sheetsService.saveTasks(tasks, spreadsheetId: sid, token: token)

            // Award or revoke points for the task's assignee
            let assigneeEmail = appVM.userEmail
            let currentPoints = try await fetchCurrentPoints(email: assigneeEmail, appVM: appVM)
            let delta = wasCompleted ? -updated.pointsValue : updated.pointsValue
            let newTotal = max(0, currentPoints + delta)

            try await appVM.sheetsService.updatePoints(
                userId: appVM.userId,
                displayName: appVM.userDisplayName,
                email: assigneeEmail,
                newTotal: newTotal,
                spreadsheetId: sid,
                token: token
            )
        } catch {
            // Revert optimistic update
            tasks[idx].completed = wasCompleted
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Task

    func deleteTask(_ task: TaskItem, appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        tasks.removeAll { $0.id == task.id }
        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.saveTasks(tasks, spreadsheetId: sid, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func fetchCurrentPoints(email: String, appVM: AppViewModel) async throws -> Int {
        guard let sid = appVM.spreadsheetId else { return 0 }
        let token   = try await appVM.accessToken()
        let entries = try await appVM.sheetsService.fetchPoints(spreadsheetId: sid, token: token)
        return entries.first(where: { $0.email == email })?.totalPoints ?? 0
    }
}
