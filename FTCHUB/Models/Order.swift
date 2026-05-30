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
    var receiptUrl: String? // Legacy single receipt URL (for backward compatibility)
    var receiptUrls: [String]? // Array of receipt URLs (new)
    var budgetId: UUID? // Link to specific budget
    var budgetCategoryId: UUID? // Link to budget category (references category ID within budget JSONB)
    var expectedDeliveryDate: Date? // Expected delivery date
    var actualDeliveryDate: Date? // Actual delivery date
    var orderItems: [OrderItem]? // Line items for this order
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
        case receiptUrls = "receipt_urls"
        case budgetId = "budget_id"
        case budgetCategoryId = "budget_category_id"
        case expectedDeliveryDate = "expected_delivery_date"
        case actualDeliveryDate = "actual_delivery_date"
        case orderItems = "order_items" // Note: This is loaded separately, not stored in orders table
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
    
    // Get all receipt URLs (combines legacy and new format)
    var allReceiptUrls: [String] {
        var urls: [String] = []
        if let legacyUrl = receiptUrl, !legacyUrl.isEmpty {
            urls.append(legacyUrl)
        }
        if let newUrls = receiptUrls {
            urls.append(contentsOf: newUrls)
        }
        return urls
    }
    
    // Check if order has any receipts
    var hasReceipts: Bool {
        return !allReceiptUrls.isEmpty
    }
    
    // Check if order is overdue (has expected delivery date but not received)
    var isOverdue: Bool {
        guard let expectedDate = expectedDeliveryDate,
              actualDeliveryDate == nil,
              status != .received,
              status != .cancelled else {
            return false
        }
        return Date() > expectedDate
    }
    
    // Calculate total from line items if available
    var calculatedTotalFromItems: Decimal? {
        guard let items = orderItems, !items.isEmpty else { return nil }
        return items.reduce(Decimal(0)) { $0 + $1.totalPrice }
    }
    
    // Check if order total matches line items total
    var totalMatchesItems: Bool {
        guard let calculatedTotal = calculatedTotalFromItems else { return true } // No items means it's fine
        return abs(totalAmount - calculatedTotal) < Decimal(0.01)
    }
    
    // Get line items count
    var itemCount: Int {
        orderItems?.count ?? 0
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

