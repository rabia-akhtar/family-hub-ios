import SwiftUI

struct RewardsView: View {

    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var rewardsVM: RewardsViewModel

    @State private var showAddReward = false

    private var currentEntry: PointsEntry? {
        rewardsVM.currentEntry(for: appVM)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Points summary card
                    if let entry = currentEntry {
                        pointsSummaryCard(entry: entry)
                    }

                    // Available rewards
                    if !rewardsVM.availableRewards.isEmpty {
                        rewardsList(rewards: rewardsVM.availableRewards, section: "Available Rewards")
                    }

                    // Redeemed rewards
                    if !rewardsVM.redeemedRewards.isEmpty {
                        rewardsList(rewards: rewardsVM.redeemedRewards, section: "Redeemed")
                    }

                    if rewardsVM.availableRewards.isEmpty && rewardsVM.redeemedRewards.isEmpty && !rewardsVM.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "gift")
                                .font(.system(size: 48))
                                .foregroundColor(.secondaryText)
                            Text("No rewards yet")
                                .foregroundColor(.secondaryText)
                            Text("Add rewards that family members can redeem with points!")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Rewards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddReward = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primaryPurple)
                    }
                }
            }
            .sheet(isPresented: $showAddReward) {
                AddRewardView(rewardsVM: rewardsVM)
            }
            .alert("Redeemed!", isPresented: Binding(
                get: { rewardsVM.successMessage != nil },
                set: { if !$0 { rewardsVM.successMessage = nil } }
            )) {
                Button("Great!") { rewardsVM.successMessage = nil }
            } message: {
                Text(rewardsVM.successMessage ?? "")
            }
            .alert("Cannot Redeem", isPresented: Binding(
                get: { rewardsVM.errorMessage != nil },
                set: { if !$0 { rewardsVM.errorMessage = nil } }
            )) {
                Button("OK") { rewardsVM.errorMessage = nil }
            } message: {
                Text(rewardsVM.errorMessage ?? "")
            }
            .refreshable {
                await rewardsVM.load(appVM: appVM)
            }
        }
    }

    // MARK: - Points Summary Card

    private func pointsSummaryCard(entry: PointsEntry) -> some View {
        let milestone = AppConfig.milestone(for: entry.totalPoints)
        let nextTarget = entry.nextMilestone
        let progress = entry.milestoneProgress

        return ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.homeGradient)

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Points")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        HStack(alignment: .bottom, spacing: 8) {
                            Text("\(entry.totalPoints)")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundColor(.white)
                            Text("pts")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.bottom, 6)
                        }
                    }
                    Spacer()
                    Text(milestone.emoji)
                        .font(.system(size: 52))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(milestone.label)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        if nextTarget > milestone.threshold {
                            Text("\(nextTarget - entry.totalPoints) pts to next milestone")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Max milestone reached!")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 8)
                            Capsule()
                                .fill(Color.white)
                                .frame(width: geo.size.width * min(1.0, progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(20)
        }
        .frame(height: 160)
    }

    // MARK: - Rewards List

    private func rewardsList(rewards: [Reward], section: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primaryText)

            ForEach(rewards) { reward in
                RewardCard(
                    reward: reward,
                    currentPoints: currentEntry?.totalPoints ?? 0,
                    isRedeemed: reward.redeemed
                ) {
                    Task { await rewardsVM.redeem(reward, appVM: appVM) }
                } onDelete: {
                    Task { await rewardsVM.deleteReward(reward, appVM: appVM) }
                }
            }
        }
    }
}

// MARK: - Reward Card

private struct RewardCard: View {
    let reward: Reward
    let currentPoints: Int
    let isRedeemed: Bool
    let onRedeem: () -> Void
    let onDelete: () -> Void

    private var canAfford: Bool {
        !isRedeemed && currentPoints >= reward.pointsCost
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isRedeemed ? Color.secondaryText.opacity(0.15) : Color.accentOrange.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: isRedeemed ? "checkmark.seal.fill" : "gift.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isRedeemed ? .secondaryText : .accentOrange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isRedeemed ? .secondaryText : .primaryText)
                if !reward.description.isEmpty {
                    Text(reward.description)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .lineLimit(2)
                }
                Text("\(reward.pointsCost) points")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(canAfford ? .accentGreen : (isRedeemed ? .secondaryText : .accentRed))
            }

            Spacer()

            if isRedeemed {
                Text("Redeemed")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            } else {
                Button(action: onRedeem) {
                    Text("Redeem")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(canAfford ? .white : .secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(canAfford ? Color.primaryPurple : Color.secondaryCardBackground)
                        .cornerRadius(8)
                }
                .disabled(!canAfford)
            }
        }
        .padding(14)
        .background(Color.cardBackground)
        .cornerRadius(14)
        .opacity(isRedeemed ? 0.7 : 1.0)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
