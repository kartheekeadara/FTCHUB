//
//  BudgetsListView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct BudgetsListView: View {
    @EnvironmentObject var financeService: FinanceService
    @State private var selectedBudget: Budget? = nil
    
    var body: some View {
        List {
            if financeService.budgets.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No budgets found")
                            .font(.headline)
                        Text("Create your first budget to track spending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(financeService.budgets) { budget in
                    Button(action: {
                        selectedBudget = budget
                    }) {
                        BudgetListRow(budget: budget)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $selectedBudget) { budget in
            BudgetDetailView(budget: budget)
                .environmentObject(financeService)
        }
    }
}

// MARK: - Budget List Row
struct BudgetListRow: View {
    let budget: Budget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.headline)
                    
                    Text("\(budget.startDate.formatted(date: .abbreviated, time: .omitted)) - \(budget.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if budget.isOverBudget {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }
            
            // Progress
            VStack(spacing: 8) {
                HStack {
                    Text("\(Int(budget.percentageUsed))% Used")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("$\(budget.spentAmount.formatted()) / $\(budget.totalAmount.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: budget.percentageUsed, total: 100)
                    .tint(budget.isOverBudget ? .red : .blue)
            }
            
            // Categories Summary
            HStack(spacing: 16) {
                Label("\(budget.categories.count) categories", systemImage: "folder")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if budget.remainingAmount > 0 {
                    Label("$\(budget.remainingAmount.formatted()) left", systemImage: "banknote")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("$\(abs(budget.remainingAmount).formatted()) over", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        BudgetsListView()
            .environmentObject(FinanceService.shared)
    }
}

