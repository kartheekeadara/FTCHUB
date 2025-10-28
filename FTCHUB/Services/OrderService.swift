//
//  OrderService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class OrderService: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let supabase = SupabaseService.shared.client
    
    init() {
        Task {
            await loadOrders()
        }
    }
    
    // MARK: - Computed Properties
    var totalSpent: Decimal {
        return orders.filter { $0.status != .cancelled }.reduce(0) { $0 + $1.totalAmount }
    }
    
    var totalPending: Decimal {
        return orders.filter { $0.status == .pending || $0.status == .ordered }.reduce(0) { $0 + $1.totalAmount }
    }
    
    var ordersByStatus: [OrderStatus: [Order]] {
        Dictionary(grouping: orders, by: { $0.status })
    }
    
    var recentOrders: [Order] {
        return Array(orders.sorted { $0.orderDate > $1.orderDate }.prefix(10))
    }
    
    // MARK: - Load Orders
    func loadOrders() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // TODO: Replace with actual team_id from AuthService.currentUser.teamId
            guard let teamId = UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else {
                errorMessage = "Team ID not available."
                return
            }
            
            let orderList: [Order] = try await supabase
                .from("orders")
                .select()
                .eq("team_id", value: teamId)
                .order("order_date", ascending: false)
                .execute() as! [Order]
            
            self.orders = orderList
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading orders: \(error)")
            
            // For now, use sample data if Supabase fails
            self.orders = Order.sampleOrders
        }
    }
    
    // MARK: - Order CRUD Operations
    func createOrder(order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("orders")
                .insert(order)
                .execute() as! [Order]
            await loadOrders()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateOrder(order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("orders")
                .update(order)
                .eq("id", value: order.id)
                .execute() as! [Order]
            await loadOrders()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteOrder(order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("orders")
                .delete()
                .eq("id", value: order.id)
                .execute() as! [Order]
            await loadOrders()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Helper Methods
    func ordersByVendor() -> [String: [Order]] {
        return Dictionary(grouping: orders, by: { $0.vendorName })
    }
    
    func ordersInDateRange(from: Date, to: Date) -> [Order] {
        return orders.filter { order in
            order.orderDate >= from && order.orderDate <= to
        }
    }
    
    func totalSpentInRange(from: Date, to: Date) -> Decimal {
        return ordersInDateRange(from: from, to: to)
            .filter { $0.status != .cancelled }
            .reduce(0) { $0 + $1.totalAmount }
    }
}
