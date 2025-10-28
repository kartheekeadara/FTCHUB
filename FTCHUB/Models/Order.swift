//
//  Order.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

struct Order: Identifiable, Codable, Hashable {
    let id: UUID
    var teamId: UUID
    var orderNumber: String?
    var vendor: String?
    var totalAmount: Decimal
    var orderDate: Date
    var status: OrderStatus
    var notes: String?
    var receiptUrl: String?
    var createdBy: UUID?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case orderNumber = "order_number"
        case vendor
        case totalAmount = "total_amount"
        case orderDate = "order_date"
        case status
        case notes
        case receiptUrl = "receipt_url"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties
    var displayAmount: String {
        return String(format: "$%.2f", totalAmount as NSDecimalNumber)
    }
    
    var vendorName: String {
        return vendor ?? "Unknown Vendor"
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case ordered = "ordered"
    case received = "received"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .ordered: return "Ordered"
        case .received: return "Received"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .ordered: return "blue"
        case .received: return "green"
        case .cancelled: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .ordered: return "shippingbox.fill"
        case .received: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}

// MARK: - Sample Data
extension Order {
    static let sample = Order(
        id: UUID(),
        teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
        orderNumber: "ORD-001",
        vendor: "REV Robotics",
        totalAmount: 450.00,
        orderDate: Date(),
        status: .received,
        notes: "Ordered new sensors and motors",
        receiptUrl: nil,
        createdBy: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let sampleOrders = [
        Order(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            orderNumber: "ORD-001",
            vendor: "REV Robotics",
            totalAmount: 450.00,
            orderDate: Date(),
            status: .received,
            notes: "Ordered new sensors and motors",
            receiptUrl: nil,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Order(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            orderNumber: "ORD-002",
            vendor: "Amazon",
            totalAmount: 125.50,
            orderDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            status: .ordered,
            notes: "Tubing and connectors",
            receiptUrl: nil,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Order(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            orderNumber: "ORD-003",
            vendor: "TETRIX",
            totalAmount: 89.99,
            orderDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            status: .pending,
            notes: "Wheels and bearings",
            receiptUrl: nil,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
