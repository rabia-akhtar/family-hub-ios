import Foundation

@MainActor
final class RewardsViewModel: ObservableObject {

    @Published var rewards: [Reward] = []
    @Published var pointsEntries: [PointsEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Computed

    var availableRewards: [Reward] { rewards.filter { !$0.redeemed } }
    var redeemedRewards:  [Reward] { rewards.filter {  $0.redeemed } }

    func currentEntry(for appVM: AppViewModel) -> PointsEntry? {
        pointsEntries.first { $0.email == appVM.userEmail }
    }

    // MARK: - Load

    func load(appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        isLoading = true
        errorMessage = nil
        do {
            let token = try await appVM.accessToken()
            async let r = appVM.sheetsService.fetchRewards(spreadsheetId: sid, token: token)
            async let p = appVM.sheetsService.fetchPoints(spreadsheetId: sid, token: token)
            (rewards, pointsEntries) = try await (r, p)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Add Reward

    func addReward(_ reward: Reward, appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        isLoading = true
        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.appendRow(
                spreadsheetId: sid,
                sheet: AppConfig.SheetName.rewards,
                values: [reward.toSheetRow()],
                token: token
            )
            rewards.append(reward)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Delete Reward

    func deleteReward(_ reward: Reward, appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }
        rewards.removeAll { $0.id == reward.id }
        do {
            let token = try await appVM.accessToken()
            try await appVM.sheetsService.saveRewards(rewards, spreadsheetId: sid, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Redeem

    func redeem(_ reward: Reward, appVM: AppViewModel) async {
        guard let sid = appVM.spreadsheetId else { return }

        guard let entryIdx = pointsEntries.firstIndex(where: { $0.email == appVM.userEmail }) else {
            errorMessage = "No points entry found for your account."
            return
        }

        let entry = pointsEntries[entryIdx]
        guard entry.totalPoints >= reward.pointsCost else {
            errorMessage = "Not enough points to redeem \"\(reward.name)\"."
            return
        }

        // Optimistic update
        guard let rewardIdx = rewards.firstIndex(where: { $0.id == reward.id }) else { return }
        rewards[rewardIdx].redeemed = true
        let newTotal = entry.totalPoints - reward.pointsCost
        pointsEntries[entryIdx].totalPoints = newTotal

        isLoading = true
        do {
            let token = try await appVM.accessToken()
            // Persist rewards
            try await appVM.sheetsService.saveRewards(rewards, spreadsheetId: sid, token: token)
            // Persist points
            try await appVM.sheetsService.updatePoints(
                userId: appVM.userId,
                displayName: appVM.userDisplayName,
                email: appVM.userEmail,
                newTotal: newTotal,
                spreadsheetId: sid,
                token: token
            )
            successMessage = "Redeemed \"\(reward.name)\"! 🎉"
        } catch {
            // Revert
            rewards[rewardIdx].redeemed = false
            pointsEntries[entryIdx].totalPoints = entry.totalPoints
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
