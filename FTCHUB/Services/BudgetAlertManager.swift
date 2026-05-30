//
//  BudgetAlertManager.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class BudgetAlertManager: ObservableObject {
    static let shared = BudgetAlertManager()
    
    @Published var activeAlerts: [BudgetAlert] = []
    @Published var dismissedAlerts: Set<UUID> = []
    
    private init() {}
    
    // MARK: - Alert Calculation
    
    func calculateAlerts(
        budgets: [Budget],
        orders: [Order],
        preferences: AlertPreferences
    ) -> [BudgetAlert] {
        var alerts: [BudgetAlert] = []
        let now = Date()
        
        // Budget threshold alerts
        if preferences.enableBudgetAlerts {
            for budget in budgets {
                // Check if budget is active
                guard budget.startDate <= now && budget.endDate >= now else { continue }
                
                let percentage = budget.percentageUsed
                let threshold = Double(preferences.budgetAlertThreshold)
                
                // Check threshold levels
                if percentage >= 100 {
                    alerts.append(BudgetAlert(
                        id: UUID(),
                        budgetId: budget.id,
                        categoryId: nil,
                        type: .overBudget,
                        severity: .critical,
                        message: "\(budget.name) is over budget by \(String(format: "%.1f", percentage - 100))%",
                        isDismissed: false,
                        createdAt: now
                    ))
                } else if percentage >= threshold {
                    alerts.append(BudgetAlert(
                        id: UUID(),
                        budgetId: budget.id,
                        categoryId: nil,
                        type: .budgetThreshold(percentage: percentage),
                        severity: percentage >= 90 ? .critical : percentage >= 75 ? .warning : .info,
                        message: "\(budget.name) is \(String(format: "%.1f", percentage))% used",
                        isDismissed: false,
                        createdAt: now
                    ))
                }
                
                // Category alerts
                for category in budget.categories {
                    let categoryPercentage = category.percentageUsed
                    
                    if category.isOverBudget {
                        alerts.append(BudgetAlert(
                            id: UUID(),
                            budgetId: budget.id,
                            categoryId: category.id,
                            type: .overBudget,
                            severity: .critical,
                            message: "\(category.name) in \(budget.name) is over budget",
                            isDismissed: false,
                            createdAt: now
                        ))
                    } else if categoryPercentage >= threshold {
                        alerts.append(BudgetAlert(
                            id: UUID(),
                            budgetId: budget.id,
                            categoryId: category.id,
                            type: .budgetThreshold(percentage: categoryPercentage),
                            severity: categoryPercentage >= 90 ? .critical : categoryPercentage >= 75 ? .warning : .info,
                            message: "\(category.name) is \(String(format: "%.1f", categoryPercentage))% used",
                            isDismissed: false,
                            createdAt: now
                        ))
                    }
                }
                
                // Budget expiration alert (7 days before)
                let daysUntilExpiration = Calendar.current.dateComponents([.day], from: now, to: budget.endDate).day ?? 0
                if daysUntilExpiration > 0 && daysUntilExpiration <= 7 {
                    alerts.append(BudgetAlert(
                        id: UUID(),
                        budgetId: budget.id,
                        categoryId: nil,
                        type: .budgetExpiration,
                        severity: daysUntilExpiration <= 3 ? .critical : .warning,
                        message: "\(budget.name) expires in \(daysUntilExpiration) day\(daysUntilExpiration == 1 ? "" : "s")",
                        isDismissed: false,
                        createdAt: now
                    ))
                }
            }
        }
        
        // Spending limit alerts
        if preferences.enableSpendingAlerts {
            let largeOrders = orders.filter { order in
                order.status != .cancelled &&
                Double(truncating: order.totalAmount as NSDecimalNumber) >= preferences.spendingAlertLimit
            }
            
            for order in largeOrders {
                alerts.append(BudgetAlert(
                    id: UUID(),
                    budgetId: order.budgetId,
                    categoryId: order.budgetCategoryId,
                    type: .spendingLimit,
                    severity: .warning,
                    message: "Large order: $\(order.totalAmount.formatted()) from \(order.vendorName)",
                    isDismissed: false,
                    createdAt: order.orderDate
                ))
            }
        }
        
        // Filter out dismissed alerts
        return alerts.filter { !dismissedAlerts.contains($0.id) }
    }
    
    func updateAlerts(budgets: [Budget], orders: [Order], preferences: AlertPreferences) {
        activeAlerts = calculateAlerts(budgets: budgets, orders: orders, preferences: preferences)
        // Sort by severity (critical > warning > info)
        activeAlerts.sort { lhs, rhs in
            if lhs.severity != rhs.severity {
                return lhs.severity.rawValue > rhs.severity.rawValue
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    // MARK: - Alert Management
    
    func dismissAlert(_ alert: BudgetAlert) {
        dismissedAlerts.insert(alert.id)
        activeAlerts.removeAll { $0.id == alert.id }
    }
    
    func dismissAllAlerts() {
        for alert in activeAlerts {
            dismissedAlerts.insert(alert.id)
        }
        activeAlerts.removeAll()
    }
    
    func clearDismissedAlerts() {
        dismissedAlerts.removeAll()
    }
    
    // MARK: - Alert Queries
    
    func getCriticalAlerts() -> [BudgetAlert] {
        activeAlerts.filter { $0.severity == .critical }
    }
    
    func getWarningAlerts() -> [BudgetAlert] {
        activeAlerts.filter { $0.severity == .warning }
    }
    
    func getInfoAlerts() -> [BudgetAlert] {
        activeAlerts.filter { $0.severity == .info }
    }
    
    func getAlertsForBudget(_ budgetId: UUID) -> [BudgetAlert] {
        activeAlerts.filter { $0.budgetId == budgetId }
    }
    
    func hasUnreadAlerts() -> Bool {
        !activeAlerts.isEmpty
    }
    
    func criticalAlertCount() -> Int {
        getCriticalAlerts().count
    }
}

// MARK: - Alert Models

struct BudgetAlert: Identifiable, Hashable {
    let id: UUID
    let budgetId: UUID?
    let categoryId: UUID?
    let type: AlertType
    let severity: AlertSeverity
    let message: String
    var isDismissed: Bool
    let createdAt: Date
    
    var icon: String {
        switch severity {
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch severity {
        case .critical: return DesignSystem.Colors.error
        case .warning: return DesignSystem.Colors.warning
        case .info: return DesignSystem.Colors.primary
        }
    }
}

enum AlertType: Hashable {
    case budgetThreshold(percentage: Double)
    case overBudget
    case spendingLimit
    case budgetExpiration
}

enum AlertSeverity: Int, Hashable, Comparable {
    case info = 0
    case warning = 1
    case critical = 2
    
    static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var displayName: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

struct AlertPreferences: Codable {
    var enableBudgetAlerts: Bool = true
    var budgetAlertThreshold: Int = 15 // Percentage
    var enableSpendingAlerts: Bool = false
    var spendingAlertLimit: Double = 250.0 // Dollar amount
    
    static var `default`: AlertPreferences {
        AlertPreferences()
    }
}

import SwiftUI

