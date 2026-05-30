//
//  BudgetTemplate.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation

struct BudgetTemplate: Identifiable, Codable {
    let id: UUID
    let teamId: UUID
    var name: String
    var description: String?
    var categories: [BudgetCategoryTemplate]
    var createdBy: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, categories
        case teamId = "team_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Convert template to a budget
    func toBudget(startDate: Date, endDate: Date, teamId: UUID) -> Budget {
        let budgetCategories = categories.map { template in
            BudgetCategory(
                id: UUID(),
                name: template.name,
                allocated: template.allocatedAmount,
                spent: 0
            )
        }
        
        let totalAmount = categories.reduce(Decimal(0)) { $0 + $1.allocatedAmount }
        
        return Budget(
            id: UUID(),
            teamId: teamId,
            name: name,
            description: description,
            totalAmount: totalAmount,
            startDate: startDate,
            endDate: endDate,
            categories: budgetCategories,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

struct BudgetCategoryTemplate: Codable, Identifiable {
    var id = UUID()
    var name: String
    var allocatedAmount: Decimal
    var suggestedPercent: Double? // Optional percentage of total budget
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case allocatedAmount = "allocated_amount"
        case suggestedPercent = "suggested_percent"
    }
}

extension BudgetTemplate {
    static let sampleTemplates = [
        BudgetTemplate(
            id: UUID(),
            teamId: UUID(),
            name: "Season Budget Template",
            description: "Standard template for FTC season budget",
            categories: [
                BudgetCategoryTemplate(name: "Parts & Materials", allocatedAmount: 4000, suggestedPercent: 40),
                BudgetCategoryTemplate(name: "Competition Fees", allocatedAmount: 2000, suggestedPercent: 20),
                BudgetCategoryTemplate(name: "Travel", allocatedAmount: 2000, suggestedPercent: 20),
                BudgetCategoryTemplate(name: "Tools & Equipment", allocatedAmount: 1500, suggestedPercent: 15),
                BudgetCategoryTemplate(name: "Outreach", allocatedAmount: 500, suggestedPercent: 5)
            ],
            createdBy: nil,
            createdAt: Date().addingTimeInterval(-86400 * 60),
            updatedAt: Date()
        ),
        BudgetTemplate(
            id: UUID(),
            teamId: UUID(),
            name: "Competition Budget Template",
            description: "Template for competition-specific expenses",
            categories: [
                BudgetCategoryTemplate(name: "Registration Fees", allocatedAmount: 500, suggestedPercent: 25),
                BudgetCategoryTemplate(name: "Travel & Lodging", allocatedAmount: 800, suggestedPercent: 40),
                BudgetCategoryTemplate(name: "Food & Supplies", allocatedAmount: 300, suggestedPercent: 15),
                BudgetCategoryTemplate(name: "Emergency Fund", allocatedAmount: 400, suggestedPercent: 20)
            ],
            createdBy: nil,
            createdAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date()
        )
    ]
}

