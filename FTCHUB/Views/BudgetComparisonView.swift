//
//  BudgetComparisonView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct BudgetComparisonView: View {
    @EnvironmentObject var financeService: FinanceService
    @State private var selectedPeriod: ComparisonPeriod = .month
    @State private var selectedDate = Date()
    
    enum ComparisonPeriod {
        case month, quarter, year, custom
        
        var displayName: String {
            switch self {
            case .month: return "Month"
            case .quarter: return "Quarter"
            case .year: return "Year"
            case .custom: return "Custom"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Period Selector
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Comparison Period")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach([ComparisonPeriod.month, .quarter, .year, .custom], id: \.self) { period in
                                Text(period.displayName).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        if selectedPeriod == .custom {
                            DatePicker("Start Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Current vs Previous Period
                    if let comparison = getPeriodComparison() {
                        ComparisonSummaryCard(comparison: comparison)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Budget Breakdown Comparison
                        BudgetBreakdownComparisonView(comparison: comparison)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                    } else {
                        // Show current period data even if no previous period
                        CurrentPeriodSummaryView()
                            .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Budget Comparison")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func getPeriodComparison() -> BudgetPeriodComparison? {
        let calendar = Calendar.current
        let (currentStart, currentEnd) = dateRangeForPeriod(selectedPeriod, date: selectedDate, calendar: calendar)
        
        // Calculate previous period
        let previousEnd = currentStart.addingTimeInterval(-1)
        let previousStart: Date
        switch selectedPeriod {
        case .month:
            previousStart = calendar.date(byAdding: .month, value: -1, to: currentStart) ?? currentStart
        case .quarter:
            previousStart = calendar.date(byAdding: .month, value: -3, to: currentStart) ?? currentStart
        case .year:
            previousStart = calendar.date(byAdding: .year, value: -1, to: currentStart) ?? currentStart
        case .custom:
            let duration = currentEnd.timeIntervalSince(currentStart)
            previousStart = currentStart.addingTimeInterval(-duration)
        }
        
        let currentPeriodOrders = financeService.orders.filter { order in
            order.orderDate >= currentStart &&
            order.orderDate <= currentEnd &&
            order.status != .cancelled
        }
        
        let previousPeriodOrders = financeService.orders.filter { order in
            order.orderDate >= previousStart &&
            order.orderDate <= previousEnd &&
            order.status != .cancelled
        }
        
        let currentSpending = currentPeriodOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
        let previousSpending = previousPeriodOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
        
        // Always return comparison, even if previous period has no data
        return BudgetPeriodComparison(
            currentPeriod: PeriodData(
                startDate: currentStart,
                endDate: currentEnd,
                spending: currentSpending,
                orderCount: currentPeriodOrders.count
            ),
            previousPeriod: PeriodData(
                startDate: previousStart,
                endDate: previousEnd,
                spending: previousSpending,
                orderCount: previousPeriodOrders.count
            )
        )
    }
    
    private func dateRangeForPeriod(_ period: ComparisonPeriod, date: Date, calendar: Calendar) -> (Date, Date) {
        let endDate = calendar.startOfDay(for: date)
        
        switch period {
        case .month:
            let monthComponents = calendar.dateComponents([.year, .month], from: endDate)
            let startDate = calendar.date(from: monthComponents) ?? endDate
            return (startDate, endDate)
        case .quarter:
            let month = calendar.component(.month, from: endDate)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year, .month], from: endDate)
            components.month = quarterStartMonth
            let startDate = calendar.date(from: components) ?? endDate
            return (startDate, endDate)
        case .year:
            let startDate = calendar.date(from: calendar.dateComponents([.year], from: endDate)) ?? endDate
            return (startDate, endDate)
        case .custom:
            let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            return (startDate, endDate)
        }
    }
}

// MARK: - Comparison Models

struct BudgetPeriodComparison {
    let currentPeriod: PeriodData
    let previousPeriod: PeriodData
    
    var spendingChange: Decimal {
        currentPeriod.spending - previousPeriod.spending
    }
    
    var spendingChangePercent: Double {
        guard previousPeriod.spending > 0 else { return 0 }
        return Double(truncating: (spendingChange / previousPeriod.spending * 100) as NSDecimalNumber)
    }
    
    var orderCountChange: Int {
        currentPeriod.orderCount - previousPeriod.orderCount
    }
    
    var isSpendingIncrease: Bool {
        spendingChange > 0
    }
}

struct PeriodData {
    let startDate: Date
    let endDate: Date
    let spending: Decimal
    let orderCount: Int
}

struct ComparisonSummaryCard: View {
    let comparison: BudgetPeriodComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Period Comparison")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Current Period
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Current Period")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                HStack {
                    Text("$\(comparison.currentPeriod.spending.formatted())")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(comparison.currentPeriod.orderCount) orders")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Text(formatDateRange(comparison.currentPeriod.startDate, comparison.currentPeriod.endDate))
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // Previous Period
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Previous Period")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                HStack {
                    Text("$\(comparison.previousPeriod.spending.formatted())")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(comparison.previousPeriod.orderCount) orders")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Text(formatDateRange(comparison.previousPeriod.startDate, comparison.previousPeriod.endDate))
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            
            // Change Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: comparison.isSpendingIncrease ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                            .foregroundColor(comparison.isSpendingIncrease ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                        
                        Text("$\(abs(comparison.spendingChange).formatted())")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(comparison.isSpendingIncrease ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Percentage Change")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(String(format: "%.1f", abs(comparison.spendingChangePercent)))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(comparison.isSpendingIncrease ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(comparison.isSpendingIncrease ? DesignSystem.Colors.error.opacity(0.1) : DesignSystem.Colors.success.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

struct BudgetBreakdownComparisonView: View {
    let comparison: BudgetPeriodComparison
    @EnvironmentObject var financeService: FinanceService
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Budget vs Actual")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Show budget comparison if budgets exist
            if !financeService.budgets.isEmpty {
                let totalBudget = financeService.budgets.reduce(Decimal(0)) { $0 + $1.totalAmount }
                let budgetUsed = comparison.currentPeriod.spending
                let budgetRemaining = totalBudget - budgetUsed
                let budgetPercentage = totalBudget > 0 ? Double(truncating: (budgetUsed / totalBudget * 100) as NSDecimalNumber) : 0
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Text("Total Budget")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(totalBudget.formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Spent This Period")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(budgetUsed.formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(budgetUsed > totalBudget ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary)
                    }
                    
                    HStack {
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text("$\(budgetRemaining.formatted())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(budgetRemaining < 0 ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                    }
                    
                    ProgressView(value: budgetPercentage, total: 100)
                        .progressViewStyle(.linear)
                        .tint(budgetUsed > totalBudget ? DesignSystem.Colors.error : DesignSystem.Colors.primary)
                        .frame(height: 8)
                    
                    Text("\(String(format: "%.1f", budgetPercentage))% of budget used")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
            } else {
                Text("No budgets created yet")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.tertiaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct CurrentPeriodSummaryView: View {
    @EnvironmentObject var financeService: FinanceService
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            let currentOrders = financeService.orders.filter { $0.status != .cancelled }
            let totalSpending = currentOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Text("Current Period Summary")
                    .font(.headline)
                Text("$\(totalSpending.formatted()) spent across \(currentOrders.count) orders")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
    }
}

#Preview {
    BudgetComparisonView()
        .environmentObject(FinanceService.shared)
}

