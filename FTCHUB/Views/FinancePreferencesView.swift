//
//  FinancePreferencesView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct FinancePreferencesView: View {
    @EnvironmentObject var financeService: FinanceService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Alerts") {
                    Toggle("Enable Budget Alerts", isOn: $financeService.enableBudgetAlerts)
                    
                    if financeService.enableBudgetAlerts {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Alert Threshold: \(financeService.budgetAlertThreshold)%")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Slider(
                                value: Binding(
                                    get: { Double(financeService.budgetAlertThreshold) },
                                    set: { financeService.budgetAlertThreshold = max(5, Int($0)) }
                                ),
                                in: 5...50,
                                step: 5
                            )
                            
                            HStack {
                                Text("5%")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Spacer()
                                Text("Alert when budget usage reaches this percentage")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .multilineTextAlignment(.trailing)
                                Spacer()
                                Text("50%")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                }
                
                Section("Spending Alerts") {
                    Toggle("Enable Spending Alerts", isOn: $financeService.enableSpendingAlerts)
                    
                    if financeService.enableSpendingAlerts {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Spending Limit: $\(financeService.spendingAlertLimit, specifier: "%.0f")")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Slider(
                                value: $financeService.spendingAlertLimit,
                                in: 50...1000,
                                step: 50
                            )
                            
                            HStack {
                                Text("$50")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Spacer()
                                Text("Alert for orders exceeding this amount")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .multilineTextAlignment(.trailing)
                                Spacer()
                                Text("$1000")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                }
                
                Section("Order Settings") {
                    Toggle("Auto-Categorize Orders", isOn: $financeService.autoCategorizeOrders)
                    
                    Text("Automatically suggest budget categories based on vendor and order history")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Section {
                    Button("Reset to Defaults") {
                        financeService.enableBudgetAlerts = true
                        financeService.budgetAlertThreshold = 15
                        financeService.enableSpendingAlerts = false
                        financeService.spendingAlertLimit = 250
                        financeService.autoCategorizeOrders = true
                        financeService.savePreferences()
                    }
                    .foregroundColor(DesignSystem.Colors.error)
                }
            }
            .navigationTitle("Finance Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        financeService.savePreferences()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FinancePreferencesView()
        .environmentObject(FinanceService.shared)
}

