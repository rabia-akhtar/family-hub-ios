import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var appVM:      AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @ObservedObject    var weatherVM:  WeatherViewModel

    // Sheet state
    @State private var showAddMember     = false
    @State private var showAddCategory   = false
    @State private var showAddBudgetCat  = false
    @State private var showAddMilestone  = false

    // New-item inputs
    @State private var newMember    = ""
    @State private var newBudgetCat = ""

    var body: some View {
        NavigationStack {
            List {
                familySection
                taskCategoriesSection
                milestonesSection
                budgetSection
                locationSection
                accountSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddCategory)  { AddCategorySheet() }
            .sheet(isPresented: $showAddMilestone) { AddMilestoneSheet() }
        }
    }

    // MARK: - Family

    private var familySection: some View {
        Section {
            HStack {
                Label("Family Name", systemImage: "house.fill")
                    .foregroundColor(.primaryPurple)
                Spacer()
                TextField("My Family", text: $settingsVM.familyName)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondaryText)
            }

            ForEach($settingsVM.familyMembers, id: \.self) { $member in
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.accentOrange)
                    TextField("Name", text: $member)
                }
            }
            .onDelete { settingsVM.familyMembers.remove(atOffsets: $0) }
            .onMove  { settingsVM.familyMembers.move(fromOffsets: $0, toOffset: $1) }

            if showAddMember {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.green)
                    TextField("Member name", text: $newMember)
                        .submitLabel(.done)
                        .onSubmit { commitNewMember() }
                    Button("Add") { commitNewMember() }
                        .disabled(newMember.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Button {
                showAddMember = true
            } label: {
                Label("Add Family Member", systemImage: "plus")
                    .foregroundColor(.primaryPurple)
            }
        } header: {
            Text("Family")
        }
    }

    private func commitNewMember() {
        let trimmed = newMember.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        settingsVM.familyMembers.append(trimmed)
        newMember = ""
        showAddMember = false
    }

    // MARK: - Task Categories

    private var taskCategoriesSection: some View {
        Section {
            ForEach($settingsVM.taskCategories) { $cat in
                HStack(spacing: 12) {
                    EmojiField(value: $cat.emoji)
                        .frame(width: 36)

                    TextField("Category name", text: $cat.name)

                    Spacer()

                    Stepper("\(cat.pointValue) pts",
                            value: $cat.pointValue,
                            in: 1...100)
                        .fixedSize()
                }
            }
            .onDelete { settingsVM.taskCategories.remove(atOffsets: $0) }
            .onMove   { settingsVM.taskCategories.move(fromOffsets: $0, toOffset: $1) }

            Button {
                showAddCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
                    .foregroundColor(.primaryPurple)
            }
        } header: {
            Text("Task Categories & Points")
        } footer: {
            Text("Tap an emoji to change it. Drag to reorder.")
                .font(.caption)
        }
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        Section {
            ForEach($settingsVM.milestones) { $m in
                HStack(spacing: 12) {
                    EmojiField(value: $m.emoji)
                        .frame(width: 36)

                    TextField("Label", text: $m.label)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.accentOrange)
                        TextField("0", value: $m.threshold, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 55)
                    }
                }
            }
            .onDelete { settingsVM.milestones.remove(atOffsets: $0) }
            .onMove   { settingsVM.milestones.move(fromOffsets: $0, toOffset: $1) }

            Button {
                showAddMilestone = true
            } label: {
                Label("Add Milestone", systemImage: "plus")
                    .foregroundColor(.primaryPurple)
            }
        } header: {
            Text("Reward Milestones")
        } footer: {
            Text("Points threshold at which the milestone badge is awarded.")
                .font(.caption)
        }
    }

    // MARK: - Budget Categories

    private var budgetSection: some View {
        Section {
            ForEach(settingsVM.budgetCategories, id: \.self) { cat in
                Text(cat)
            }
            .onDelete { settingsVM.budgetCategories.remove(atOffsets: $0) }
            .onMove   { settingsVM.budgetCategories.move(fromOffsets: $0, toOffset: $1) }

            if showAddBudgetCat {
                HStack {
                    TextField("Category name", text: $newBudgetCat)
                        .submitLabel(.done)
                        .onSubmit { commitBudgetCat() }
                    Button("Add") { commitBudgetCat() }
                        .disabled(newBudgetCat.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Button {
                showAddBudgetCat = true
            } label: {
                Label("Add Category", systemImage: "plus")
                    .foregroundColor(.primaryPurple)
            }
        } header: {
            Text("Budget Categories")
        }
    }

    private func commitBudgetCat() {
        let trimmed = newBudgetCat.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        settingsVM.budgetCategories.append(trimmed)
        newBudgetCat = ""
        showAddBudgetCat = false
    }

    // MARK: - Location

    private var locationSection: some View {
        Section {
            HStack {
                Label("Location Name", systemImage: "mappin")
                    .foregroundColor(.primaryPurple)
                Spacer()
                TextField("City, State", text: $settingsVM.locationLabel)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondaryText)
            }

            HStack {
                Text("Latitude")
                Spacer()
                TextField("40.7128", value: $settingsVM.locationLatitude, format: .number.precision(.fractionLength(4)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .foregroundColor(.secondaryText)
            }

            HStack {
                Text("Longitude")
                Spacer()
                TextField("-74.0060", value: $settingsVM.locationLongitude, format: .number.precision(.fractionLength(4)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .foregroundColor(.secondaryText)
            }

            Button {
                Task {
                    await weatherVM.setLocation(
                        latitude: settingsVM.locationLatitude,
                        longitude: settingsVM.locationLongitude
                    )
                }
            } label: {
                Label("Refresh Weather", systemImage: "arrow.clockwise")
                    .foregroundColor(.primaryPurple)
            }
        } header: {
            Text("Weather Location")
        } footer: {
            Text("Find lat/lon at maps.google.com — right-click any location.")
                .font(.caption)
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section {
            if let user = appVM.currentUser {
                HStack {
                    Label("Signed in as", systemImage: "person.circle")
                        .foregroundColor(.primaryPurple)
                    Spacer()
                    Text(user.profile?.email ?? "")
                        .foregroundColor(.secondaryText)
                        .font(.footnote)
                }
            }

            Button(role: .destructive) {
                appVM.signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } header: {
            Text("Account")
        }
    }
}

// MARK: - Add Category Sheet

private struct AddCategorySheet: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "📌"
    @State private var points = 5

    var body: some View {
        NavigationStack {
            Form {
                Section("New Category") {
                    HStack {
                        EmojiField(value: $emoji).frame(width: 44)
                        TextField("Category name", text: $name)
                    }
                    Stepper("\(points) points", value: $points, in: 1...100)
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        settingsVM.taskCategories.append(
                            TaskCategoryConfig(name: trimmed, emoji: emoji, pointValue: points)
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Add Milestone Sheet

private struct AddMilestoneSheet: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var emoji = "🎯"
    @State private var threshold = 100

    var body: some View {
        NavigationStack {
            Form {
                Section("New Milestone") {
                    HStack {
                        EmojiField(value: $emoji).frame(width: 44)
                        TextField("Label", text: $label)
                    }
                    HStack {
                        Text("Points threshold")
                        Spacer()
                        TextField("100", value: $threshold, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("Add Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = label.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        settingsVM.milestones.append(
                            MilestoneConfig(threshold: threshold, emoji: emoji, label: trimmed)
                        )
                        dismiss()
                    }
                    .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Emoji TextField helper

private struct EmojiField: View {
    @Binding var value: String

    var body: some View {
        TextField("", text: $value)
            .font(.title2)
            .multilineTextAlignment(.center)
            .onChange(of: value) { _, newVal in
                // Keep only the first character/emoji
                if let first = newVal.unicodeScalars.first {
                    value = String(first.value > 127 ? newVal.prefix(2) : newVal.prefix(1))
                }
            }
    }
}
