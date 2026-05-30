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
    private weak var authService: AuthService?
    
    init() {
        // Don't auto-load in init - wait for team context
    }
    
    func bindAuthService(_ service: AuthService) {
        authService = service
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
            // Security: Get team ID from authenticated user
            guard let userId = supabase.auth.currentUser?.id else {
                errorMessage = "Authentication required."
                self.orders = []
                return
            }
            
            // Get user's profile to verify team membership
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            guard let teamId = profile.teamId else {
                errorMessage = "Join or create a team to view orders."
                self.orders = []
                return
            }
            
            // Security: Verify user is authenticated and belongs to team
            guard SecurityUtils.verifyTeamMembership(userTeamId: profile.teamId, requestedTeamId: teamId) else {
                errorMessage = "Unauthorized access."
                self.orders = []
                return
            }
            
            let orderList: [Order] = try await supabase
                .from("orders")
                .select()
                .eq("team_id", value: teamId)
                .order("order_date", ascending: false)
                .execute()
                .value
            
            self.orders = orderList
        } catch {
            errorMessage = "Unable to load orders. Please try again."
            // Security: Don't log sensitive error details
            TelemetryService.shared.logError(error, context: ["action": "load_orders"])
            self.orders = []
        }
    }
    
    // MARK: - Order CRUD Operations
    func createOrder(order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Security: Verify user belongs to the team
        guard let userId = supabase.auth.currentUser?.id else {
            throw OrderError.notAuthenticated
        }
        
        let profile: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        guard let userTeamId = profile.teamId else {
            throw OrderError.noTeam
        }
        
        guard SecurityUtils.verifyTeamMembership(userTeamId: userTeamId, requestedTeamId: order.teamId) else {
            throw OrderError.unauthorized
        }
        
        do {
            // Security: Ensure order belongs to user's team
            var secureOrder = order
            secureOrder.teamId = userTeamId
            
            try await supabase
                .from("orders")
                .insert(secureOrder)
                .execute()
            await loadOrders()
        } catch {
            errorMessage = "Failed to create order. Please try again."
            TelemetryService.shared.logError(error, context: ["action": "create_order"])
            throw error
        }
    }
    
    func updateOrder(order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Security: Verify user belongs to the team and order belongs to their team
        guard let userId = supabase.auth.currentUser?.id else {
            throw OrderError.notAuthenticated
        }
        
        let profile: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        guard let userTeamId = profile.teamId else {
            throw OrderError.noTeam
        }
        
        guard SecurityUtils.verifyTeamMembership(userTeamId: userTeamId, requestedTeamId: order.teamId) else {
            throw OrderError.unauthorized
        }
        
        do {
            // Security: Ensure order belongs to user's team
            var secureOrder = order
            secureOrder.teamId = userTeamId
            
            try await supabase
                .from("orders")
                .update(secureOrder)
                .eq("id", value: order.id)
                .eq("team_id", value: userTeamId) // Additional security: verify team_id matches
                .execute()
            await loadOrders()
        } catch {
            errorMessage = "Failed to update order. Please try again."
            TelemetryService.shared.logError(error, context: ["action": "update_order"])
            throw error
        }
    }
    
    func deleteOrder(order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Security: Verify user belongs to the team and order belongs to their team
        guard let userId = supabase.auth.currentUser?.id else {
            throw OrderError.notAuthenticated
        }
        
        let profile: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        guard let userTeamId = profile.teamId else {
            throw OrderError.noTeam
        }
        
        guard SecurityUtils.verifyTeamMembership(userTeamId: userTeamId, requestedTeamId: order.teamId) else {
            throw OrderError.unauthorized
        }
        
        do {
            // Security: Additional check - verify team_id matches before deletion
            try await supabase
                .from("orders")
                .delete()
                .eq("id", value: order.id)
                .eq("team_id", value: userTeamId) // Security: ensure user can only delete their team's orders
                .execute()
            await loadOrders()
        } catch {
            errorMessage = "Failed to delete order. Please try again."
            TelemetryService.shared.logError(error, context: ["action": "delete_order"])
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

// MARK: - Order Errors
enum OrderError: LocalizedError {
    case notAuthenticated
    case noTeam
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .noTeam:
            return "You must join or create a team first."
        case .unauthorized:
            return "You don't have permission to perform this action."
        }
    }
}
