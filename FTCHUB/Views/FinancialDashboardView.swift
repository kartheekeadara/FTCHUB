//
//  FinancialDashboardView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct FinancialDashboardView: View {
    @EnvironmentObject var financeService: FinanceService
    @EnvironmentObject var teamService: TeamService
    @State private var selectedTab: FinanceTab = .overview
    @State private var showingAddOrder = false
    @State private var showingAddBudget = false
    @State private var orderToDelete: Order? = nil
    @State private var budgetToDelete: Budget? = nil
    @State private var showingDeleteOrderConfirmation = false
    @State private var showingDeleteBudgetConfirmation = false
    
    var body: some View {
        NavigationStack {
            Group {
                switch selectedTab {
                case .overview:
                    FinanceOverviewView(
                        selectedTab: $selectedTab,
                        onRequestBudgetsTab: {
                            withAnimation {
                                selectedTab = .budgets
                            }
                        }
                    )
                    .environmentObject(financeService)
                case .orders:
                    OrdersListView(
                        selectedTab: $selectedTab,
                        isEmbeddedInFinanceDashboard: true
                    )
                    .environmentObject(financeService)
                case .budgets:
                    BudgetsListView(
                        selectedTab: $selectedTab,
                        isEmbeddedInFinanceDashboard: true
                    )
                    .environmentObject(financeService)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Colors.background)
            .ftchubRootNavHeader(title: "Finance")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Add Section
                        Button(action: { showingAddOrder = true }) {
                            Label("Add Order", systemImage: "cart.badge.plus")
                        }
                        Button(action: { showingAddBudget = true }) {
                            Label("Add Budget", systemImage: "dollarsign.circle")
                        }
                        
                        // Delete Section
                        if !financeService.orders.isEmpty || !financeService.budgets.isEmpty {
                            Divider()
                            
                            // Delete Orders Submenu
                            if !financeService.orders.isEmpty {
                                Menu {
                                    ForEach(financeService.orders.prefix(10)) { order in
                                        Button(role: .destructive) {
                                            orderToDelete = order
                                            showingDeleteOrderConfirmation = true
                                        } label: {
                                            Label("\(order.vendorName) - $\(order.totalAmount.formatted())", systemImage: "trash")
                                        }
                                    }
                                    
                                    if financeService.orders.count > 10 {
                                        Text("... and \(financeService.orders.count - 10) more")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                } label: {
                                    Label("Delete Order", systemImage: "cart.badge.minus")
                                }
                            }
                            
                            // Delete Budgets Submenu
                            if !financeService.budgets.isEmpty {
                                Menu {
                                    ForEach(financeService.budgets) { budget in
                                        Button(role: .destructive) {
                                            budgetToDelete = budget
                                            showingDeleteBudgetConfirmation = true
                                        } label: {
                                            Label("\(budget.name) - $\(budget.totalAmount.formatted())", systemImage: "trash")
                                        }
                                    }
                                } label: {
                                    Label("Delete Budget", systemImage: "dollarsign.circle.badge.minus")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .onAppear {
                Task {
                    await financeService.loadFinancialData()
                }
            }
            .sheet(isPresented: $showingAddOrder) {
                AddOrderView()
                    .environmentObject(financeService)
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetView()
                    .environmentObject(financeService)
                    .environmentObject(teamService)
            }
            .alert("Delete Order", isPresented: $showingDeleteOrderConfirmation) {
                Button("Cancel", role: .cancel) {
                    orderToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let order = orderToDelete {
                        Task {
                            do {
                                try await financeService.deleteOrder(order)
                            } catch {
                                DebugLog.log("Error deleting order: \(error)")
                            }
                        }
                    }
                    orderToDelete = nil
                }
            } message: {
                if let order = orderToDelete {
                    Text("Are you sure you want to delete the order from \(order.vendorName)? This action cannot be undone.")
                }
            }
            .alert("Delete Budget", isPresented: $showingDeleteBudgetConfirmation) {
                Button("Cancel", role: .cancel) {
                    budgetToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let budget = budgetToDelete {
                        Task {
                            do {
                                try await financeService.deleteBudget(budget)
                            } catch {
                                DebugLog.log("Error deleting budget: \(error)")
                            }
                        }
                    }
                    budgetToDelete = nil
                }
            } message: {
                if let budget = budgetToDelete {
                    Text("Are you sure you want to delete \"\(budget.name)\"? This action cannot be undone.")
                }
            }
            .refreshable {
                await financeService.loadFinancialData()
            }
        }
    }
}

// MARK: - Phase 1: sync status & retry (finance vertical)

struct FinanceSyncErrorBanner: View {
    @EnvironmentObject var financeService: FinanceService
    
    var body: some View {
        if let message = financeService.errorMessage {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.error)
                    .accessibilityHidden(true)
                Text(message)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                Button("Retry") {
                    Task { await financeService.loadFinancialData() }
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(DesignSystem.Colors.primary)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.error.opacity(0.10))
            )
        }
    }
}

enum FinanceTab: CaseIterable, Identifiable {
    case overview, orders, budgets
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .orders: return "Orders"
        case .budgets: return "Budgets"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.pie.fill"
        case .orders: return "cart.fill"
        case .budgets: return "dollarsign.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .overview: return DesignSystem.Colors.primary
        case .orders: return DesignSystem.Colors.accent
        case .budgets: return DesignSystem.Colors.secondary
        }
    }
}

// MARK: - Finance Scroll Header

struct FinanceScrollHeader: View {
    @Binding var selectedTab: FinanceTab
    @EnvironmentObject var financeService: FinanceService
    
    private var summary: FinancialSummary {
        financeService.getFinancialSummary()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            FinanceSegmentedTabBar(selectedTab: $selectedTab)
            
            if selectedTab == .overview {
                HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "banknote.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(
                            summary.isOverBudget ? DesignSystem.Colors.error : DesignSystem.Colors.success
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text("$\(summary.totalRemaining.formatted())")
                            .font(.title2.weight(.bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    
                    Spacer(minLength: DesignSystem.Spacing.md)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.top, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.lg)
    }
}

// MARK: - Finance Segmented Tab Bar

struct FinanceSegmentedTabBar: View {
    @Binding var selectedTab: FinanceTab
    @Namespace private var animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(FinanceTab.allCases) { tab in
                FinanceTabSegment(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    animation: animation
                ) {
                    withAnimation(reduceMotion ? .none : DesignSystem.Motion.spring(response: 0.30, dampingFraction: 0.78)) {
                        selectedTab = tab
                    }
                    DesignSystem.Haptics.selection()
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.tertiaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.borderSubtle.opacity(0.5), lineWidth: 1)
        )
    }
}

private struct FinanceTabSegment: View {
    let tab: FinanceTab
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(tab.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundColor(isSelected ? DesignSystem.Colors.textOnPrimary : DesignSystem.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(DesignSystem.Gradients.primary)
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.28), radius: 8, x: 0, y: 3)
                        .matchedGeometryEffect(id: "financeSelectedTab", in: animation)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// Backward-compatible alias for older references.
struct CustomTabBar: View {
    @Binding var selectedTab: FinanceTab
    
    var body: some View {
        FinanceSegmentedTabBar(selectedTab: $selectedTab)
    }
}

// MARK: - Finance Overview
struct FinanceOverviewView: View {
    @EnvironmentObject var financeService: FinanceService
    @Binding var selectedTab: FinanceTab
    var onRequestBudgetsTab: () -> Void = {}
    @State private var showingAlertCenter = false
    @State private var spendingBudgetDisplayMode = SpendingBudgetDisplayMode.pace
    @State private var spendingTrendRange = SpendingTrendRange.month
    
    init(
        selectedTab: Binding<FinanceTab> = .constant(.overview),
        onRequestBudgetsTab: @escaping () -> Void = {}
    ) {
        _selectedTab = selectedTab
        self.onRequestBudgetsTab = onRequestBudgetsTab
    }
    
    var summary: FinancialSummary {
        financeService.getFinancialSummary()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.sm) {
                FinanceScrollHeader(selectedTab: $selectedTab)
                    .environmentObject(financeService)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                FinanceSyncErrorBanner()
                    .environmentObject(financeService)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Alert Summary with enhanced design
                if !financeService.activeAlerts.isEmpty {
                    AlertSummaryView(
                        alerts: financeService.activeAlerts,
                        onDismiss: { alert in
                            financeService.dismissAlert(alert)
                        },
                        onDismissAll: {
                            financeService.activeAlerts.forEach {
                                financeService.dismissAlert($0)
                            }
                        },
                        onViewAll: {
                            showingAlertCenter = true
                        }
                    )
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                
                // Redesigned Financial Summary - List Style (No Boxes)
                VStack(spacing: 0) {
                    FinanceSummaryRow(
                        title: "Total Budget",
                        value: "$\(summary.totalBudget.formatted())",
                        icon: "dollarsign.circle.fill",
                        color: DesignSystem.Colors.primary
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    FinanceSummaryRow(
                        title: "Total Spent",
                        value: "$\(summary.totalSpent.formatted())",
                        icon: "cart.fill",
                        color: summary.isOverBudget ? DesignSystem.Colors.error : DesignSystem.Colors.success
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    FinanceSummaryRow(
                        title: "Remaining",
                        value: "$\(summary.totalRemaining.formatted())",
                        icon: "banknote.fill",
                        color: DesignSystem.Colors.accent
                    )
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    FinanceSummaryRow(
                        title: "Pending",
                        value: "$\(summary.pendingAmount.formatted())",
                        icon: "clock.fill",
                        color: DesignSystem.Colors.warning
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                Text("How to read this: Total budget adds every budget’s cap. Total spent is all non-cancelled orders, including orders not tied to a budget category.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.xs)
                
                if !financeService.budgets.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Text("Budgets at a glance")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                            Button("View all budgets") {
                                onRequestBudgetsTab()
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(Array(financeService.budgets.prefix(3))) { budget in
                                FinanceBudgetGlanceRow(budget: budget, financeService: financeService)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
                
                // Enhanced Recent Orders Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    HStack {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "list.bullet.rectangle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            Text("Recent Orders")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        Spacer()
                        NavigationLink {
                            OrdersListView()
                                .environmentObject(financeService)
                        } label: {
                            HStack(spacing: 4) {
                                Text("View All")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                    
                    if financeService.orders.isEmpty {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.tertiaryBackground)
                                    .frame(width: 64, height: 64)
                                Image(systemName: "cart.badge.questionmark")
                                    .font(.title)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            Text("No orders yet")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text("Create your first order to get started")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(DesignSystem.Spacing.xl)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(financeService.getRecentOrders().enumerated()), id: \.element.id) { index, order in
                                OrderRowView(order: order)
                                if index < financeService.getRecentOrders().count - 1 {
                                    Divider()
                                        .padding(.leading, 60)
                                        .background(DesignSystem.Colors.border.opacity(0.3))
                                }
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
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Enhanced Charts Section
                VStack(spacing: DesignSystem.Spacing.lg) {
                    SpendingBudgetCardView(
                        snapshot: financeService.getSpendingTrendSnapshot(range: spendingTrendRange),
                        displayMode: $spendingBudgetDisplayMode,
                        selectedRange: $spendingTrendRange,
                        onRequestBudgets: onRequestBudgetsTab
                    )
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Vendor Spending
                    VendorSpendingChartView(
                        vendors: financeService.getVendorSpending()
                    )
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                .padding(.top, DesignSystem.Spacing.md)
                
                }
                .padding(.top, DesignSystem.Spacing.lg)
            }
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .sheet(isPresented: $showingAlertCenter) {
            AlertCenterView()
                .environmentObject(financeService)
        }
    }
}

// MARK: - Budget glance (overview)

private struct FinanceBudgetGlanceRow: View {
    let budget: Budget
    let financeService: FinanceService
    
    private var spent: Decimal {
        financeService.calculateBudgetSpending(budgetId: budget.id)
    }
    
    private var fraction: CGFloat {
        guard budget.totalAmount > 0 else { return 0 }
        let raw = Double(truncating: (spent / budget.totalAmount) as NSDecimalNumber)
        return CGFloat(min(max(raw, 0), 1))
    }
    
    private var overCap: Bool {
        spent > budget.totalAmount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(budget.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("$\(spent.formatted()) of $\(budget.totalAmount.formatted())")
                    .font(.caption.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(overCap ? DesignSystem.Colors.error : DesignSystem.Colors.primary)
                        .frame(width: geo.size.width * (overCap ? 1 : fraction), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.border.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

// MARK: - Finance Summary Row (List Style)
struct FinanceSummaryRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

// MARK: - Enhanced Finance Summary Card (deprecated, keeping for compatibility)
struct FinanceSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Icon badge at top
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            Spacer()
            
            // Value and title at bottom
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(height: 140)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.08), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - Enhanced Quick Stat View
struct QuickStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Enhanced Order Row View
struct OrderRowView: View {
    let order: Order
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.fromString(order.status.color).opacity(0.2),
                                Color.fromString(order.status.color).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.fromString(order.status.color).opacity(0.2), radius: 3, x: 0, y: 2)
                Image(systemName: order.status.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color.fromString(order.status.color))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(order.vendorName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(order.orderDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("$\(order.totalAmount.formatted())")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(order.status.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.fromString(order.status.color).opacity(0.15))
                    )
                    .foregroundColor(Color.fromString(order.status.color))
            }
        }
        .padding(.vertical, DesignSystem.Spacing.md)
    }
}

#Preview {
    FinancialDashboardView()
        .environmentObject(FinanceService.shared)
        .environmentObject(TeamService())
        .withToast()
}

