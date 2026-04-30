import SwiftUI

struct TasksView: View {

    @EnvironmentObject var appVM:      AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @ObservedObject var tasksVM: TasksViewModel

    @State private var showAddTask = false
    @State private var completionFeedback: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter bar
                filterBar

                if tasksVM.isLoading {
                    Spacer()
                    ProgressView("Loading tasks...")
                    Spacer()
                } else {
                    taskList
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primaryPurple)
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView(tasksVM: tasksVM)
            }
            .overlay(feedbackOverlay)
            .refreshable {
                await tasksVM.load(appVM: appVM)
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All",  isSelected: tasksVM.activeFilter == "all")  {
                    tasksVM.activeFilter = "all"
                }
                FilterChip(title: "Mine", isSelected: tasksVM.activeFilter == "mine") {
                    tasksVM.activeFilter = "mine"
                    tasksVM.selectedAssignee = appVM.userDisplayName
                }
                ForEach(settingsVM.taskCategories) { cat in
                    FilterChip(
                        title: "\(cat.emoji) \(cat.name)",
                        isSelected: tasksVM.activeFilter == cat.name
                    ) {
                        tasksVM.activeFilter = cat.name
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.cardBackground)
    }

    // MARK: - Task List

    private var taskList: some View {
        List {
            // Incomplete Tasks
            if !tasksVM.incompleteTasks.isEmpty {
                Section {
                    ForEach(tasksVM.incompleteTasks) { task in
                        TaskRow(task: task) {
                            Task {
                                await tasksVM.toggleComplete(task, appVM: appVM)
                                showCompletionFeedback(for: task)
                            }
                        }
                        .listRowBackground(Color.cardBackground)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await tasksVM.deleteTask(task, appVM: appVM) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("To Do (\(tasksVM.incompleteTasks.count))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondaryText)
                        .textCase(nil)
                }
            }

            // Completed Tasks
            if !tasksVM.completedTasks.isEmpty {
                Section {
                    ForEach(tasksVM.completedTasks) { task in
                        TaskRow(task: task) {
                            Task { await tasksVM.toggleComplete(task, appVM: appVM) }
                        }
                        .listRowBackground(Color.cardBackground)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await tasksVM.deleteTask(task, appVM: appVM) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Completed (\(tasksVM.completedTasks.count))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondaryText)
                        .textCase(nil)
                }
            }

            if tasksVM.incompleteTasks.isEmpty && tasksVM.completedTasks.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.secondaryText)
                        Text("No tasks yet")
                            .foregroundColor(.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Feedback Overlay

    private var feedbackOverlay: some View {
        Group {
            if let feedback = completionFeedback {
                VStack {
                    Spacer()
                    Text(feedback)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.accentGreen)
                        .cornerRadius(20)
                        .shadow(radius: 8)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(), value: completionFeedback)
            }
        }
    }

    private func showCompletionFeedback(for task: TaskItem) {
        completionFeedback = "+\(task.pointsValue) pts earned! \(settingsVM.milestone(for: task.pointsValue).emoji)"
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            completionFeedback = nil
        }
    }
}

// MARK: - TaskRow

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.completed ? .accentGreen : Color.categoryColor(for: task.category))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(task.completed ? .secondaryText : .primaryText)
                    .strikethrough(task.completed, color: .secondaryText)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(task.assignee, systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondaryText)

                    if let due = task.dueDate {
                        Label(due.relativeLabel(), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .accentRed : .secondaryText)
                    }

                    Text("\(task.pointsValue) pts")
                        .font(.caption)
                        .foregroundColor(.accentOrange)
                }
            }

            Spacer()

            CategoryBadge(category: task.category)
        }
        .padding(.vertical, 4)
        .opacity(task.completed ? 0.6 : 1.0)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.primaryPurple : Color.secondaryCardBackground)
                .cornerRadius(20)
        }
    }
}

// MARK: - CategoryBadge (reused)

struct CategoryBadge: View {
    let category: String

    var body: some View {
        Text(category.capitalized)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.categoryColor(for: category).opacity(0.2))
            .foregroundColor(Color.categoryColor(for: category))
            .cornerRadius(6)
    }
}
