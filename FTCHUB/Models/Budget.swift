//
//  Budget.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation

struct Budget: Identifiable, Codable {
    let id: UUID
    let teamId: UUID
    let name: String
    let description: String?
    let totalAmount: Decimal
    let startDate: Date
    let endDate: Date
    let categories: [BudgetCategory]
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, categories
        case teamId = "team_id"
        case totalAmount = "total_amount"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var spentAmount: Decimal {
        categories.reduce(0) { $0 + $1.spent }
    }
    
    var remainingAmount: Decimal {
        totalAmount - spentAmount
    }
    
    var percentageUsed: Double {
        guard totalAmount > 0 else { return 0 }
        return Double(truncating: (spentAmount / totalAmount) as NSNumber) * 100
    }
    
    var isOverBudget: Bool {
        spentAmount > totalAmount
    }
    
    static let sample = Budget(
        id: UUID(),
        teamId: UUID(),
        name: "2025-2026 Season Budget",
        description: "Main budget for DECODE season",
        totalAmount: 10000,
        startDate: Date().addingTimeInterval(-86400 * 30),
        endDate: Date().addingTimeInterval(86400 * 150),
        categories: [
            BudgetCategory(name: "Parts & Materials", allocated: 4000, spent: 2500),
            BudgetCategory(name: "Competition Fees", allocated: 2000, spent: 1500),
            BudgetCategory(name: "Travel", allocated: 2000, spent: 500),
            BudgetCategory(name: "Tools & Equipment", allocated: 1500, spent: 800),
            BudgetCategory(name: "Outreach", allocated: 500, spent: 200)
        ],
        createdBy: nil,
        createdAt: Date().addingTimeInterval(-86400 * 30),
        updatedAt: Date()
    )
}

struct BudgetCategory: Codable, Identifiable {
    var id = UUID()
    let name: String
    let allocated: Decimal
    var spent: Decimal
    
    var remaining: Decimal {
        allocated - spent
    }
    
    var percentageUsed: Double {
        guard allocated > 0 else { return 0 }
        return Double(truncating: (spent / allocated) as NSNumber) * 100
    }
    
    var isOverBudget: Bool {
        spent > allocated
    }
}

struct BudgetSummary {
    let totalBudget: Decimal
    let totalSpent: Decimal
    let totalRemaining: Decimal
    let percentageUsed: Double
    let categoryCount: Int
    let overBudgetCategories: Int
}

