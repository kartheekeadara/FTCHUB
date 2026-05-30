//
//  Vendor.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation

struct Vendor: Identifiable, Codable, Hashable {
    let id: UUID
    let teamId: UUID
    let name: String
    let contactPerson: String?
    let email: String?
    let phone: String?
    let website: String?
    let address: String?
    let notes: String?
    var rating: Int? // 1-5 stars
    var averageDeliveryDays: Double? // Average delivery time in days
    var totalOrders: Int
    var totalSpent: Decimal
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, website, address, notes, rating
        case teamId = "team_id"
        case contactPerson = "contact_person"
        case averageDeliveryDays = "average_delivery_days"
        case totalOrders = "total_orders"
        case totalSpent = "total_spent"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties
    var displayRating: String {
        guard let rating = rating else { return "No rating" }
        return String(repeating: "", count: rating) + String(repeating: "", count: 5 - rating)
    }
    
    var hasRating: Bool {
        rating != nil
    }
    
    var averageDeliveryText: String {
        guard let days = averageDeliveryDays else { return "N/A" }
        if days < 1 {
            return "< 1 day"
        } else if days < 2 {
            return "~1 day"
        } else {
            return "~\(Int(days)) days"
        }
    }
    
    var formattedTotalSpent: String {
        String(format: "$%.2f", totalSpent as NSDecimalNumber)
    }
    
    init(
        id: UUID = UUID(),
        teamId: UUID,
        name: String,
        contactPerson: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        website: String? = nil,
        address: String? = nil,
        notes: String? = nil,
        rating: Int? = nil,
        averageDeliveryDays: Double? = nil,
        totalOrders: Int = 0,
        totalSpent: Decimal = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.teamId = teamId
        self.name = name
        self.contactPerson = contactPerson
        self.email = email
        self.phone = phone
        self.website = website
        self.address = address
        self.notes = notes
        self.rating = rating
        self.averageDeliveryDays = averageDeliveryDays
        self.totalOrders = totalOrders
        self.totalSpent = totalSpent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
}

