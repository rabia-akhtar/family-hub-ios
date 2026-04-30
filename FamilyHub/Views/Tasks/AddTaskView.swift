import SwiftUI

struct AddTaskView: View {

    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var tasksVM: TasksViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: String = AppConfig.taskCategories[0]
    @State private var assignee: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var isSaving: Bool = false

    private var pointsValue: Int {
        AppConfig.pointsForCategory[category.lowercased()] ?? 3
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !assignee.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task name", text: $name)

                    Picker("Category", selection: $category) {
                        ForEach(AppConfig.taskCategories, id: \.self) { cat in
                            Label {
                                Text(cat.capitalized)
                            } icon: {
                                Circle()
                                    .fill(Color.categoryColor(for: cat))
                                    .frame(width: 10, height: 10)
                            }
                            .tag(cat)
                        }
                    }

                    TextField("Assigned to", text: $assignee)
                        .onAppear { assignee = appVM.userDisplayName }
                }

                Section("Points") {
                    HStack {
                        Label("Points awarded", systemImage: "star.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(pointsValue) pts")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.accentOrange)
                    }
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Add") {
                            Task { await save() }
                        }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        let task = TaskItem.new(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            assignee: assignee.trimmingCharacters(in: .whitespaces),
            dueDate: hasDueDate ? dueDate : nil
        )
        await tasksVM.addTask(task, appVM: appVM)
        isSaving = false
        dismiss()
    }
}
