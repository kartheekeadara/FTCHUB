//
//  OrderItem.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation

struct OrderItem: Identifiable, Codable, Hashable {
    let id: UUID
    let orderId: UUID
    var itemId: UUID? // Link to inventory item (optional)
    var description: String
    var quantity: Int
    var unitPrice: Decimal
    var totalPrice: Decimal
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case itemId = "item_id"
        case description
        case quantity
        case unitPrice = "unit_price"
        case totalPrice = "total_price"
        case createdAt = "created_at"
    }
    
    init(
        id: UUID = UUID(),
        orderId: UUID,
        itemId: UUID? = nil,
        description: String,
        quantity: Int,
        unitPrice: Decimal,
        totalPrice: Decimal? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.orderId = orderId
        self.itemId = itemId
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice ?? (Decimal(quantity) * unitPrice)
        self.createdAt = createdAt
    }
    
    // Computed property to recalculate total if needed
    var computedTotal: Decimal {
        Decimal(quantity) * unitPrice
    }
    
    // Formatted display values
    var displayUnitPrice: String {
        String(format: "$%.2f", unitPrice as NSDecimalNumber)
    }
    
    var displayTotalPrice: String {
        String(format: "$%.2f", totalPrice as NSDecimalNumber)
    }
    
    // Validate that total matches computed value
    var isValid: Bool {
        abs(totalPrice - computedTotal) < Decimal(0.01)
    }
}

// MARK: - Sample Data

extension OrderItem {
    static let sample = OrderItem(
        orderId: UUID(),
        description: "REV Robotics Motor",
        quantity: 4,
        unitPrice: 29.99,
        createdAt: Date()
    )
    
    static let sampleItems = [
        OrderItem(
            orderId: UUID(),
            description: "REV Robotics Motor",
            quantity: 4,
            unitPrice: 29.99
        ),
        OrderItem(
            orderId: UUID(),
            description: "REV Robotics Sensor",
            quantity: 2,
            unitPrice: 45.00
        ),
        OrderItem(
            orderId: UUID(),
            description: "Aluminum Extrusion 15mm",
            quantity: 6,
            unitPrice: 8.50
        )
    ]
}

