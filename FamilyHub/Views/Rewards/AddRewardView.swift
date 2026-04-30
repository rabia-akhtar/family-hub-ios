import SwiftUI

struct AddRewardView: View {

    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var rewardsVM: RewardsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var pointsCostText: String = ""
    @State private var description: String = ""
    @State private var isSaving: Bool = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        Int(pointsCostText) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reward Details") {
                    TextField("Reward name", text: $name)

                    HStack {
                        Text("Points cost")
                        Spacer()
                        TextField("0", text: $pointsCostText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentBlue)
                        Text("Family members can redeem this reward by spending their earned points.")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .navigationTitle("New Reward")
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
        guard let cost = Int(pointsCostText) else { return }
        isSaving = true
        let reward = Reward.new(
            name: name.trimmingCharacters(in: .whitespaces),
            pointsCost: cost,
            description: description.trimmingCharacters(in: .whitespaces)
        )
        await rewardsVM.addReward(reward, appVM: appVM)
        isSaving = false
        dismiss()
    }
}
