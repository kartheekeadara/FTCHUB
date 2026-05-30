//
//  FinanceCharts.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI
import Charts

// MARK: - Spending & Budget Card

enum SpendingTrendRange: String, CaseIterable, Identifiable {
    case week, month, quarter, all
    
    var id: String { rawValue }
    
    var shortLabel: String {
        switch self {
        case .week: return "7D"
        case .month: return "30D"
        case .quarter: return "90D"
        case .all: return "All"
        }
    }
}

enum SpendingBudgetDisplayMode: String, CaseIterable {
    case pace = "Budget pace"
    case activity = "Activity"
}

struct BudgetPacePoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulativeSpent: Double
}

struct SpendingTrendSnapshot {
    let range: SpendingTrendRange
    let rangeStart: Date
    let rangeEnd: Date
    let activityBuckets: [SpendingDataPoint]
    let pacePoints: [BudgetPacePoint]
    let budgetCap: Decimal
    let totalSpentInRange: Decimal
    let orderCountInRange: Int
    let percentOfBudgetUsed: Double?
    let hasBudgets: Bool
    
    var subtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let start = formatter.string(from: rangeStart)
        let end = formatter.string(from: rangeEnd)
        let orderLabel = orderCountInRange == 1 ? "order" : "orders"
        return "\(start) – \(end) · \(orderCountInRange) \(orderLabel)"
    }
    
    var isEffectivelyEmpty: Bool {
        activityBuckets.isEmpty || (activityBuckets.allSatisfy { $0.value == 0 } && pacePoints.allSatisfy { $0.cumulativeSpent == 0 })
    }
    
    var remainingBudget: Decimal {
        max(0, budgetCap - totalSpentInRange)
    }
    
    var isOverBudget: Bool {
        budgetCap > 0 && totalSpentInRange > budgetCap
    }
}

struct SpendingBudgetCardView: View {
    let snapshot: SpendingTrendSnapshot
    @Binding var displayMode: SpendingBudgetDisplayMode
    @Binding var selectedRange: SpendingTrendRange
    var showsRangePicker: Bool = true
    var onRequestBudgets: (() -> Void)? = nil
    
    @State private var selectedDate: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var budgetCapDouble: Double {
        Double(truncating: snapshot.budgetCap as NSDecimalNumber)
    }
    
    private var spentDouble: Double {
        Double(truncating: snapshot.totalSpentInRange as NSDecimalNumber)
    }
    
    private var chartYMax: Double {
        let cap = budgetCapDouble
        let peak = snapshot.pacePoints.map(\.cumulativeSpent).max() ?? spentDouble
        return max(cap, peak, 1) * 1.1
    }
    
    private var showPaceUnavailable: Bool {
        displayMode == .pace && (!snapshot.hasBudgets || snapshot.budgetCap == 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            headerSection
            if showsRangePicker {
                rangePicker
            }
            modeToggle
            
            if snapshot.isEffectivelyEmpty {
                SpendingTrendEmptyState(rangeLabel: selectedRange.shortLabel)
            } else if showPaceUnavailable {
                paceUnavailableState
            } else {
                compactStatsRow
                chartSection
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.25), value: selectedRange)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.25), value: displayMode)
    }
    
    private var headerSection: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Spending & budget")
                    .font(.title3.weight(.bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(snapshot.subtitle)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
    }
    
    private var rangePicker: some View {
        SegmentedPillToggle(
            segments: SpendingTrendRange.allCases.map { range in
                SegmentedPillSegment(id: range.rawValue, title: range.shortLabel)
            },
            selectedID: Binding(
                get: { selectedRange.rawValue },
                set: { newID in
                    if let match = SpendingTrendRange.allCases.first(where: { $0.rawValue == newID }) {
                        selectedRange = match
                        DesignSystem.Haptics.selection()
                    }
                }
            )
        )
        .accessibilityLabel("Time range")
    }
    
    private var modeToggle: some View {
        SpendingBudgetModePillToggle(displayMode: $displayMode)
    }
    
    private var compactStatsRow: some View {
        HStack(spacing: 0) {
            statColumn(
                label: "Spent",
                value: FinanceChartFormat.currency(snapshot.totalSpentInRange),
                color: DesignSystem.Colors.textPrimary
            )
            Divider().frame(height: 36)
            statColumn(
                label: "Used",
                value: snapshot.percentOfBudgetUsed.map { String(format: "%.0f%%", $0) } ?? "—",
                color: snapshot.isOverBudget ? DesignSystem.Colors.error : DesignSystem.Colors.success
            )
            Divider().frame(height: 36)
            statColumn(
                label: "Left",
                value: snapshot.budgetCap > 0
                    ? FinanceChartFormat.currency(snapshot.remainingBudget)
                    : "—",
                color: DesignSystem.Colors.textPrimary
            )
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.tertiaryBackground.opacity(0.6))
        )
    }
    
    private func statColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var chartSection: some View {
        ZStack(alignment: .top) {
            Group {
                if displayMode == .pace {
                    paceChart
                } else {
                    activityChart
                }
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            
            if let annotation = selectionAnnotation {
                chartAnnotation(annotation)
                    .padding(.top, DesignSystem.Spacing.xs)
            }
        }
    }
    
    private var paceUnavailableState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.largeTitle)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text("Add a budget to track pace")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text("Budget pace compares spending to your total budget cap over time.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
            if onRequestBudgets != nil {
                Button("View budgets") {
                    onRequestBudgets?()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.primary)
            }
            Button("Show activity") {
                displayMode = .activity
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
    
    private var paceChart: some View {
        let cap = budgetCapDouble
        let overBudget = snapshot.isOverBudget
        let lineColor = overBudget ? DesignSystem.Colors.error : DesignSystem.Colors.primary
        
        return Chart {
            if cap > 0 {
                RuleMark(y: .value("Budget cap", cap))
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Budget cap")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
            }
            
            ForEach(snapshot.pacePoints) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Spent", point.cumulativeSpent)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            lineColor.opacity(overBudget ? 0.35 : 0.22),
                            lineColor.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.stepCenter)
                
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Spent", point.cumulativeSpent)
                )
                .foregroundStyle(lineColor)
                .interpolationMethod(.stepCenter)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }
            
            if let selectedDate {
                RuleMark(x: .value("Selected", selectedDate))
                    .foregroundStyle(DesignSystem.Colors.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartYScale(domain: 0...chartYMax)
        .chartXAxis { spendingXAxis }
        .chartYAxis { spendingYAxisContent(compact: true) }
        .chartXSelection(value: $selectedDate)
        .chartPlotStyle { $0.padding(.horizontal, 8) }
        .accessibilityLabel(paceAccessibilityLabel)
    }
    
    private var activityChart: some View {
        Chart(snapshot.activityBuckets) { point in
            BarMark(
                x: .value("Date", point.date),
                y: .value("Amount", point.value)
            )
            .foregroundStyle(
                point.value > 0
                    ? DesignSystem.Colors.primary
                    : DesignSystem.Colors.primary.opacity(0.15)
            )
            .cornerRadius(3)
            
            if let selectedDate {
                RuleMark(x: .value("Selected", selectedDate))
                    .foregroundStyle(DesignSystem.Colors.textTertiary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
        .chartXAxis { spendingXAxis }
        .chartYAxis { spendingYAxisContent(compact: true) }
        .chartXSelection(value: $selectedDate)
        .chartPlotStyle { $0.padding(.horizontal, 8) }
        .accessibilityLabel(activityAccessibilityLabel)
    }
    
    @AxisContentBuilder
    private var spendingXAxis: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(DesignSystem.Colors.border.opacity(0.3))
            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                .foregroundStyle(DesignSystem.Colors.textTertiary)
        }
    }
    
    @AxisContentBuilder
    private func spendingYAxisContent(compact: Bool) -> some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(DesignSystem.Colors.border.opacity(0.3))
            AxisValueLabel {
                if let amount = value.as(Double.self) {
                    Text(compact ? FinanceChartFormat.compactCurrency(amount) : FinanceChartFormat.currency(amount))
                        .font(.caption2)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
    }
    
    private var selectionAnnotation: (date: Date, amount: String)? {
        guard let selectedDate else { return nil }
        if displayMode == .pace {
            guard let point = nearestPacePoint(to: selectedDate) else { return nil }
            return (point.date, FinanceChartFormat.currency(point.cumulativeSpent))
        } else {
            guard let point = nearestActivityPoint(to: selectedDate) else { return nil }
            return (point.date, FinanceChartFormat.currency(point.value))
        }
    }
    
    private func chartAnnotation(_ info: (date: Date, amount: String)) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Text(FinanceChartFormat.shortDate(info.date))
                .font(.caption2.weight(.medium))
            Text(info.amount)
                .font(.caption.weight(.bold))
        }
        .foregroundColor(DesignSystem.Colors.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(DesignSystem.Colors.tertiaryBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.15), radius: 4, y: 2)
        )
    }
    
    private func nearestPacePoint(to date: Date) -> BudgetPacePoint? {
        snapshot.pacePoints.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private func nearestActivityPoint(to date: Date) -> SpendingDataPoint? {
        snapshot.activityBuckets.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private var paceAccessibilityLabel: String {
        let spent = FinanceChartFormat.currency(snapshot.totalSpentInRange)
        if let pct = snapshot.percentOfBudgetUsed {
            return "Budget pace, spent \(spent), \(Int(pct)) percent of budget used"
        }
        return "Budget pace, spent \(spent)"
    }
    
    private var activityAccessibilityLabel: String {
        "Spending activity, \(snapshot.orderCountInRange) orders in range"
    }
}

// MARK: - Spending Budget Controls

private struct SpendingBudgetModePillToggle: View {
    @Binding var displayMode: SpendingBudgetDisplayMode
    @Namespace private var animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(SpendingBudgetDisplayMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(reduceMotion ? .none : DesignSystem.Motion.spring(response: 0.30, dampingFraction: 0.78)) {
                        displayMode = mode
                    }
                    DesignSystem.Haptics.selection()
                } label: {
                    Text(mode.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(displayMode == mode ? DesignSystem.Colors.textOnPrimary : DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            if displayMode == mode {
                                Capsule()
                                    .fill(DesignSystem.Gradients.primary)
                                    .matchedGeometryEffect(id: "spendingBudgetMode", in: animation)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(displayMode == mode ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(DesignSystem.Colors.tertiaryBackground))
        .accessibilityLabel("Chart display mode")
    }
}

private enum FinanceChartFormat {
    static func currency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = value >= 1000 ? 0 : 2
        return f.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    static func currency(_ value: Decimal) -> String {
        currency(Double(truncating: value as NSDecimalNumber))
    }
    
    static func compactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        }
        if value >= 1000 {
            return String(format: "$%.1fk", value / 1000)
        }
        return currency(value)
    }
    
    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

private struct SpendingTrendEmptyState: View {
    var rangeLabel: String = ""
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("No spending in this range")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.lg)
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    private var emptyMessage: String {
        if rangeLabel.isEmpty {
            return "Add orders with dates in the selected window. Cancelled orders are excluded."
        }
        return "No orders in the last \(rangeLabel) window. Try a wider range or add orders."
    }
}

// MARK: - Category Breakdown Chart

struct CategoryBreakdownChartView: View {
    let categories: [CategorySpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if categories.isEmpty {
                EmptyChartView(message: "No category data available")
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(categories.prefix(5)) { category in
                        CategorySpendingRow(category: category, maxAmount: categories.first?.amount ?? 1)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct CategorySpendingRow: View {
    let category: CategorySpending
    let maxAmount: Double
    
    private var percentage: Double {
        maxAmount > 0 ? (category.amount / maxAmount) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("$\(Decimal(category.amount).formatted())")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: geometry.size.width * CGFloat(max(0, min(1, percentage / 100))), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Vendor Spending Chart

struct VendorSpendingChartView: View {
    let vendors: [VendorSpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                Text("Spending by Vendor")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            if vendors.isEmpty {
                EmptyChartView(message: "No vendor data available")
            } else {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(vendors.prefix(5)) { vendor in
                        VendorSpendingRow(vendor: vendor, maxAmount: vendors.first?.amount ?? 1)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

struct VendorSpendingRow: View {
    let vendor: VendorSpending
    let maxAmount: Double
    
    private var percentage: Double {
        maxAmount > 0 ? (vendor.amount / maxAmount) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(vendor.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(Decimal(vendor.amount).formatted())")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "cart.fill")
                            .font(.caption2)
                        Text("\(vendor.orderCount) orders")
                            .font(.caption)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.accent, DesignSystem.Colors.accent.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(max(0, min(1, percentage / 100))), height: 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
                }
            }
            .frame(height: 10)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

// MARK: - Supporting Types

struct SpendingDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct CategorySpending: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
}

struct VendorSpending: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let orderCount: Int
}

// MARK: - Empty Chart View

struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.title2)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text(message)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
    }
}

// MARK: - String Extension

extension String {
    func truncated(to length: Int) -> String {
        guard count > length else { return self }
        return String(prefix(length)) + "..."
    }
}

#Preview {
    struct SpendingBudgetPreview: View {
        @State private var mode = SpendingBudgetDisplayMode.pace
        @State private var range = SpendingTrendRange.month
        
        private var sampleSnapshot: SpendingTrendSnapshot {
            let buckets: [SpendingDataPoint] = [
                SpendingDataPoint(date: Date().addingTimeInterval(-86400 * 6), value: 400),
                SpendingDataPoint(date: Date().addingTimeInterval(-86400 * 5), value: 0),
                SpendingDataPoint(date: Date().addingTimeInterval(-86400 * 4), value: 1200),
                SpendingDataPoint(date: Date().addingTimeInterval(-86400 * 3), value: 0),
                SpendingDataPoint(date: Date().addingTimeInterval(-86400 * 2), value: 800),
                SpendingDataPoint(date: Date().addingTimeInterval(-86400 * 1), value: 350),
                SpendingDataPoint(date: Date(), value: 220)
            ]
            var running = 0.0
            let pace = buckets.map { b -> BudgetPacePoint in
                running += b.value
                return BudgetPacePoint(date: b.date, cumulativeSpent: running)
            }
            return SpendingTrendSnapshot(
                range: .month,
                rangeStart: Date().addingTimeInterval(-86400 * 6),
                rangeEnd: Date(),
                activityBuckets: buckets,
                pacePoints: pace,
                budgetCap: 20_000,
                totalSpentInRange: 3_970,
                orderCountInRange: 12,
                percentOfBudgetUsed: 19.85,
                hasBudgets: true
            )
        }
        
        var body: some View {
            SpendingBudgetCardView(
                snapshot: sampleSnapshot,
                displayMode: $mode,
                selectedRange: $range
            )
            .padding()
        }
    }
    return SpendingBudgetPreview()
}

