//
//  AlertSummaryView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct AlertSummaryView: View {
    let alerts: [BudgetAlert]
    let onDismiss: (BudgetAlert) -> Void
    let onDismissAll: () -> Void
    let onViewAll: () -> Void
    
    var criticalAlerts: [BudgetAlert] {
        alerts.filter { $0.severity == .critical }
    }
    
    var warningAlerts: [BudgetAlert] {
        alerts.filter { $0.severity == .warning }
    }
    
    var body: some View {
        if !alerts.isEmpty {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text("Alerts (\(alerts.count))")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if !criticalAlerts.isEmpty {
                            Text("\(criticalAlerts.count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.Colors.error)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                    
                    if alerts.count > 3 {
                        Button("View All") {
                            onViewAll()
                        }
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    Button(action: onDismissAll) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                // Show top 3 alerts (prioritize critical)
                ForEach(alerts.prefix(3)) { alert in
                    AlertRow(alert: alert) {
                        onDismiss(alert)
                    }
                    
                    if alert.id != alerts.prefix(3).last?.id {
                        Divider()
                            .background(DesignSystem.Colors.border)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(criticalAlerts.isEmpty ? DesignSystem.Colors.border : DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct AlertRow: View {
    let alert: BudgetAlert
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            // Alert Icon
            Image(systemName: alert.icon)
                .foregroundColor(alert.color)
                .font(.title3)
                .frame(width: 24)
            
            // Alert Message
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(alert.severity.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(alert.color.opacity(0.2))
                    .foregroundColor(alert.color)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Dismiss Button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

struct AlertCenterView: View {
    @EnvironmentObject var financeService: FinanceService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if financeService.activeAlerts.isEmpty {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 48))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Text("No Alerts")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text("All budgets are within limits")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(DesignSystem.Spacing.xl)
                    } else {
                        ForEach(financeService.activeAlerts) { alert in
                            AlertRow(alert: alert) {
                                financeService.dismissAlert(alert)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Active Alerts (\(financeService.activeAlerts.count))")
                        Spacer()
                        if !financeService.activeAlerts.isEmpty {
                            Button("Dismiss All") {
                                financeService.activeAlerts.forEach {
                                    financeService.dismissAlert($0)
                                }
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AlertSummaryView(
        alerts: [
            BudgetAlert(
                id: UUID(),
                budgetId: UUID(),
                categoryId: nil,
                type: .overBudget,
                severity: .critical,
                message: "Season Budget is over budget by 15.5%",
                isDismissed: false,
                createdAt: Date()
            )
        ],
        onDismiss: { _ in },
        onDismissAll: {},
        onViewAll: {}
    )
}

