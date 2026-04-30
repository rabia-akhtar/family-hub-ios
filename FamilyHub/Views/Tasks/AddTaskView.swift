import SwiftUI

struct AddTaskView: View {

    @EnvironmentObject var appVM:      AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @ObservedObject var tasksVM: TasksViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: String = ""
    @State private var assignee: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Date()
    @State private var isSaving: Bool = false

    private var pointsValue: Int {
        settingsVM.pointValue(for: category)
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
                        .onAppear {
                            if category.isEmpty {
                                category = settingsVM.taskCategories.first?.name ?? "Other"
                            }
                        }

                    Picker("Category", selection: $category) {
                        ForEach(settingsVM.taskCategories) { cat in
                            Label {
                                Text(cat.name)
                            } icon: {
                                Text(cat.emoji)
                            }
                            .tag(cat.name)
                        }
                    }

                    Picker("Assigned to", selection: $assignee) {
                        ForEach(settingsVM.familyMembers, id: \.self) { member in
                            Text(member).tag(member)
                        }
                    }
                    .onAppear {
                        // Default to the signed-in user if their name is in the list
                        let name = appVM.userDisplayName
                        assignee = settingsVM.familyMembers.first(where: { $0 == name })
                            ?? settingsVM.familyMembers.first ?? name
                    }
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
