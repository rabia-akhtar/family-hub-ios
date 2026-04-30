import SwiftUI

struct BudgetView: View {

    @EnvironmentObject var appVM: AppViewModel
    @ObservedObject var budgetVM: BudgetViewModel

    @State private var showAddExpense = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Monthly total
                    monthlySummaryCard

                    // Spending by category
                    if !budgetVM.totalByCategory.isEmpty {
                        categoryBreakdownCard
                    }

                    // Recent entries
                    recentEntriesSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddExpense = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.primaryPurple)
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(budgetVM: budgetVM)
            }
            .refreshable {
                await budgetVM.load(appVM: appVM)
            }
        }
    }

    // MARK: - Monthly Summary Card

    private var monthlySummaryCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.homeGradient)

            VStack(spacing: 8) {
                Text(Date().toMonthYearString())
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Text(formatCurrency(budgetVM.currentMonthTotal))
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)

                Text("Total spending this month")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 20) {
                    Text("\(budgetVM.currentMonthEntries.count) transactions")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 2)
            }
            .padding(24)
        }
        .frame(height: 150)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Category")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primaryText)

            ForEach(budgetVM.totalByCategory, id: \.category) { item in
                CategorySpendRow(
                    category: item.category,
                    total: item.total,
                    monthTotal: budgetVM.currentMonthTotal
                )
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Recent Entries

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primaryText)

            if budgetVM.recentEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondaryText)
                    Text("No expenses yet")
                        .foregroundColor(.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.cardBackground)
                .cornerRadius(16)
            } else {
                ForEach(budgetVM.recentEntries) { entry in
                    BudgetEntryRow(entry: entry) {
                        Task { await budgetVM.deleteEntry(entry, appVM: appVM) }
                    }
                }
            }
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Category Spend Row

private struct CategorySpendRow: View {
    let category: String
    let total: Double
    let monthTotal: Double

    private var fraction: Double {
        monthTotal > 0 ? total / monthTotal : 0
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.budgetColor(for: category))
                        .frame(width: 10, height: 10)
                    Text(category)
                        .font(.system(size: 15))
                        .foregroundColor(.primaryText)
                }
                Spacer()
                Text(formatCurrency(total))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primaryText)
                Text(String(format: "%.0f%%", fraction * 100))
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .frame(width: 35, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondaryText.opacity(0.15))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color.budgetColor(for: category))
                        .frame(width: geo.size.width * CGFloat(min(1.0, fraction)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Budget Entry Row

private struct BudgetEntryRow: View {
    let entry: BudgetEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.budgetColor(for: entry.category).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: categoryIcon(entry.category))
                    .font(.system(size: 18))
                    .foregroundColor(Color.budgetColor(for: entry.category))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.description.isEmpty ? entry.category : entry.description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.category)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    Circle().fill(Color.secondary).frame(width: 3, height: 3)
                    Text(entry.date.toDisplayString())
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }

            Spacer()

            Text(entry.formattedAmount)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primaryText)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Groceries":     return "cart.fill"
        case "Dining":        return "fork.knife"
        case "Entertainment": return "tv.fill"
        case "Transport":     return "car.fill"
        case "Health":        return "cross.fill"
        case "Shopping":      return "bag.fill"
        case "Utilities":     return "bolt.fill"
        default:              return "dollarsign.circle.fill"
        }
    }
}
