//
//  InventoryItem.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

struct InventoryItem: Identifiable, Codable, Hashable {
    let id: UUID
    var teamId: UUID
    var sku: String
    var name: String
    var manufacturer: String?
    var partNumber: String?
    var category: String?
    var location: String?
    var quantityOnHand: Int
    var lowStockThreshold: Int
    var unitCost: Decimal?
    var description: String?
    var imageUrl: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case sku
        case name
        case manufacturer
        case partNumber = "part_number"
        case category
        case location
        case quantityOnHand = "quantity_on_hand"
        case lowStockThreshold = "low_stock_threshold"
        case unitCost = "unit_cost"
        case description
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties for UI
    var isLowStock: Bool {
        return quantityOnHand <= lowStockThreshold
    }
    
    var stockStatus: StockStatus {
        if quantityOnHand == 0 {
            return .outOfStock
        } else if isLowStock {
            return .lowStock
        } else {
            return .inStock
        }
    }
    
    var displayPrice: String {
        guard let cost = unitCost else { return "N/A" }
        return String(format: "$%.2f", cost as NSDecimalNumber)
    }
    
    var categoryIcon: String {
        switch category?.lowercased() {
        case "electronics": return "cpu"
        case "mechanical": return "gear"
        case "tools": return "wrench.and.screwdriver"
        case "sensors": return "sensor.tag.radiowaves.forward"
        case "motors": return "bolt"
        case "wheels": return "circle.dotted"
        default: return "cube.box"
        }
    }
}

enum StockStatus: String, CaseIterable {
    case inStock = "In Stock"
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
    
    var color: String {
        switch self {
        case .inStock: return "green"
        case .lowStock: return "orange"
        case .outOfStock: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .inStock: return "checkmark.circle.fill"
        case .lowStock: return "exclamationmark.triangle.fill"
        case .outOfStock: return "xmark.circle.fill"
        }
    }
}

// MARK: - Sample Data for Testing
extension InventoryItem {
    static let sample = InventoryItem(
        id: UUID(),
        teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
        sku: "FTC-001",
        name: "Rev Robotics Expansion Hub",
        manufacturer: "REV Robotics",
        partNumber: "REV-31-1153",
        category: "Electronics",
        location: "Robot Cart",
        quantityOnHand: 2,
        lowStockThreshold: 1,
        unitCost: 175.00,
        description: "The REV Robotics Expansion Hub is the control system for FTC robots.",
        imageUrl: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let sampleItems = [
        InventoryItem(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            sku: "FTC-001",
            name: "Rev Robotics Expansion Hub",
            manufacturer: "REV Robotics",
            partNumber: "REV-31-1153",
            category: "Electronics",
            location: "Robot Cart",
            quantityOnHand: 2,
            lowStockThreshold: 1,
            unitCost: 175.00,
            description: "The REV Robotics Expansion Hub is the control system for FTC robots.",
            imageUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        InventoryItem(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            sku: "FTC-002",
            name: "Rev Robotics Core Hex Motor",
            manufacturer: "REV Robotics",
            partNumber: "REV-41-1301",
            category: "Motors",
            location: "Parts Bin A",
            quantityOnHand: 8,
            lowStockThreshold: 2,
            unitCost: 25.00,
            description: "High-performance brushless motor for FTC robots.",
            imageUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        InventoryItem(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            sku: "FTC-003",
            name: "Rev Robotics Color Sensor",
            manufacturer: "REV Robotics",
            partNumber: "REV-31-1557",
            category: "Sensors",
            location: "Sensor Box",
            quantityOnHand: 0,
            lowStockThreshold: 1,
            unitCost: 45.00,
            description: "Color and distance sensor for autonomous navigation.",
            imageUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        InventoryItem(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            sku: "FTC-004",
            name: "Rev Robotics 4-inch Omni Wheel",
            manufacturer: "REV Robotics",
            partNumber: "REV-41-1304",
            category: "Wheels",
            location: "Wheel Storage",
            quantityOnHand: 4,
            lowStockThreshold: 2,
            unitCost: 15.00,
            description: "Omnidirectional wheel for holonomic drive systems.",
            imageUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
