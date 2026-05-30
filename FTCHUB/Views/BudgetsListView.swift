//
//  BudgetsListView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct BudgetsListView: View {
    @EnvironmentObject var financeService: FinanceService
    @EnvironmentObject private var toastManager: ToastManager
    @Binding var selectedTab: FinanceTab
    var isEmbeddedInFinanceDashboard: Bool = false
    
    @State private var selectedBudget: Budget? = nil
    @State private var showingTemplates = false
    @State private var budgetToDelete: Budget? = nil
    @State private var showingDeleteConfirmation = false
    
    init(
        selectedTab: Binding<FinanceTab> = .constant(.budgets),
        isEmbeddedInFinanceDashboard: Bool = false
    ) {
        _selectedTab = selectedTab
        self.isEmbeddedInFinanceDashboard = isEmbeddedInFinanceDashboard
    }
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                landscapeContent
            } else {
                portraitScrollContent
            }
        }
        .sheet(item: $selectedBudget) { budget in
            BudgetDetailView(budget: budget)
                .environmentObject(financeService)
        }
        .sheet(isPresented: $showingTemplates) {
            BudgetTemplateListView()
                .environmentObject(financeService)
        }
        .alert("Delete Budget", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                budgetToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let budget = budgetToDelete {
                    Task {
                        await deleteBudget(budget)
                    }
                }
                budgetToDelete = nil
            }
        } message: {
            if let budget = budgetToDelete {
                Text("Are you sure you want to delete \"\(budget.name)\"? This action cannot be undone.")
            }
        }
    }
    
    private var portraitScrollContent: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                if isEmbeddedInFinanceDashboard {
                    FinanceScrollHeader(selectedTab: $selectedTab)
                        .environmentObject(financeService)
                }
                
                if financeService.isLoading && financeService.budgets.isEmpty {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonCard()
                            .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                } else if financeService.budgets.isEmpty {
                    emptyBudgetsView
                } else {
                    ForEach(financeService.budgets) { budget in
                        Button {
                            selectedBudget = budget
                        } label: {
                            BudgetListRow(budget: budget, financeService: financeService)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button { selectedBudget = budget } label: {
                                Label("View Details", systemImage: "eye")
                            }
                            Button(role: .destructive) {
                                budgetToDelete = budget
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background)
    }
    
    private var landscapeContent: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                if isEmbeddedInFinanceDashboard {
                    FinanceScrollHeader(selectedTab: $selectedTab)
                        .environmentObject(financeService)
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                    GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                ], spacing: DesignSystem.Spacing.md) {
                    if financeService.isLoading && financeService.budgets.isEmpty {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonCard()
                        }
                    }
                    ForEach(financeService.budgets) { budget in
                        Button {
                            selectedBudget = budget
                        } label: {
                            BudgetCardView(budget: budget, financeService: financeService)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button { selectedBudget = budget } label: {
                                Label("View Details", systemImage: "eye")
                            }
                            Button(role: .destructive) {
                                budgetToDelete = budget
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background)
    }
    
    private var emptyBudgetsView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text("No budgets found")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text("Create your first budget to track spending")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Button(action: { showingTemplates = true }) {
                Label("Use Template", systemImage: "doc.text")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    private func deleteBudget(_ budget: Budget) async {
        do {
            try await financeService.deleteBudget(budget)
        } catch {
            toastManager.showError("Couldn't delete budget. Try again.")
        }
    }
}

// MARK: - Enhanced Budget Card View (for landscape grid)
struct BudgetCardView: View {
    let budget: Budget
    let financeService: FinanceService
    
    var actualSpending: Decimal {
        financeService.calculateBudgetSpending(budgetId: budget.id)
    }
    
    var variance: Decimal {
        actualSpending - budget.totalAmount
    }
    
    var percentageUsed: Double {
        guard budget.totalAmount > 0 else { return 0 }
        return Double(truncating: (actualSpending / budget.totalAmount) as NSDecimalNumber) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary.opacity(0.2), DesignSystem.Colors.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Text(budget.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text("$\(budget.totalAmount.formatted())")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                HStack {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text("$\(actualSpending.formatted())")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(variance > 0 ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignSystem.Colors.tertiaryBackground)
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: variance > 0 ?
                                        [DesignSystem.Colors.error, DesignSystem.Colors.error.opacity(0.8)] :
                                        [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(min(percentageUsed / 100, 1)), height: 10)
                    }
                }
                .frame(height: 10)
                
                if variance != 0 {
                    HStack {
                        Image(systemName: variance > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                            .foregroundColor(variance > 0 ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                        Text(variance > 0 ? "Over by $\(abs(variance).formatted())" : "Remaining: $\(abs(variance).formatted())")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(variance > 0 ? DesignSystem.Colors.error : DesignSystem.Colors.success)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.12), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Enhanced Budget List Row
struct BudgetListRow: View {
    let budget: Budget
    let financeService: FinanceService

    var actualSpending: Decimal {
        financeService.calculateBudgetSpending(budgetId: budget.id)
    }
    
    var variance: Decimal {
        actualSpending - budget.totalAmount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(budget.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if budget.isOverBudget {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                        
                        if financeService.activeAlerts.contains(where: { $0.budgetId == budget.id }) {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text("\(budget.startDate.formatted(date: .abbreviated, time: .omitted)) - \(budget.endDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(budget.percentageUsed))% Used")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Text("$\(budget.spentAmount.formatted()) of $\(budget.totalAmount.formatted())")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    Spacer()
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(DesignSystem.Colors.tertiaryBackground)
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: budget.isOverBudget ?
                                        [DesignSystem.Colors.error, DesignSystem.Colors.error.opacity(0.8)] :
                                        [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(min(budget.percentageUsed / 100, 1)), height: 10)
                    }
                }
                .frame(height: 10)
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Label("\(budget.categories.count) categories", systemImage: "folder.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                if budget.remainingAmount > 0 {
                    Label("$\(budget.remainingAmount.formatted()) left", systemImage: "banknote.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.success)
                } else {
                    Label("$\(abs(budget.remainingAmount).formatted()) over", systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.borderSubtle.opacity(0.6), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationView {
        BudgetsListView()
            .environmentObject(FinanceService.shared)
    }
    .withToast()
}
