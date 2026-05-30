//
//  Budget.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation

struct Budget: Identifiable, Codable, Hashable {
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
    
}

struct BudgetCategory: Codable, Identifiable, Hashable {
    var id: UUID
    let name: String
    let allocated: Decimal
    var spent: Decimal
    
    init(id: UUID = UUID(), name: String, allocated: Decimal, spent: Decimal = 0) {
        self.id = id
        self.name = name
        self.allocated = allocated
        self.spent = spent
    }
    
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

