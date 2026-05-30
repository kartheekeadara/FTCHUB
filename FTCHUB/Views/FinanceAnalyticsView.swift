//
//  FinanceAnalyticsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct FinanceAnalyticsView: View {
    @EnvironmentObject var financeService: FinanceService
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var selectedDate = Date()
    @State private var spendingBudgetDisplayMode = SpendingBudgetDisplayMode.pace
    @State private var spendingTrendRange = SpendingTrendRange.month
    
    enum AnalyticsPeriod {
        case week, month, quarter, year, custom
        
        var displayName: String {
            switch self {
            case .week: return "Week"
            case .month: return "Month"
            case .quarter: return "Quarter"
            case .year: return "Year"
            case .custom: return "Custom"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Period Selector
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Time Period")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach([AnalyticsPeriod.week, .month, .quarter, .year, .custom], id: \.self) { period in
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
                
                // Key Metrics
                KeyMetricsView(period: selectedPeriod, date: selectedDate)
                    .environmentObject(financeService)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Spending & budget
                SpendingBudgetCardView(
                    snapshot: financeService.getSpendingTrendSnapshot(range: spendingTrendRange),
                    displayMode: $spendingBudgetDisplayMode,
                    selectedRange: $spendingTrendRange,
                    showsRangePicker: false
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
                .onAppear {
                    spendingTrendRange = spendingRange(for: selectedPeriod)
                }
                .onChange(of: selectedPeriod) { _, period in
                    spendingTrendRange = spendingRange(for: period)
                }
                
                // Vendor Analysis
                VendorSpendingChartView(
                    vendors: financeService.getVendorSpending()
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Budget Performance
                BudgetPerformanceView()
                    .environmentObject(financeService)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Spending Forecast
                SpendingForecastView()
                    .environmentObject(financeService)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .padding(.vertical, DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func spendingRange(for period: AnalyticsPeriod) -> SpendingTrendRange {
        switch period {
        case .week: return .week
        case .month, .custom: return .month
        case .quarter: return .quarter
        case .year: return .all
        }
    }
}

// MARK: - Key Metrics View

struct KeyMetricsView: View {
    let period: FinanceAnalyticsView.AnalyticsPeriod
    let date: Date
    @EnvironmentObject var financeService: FinanceService
    
    var periodOrders: [Order] {
        let calendar = Calendar.current
        let (startDate, endDate) = dateRangeForPeriod(period, date: date, calendar: calendar)
        
        return financeService.orders.filter { order in
            order.orderDate >= startDate &&
            order.orderDate <= endDate &&
            order.status != .cancelled
        }
    }
    
    var totalSpending: Decimal {
        periodOrders.reduce(Decimal(0)) { $0 + $1.totalAmount }
    }
    
    var averageOrderValue: Decimal {
        guard !periodOrders.isEmpty else { return 0 }
        return totalSpending / Decimal(periodOrders.count)
    }
    
    var orderCount: Int {
        periodOrders.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Key Metrics")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.md) {
                MetricCard(
                    title: "Total Spending",
                    value: "$\(totalSpending.formatted())",
                    icon: "dollarsign.circle.fill",
                    color: DesignSystem.Colors.primary
                )
                
                MetricCard(
                    title: "Order Count",
                    value: "\(orderCount)",
                    icon: "cart.fill",
                    color: DesignSystem.Colors.accent
                )
                
                MetricCard(
                    title: "Avg Order Value",
                    value: "$\(averageOrderValue.formatted())",
                    icon: "chart.bar.fill",
                    color: DesignSystem.Colors.secondary
                )
                
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private func dateRangeForPeriod(_ period: FinanceAnalyticsView.AnalyticsPeriod, date: Date, calendar: Calendar) -> (Date, Date) {
        let endDate = calendar.startOfDay(for: date)
        
        switch period {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) ?? endDate
            return (startDate, endDate)
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
            return (startDate, endDate)
        case .quarter:
            let startDate = calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
            return (startDate, endDate)
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
            return (startDate, endDate)
        case .custom:
            let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            return (startDate, endDate)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Budget Performance View

struct BudgetPerformanceView: View {
    @EnvironmentObject var financeService: FinanceService
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Budget Performance")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if financeService.budgets.isEmpty {
                Text("No budgets to analyze")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.md)
            } else {
                ForEach(financeService.budgets.prefix(3)) { budget in
                    BudgetPerformanceRow(budget: budget, financeService: financeService)
                    
                    if budget.id != financeService.budgets.prefix(3).last?.id {
                        Divider()
                            .background(DesignSystem.Colors.border)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct BudgetPerformanceRow: View {
    let budget: Budget
    let financeService: FinanceService
    
    var actualSpending: Decimal {
        financeService.calculateBudgetSpending(budgetId: budget.id)
    }
    
    var variance: Decimal {
        actualSpending - budget.totalAmount
    }
    
    var variancePercentage: Double {
        guard budget.totalAmount > 0 else { return 0 }
        return Double(truncating: (variance / budget.totalAmount) as NSDecimalNumber) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(budget.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack {
                Text("Budget: $\(budget.totalAmount.formatted())")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text("Actual: $\(actualSpending.formatted())")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(actualSpending > budget.totalAmount ? DesignSystem.Colors.error : DesignSystem.Colors.success)
            }
            
            if variance != 0 {
                HStack {
                    Image(systemName: variance > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .foregroundColor(variance > 0 ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                    
                    Text("\(variance > 0 ? "Over" : "Under") by $\(abs(variance).formatted()) (\(String(format: "%.1f", abs(variancePercentage)))%)")
                        .font(.caption2)
                        .foregroundColor(variance > 0 ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                }
            }
        }
    }
}

// MARK: - Spending Forecast View

struct SpendingForecastView: View {
    @EnvironmentObject var financeService: FinanceService
    
    var forecast: SpendingForecast {
        financeService.getSpendingForecast()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Spending Forecast")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if forecast.monthlyAverage == 0 {
                Text("Not enough data for forecast")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.md)
            } else {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    ForecastRow(
                        label: "Monthly Average",
                        value: "$\(Decimal(forecast.monthlyAverage).formatted())",
                        icon: "calendar"
                    )
                    
                    ForecastRow(
                        label: "Projected This Month",
                        value: "$\(Decimal(forecast.projectedThisMonth).formatted())",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    
                    ForecastRow(
                        label: "Projected This Quarter",
                        value: "$\(Decimal(forecast.projectedThisQuarter).formatted())",
                        icon: "chart.bar.fill"
                    )
                    
                    ForecastRow(
                        label: "Projected This Year",
                        value: "$\(Decimal(forecast.projectedThisYear).formatted())",
                        icon: "calendar.badge.clock"
                    )
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct ForecastRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

#Preview {
    NavigationView {
        FinanceAnalyticsView()
            .environmentObject(FinanceService.shared)
    }
}

