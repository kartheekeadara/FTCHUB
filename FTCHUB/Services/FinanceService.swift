//
//  FinanceService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class FinanceService: ObservableObject {
    static let shared = FinanceService()
    
    @Published var budgets: [Budget] = []
    @Published var orders: [Order] = []
    @Published var vendors: [Vendor] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    private let localStorage = LocalStorage.shared
    
    private init() {
        // Load sample data for preview/demo mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            loadSampleData()
        }
    }
    
    // MARK: - Data Loading
    
    func loadFinancialData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let teamId = UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else {
                loadSampleData()
                return
            }
            
            // Load orders
            let loadedOrders: [Order] = try await supabase
                .from("orders")
                .select()
                .eq("team_id", value: teamId)
                .order("order_date", ascending: false)
                .execute()
                .value
            
            self.orders = loadedOrders
            
            // Load vendors
            let loadedVendors: [Vendor] = try await supabase
                .from("vendors")
                .select()
                .eq("team_id", value: teamId)
                .order("name", ascending: true)
                .execute()
                .value
            
            self.vendors = loadedVendors
            
            // Load budgets
            let loadedBudgets: [Budget] = try await supabase
                .from("budgets")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.budgets = loadedBudgets
            
        } catch {
            print("Supabase connection failed, using sample data: \(error)")
            loadSampleData()
            errorMessage = nil
        }
    }
    
    private func loadSampleData() {
        self.budgets = [Budget.sample]
        self.orders = Order.sampleOrders
        self.vendors = Vendor.sampleVendors
    }
    
    // MARK: - Budget Operations
    
    func createBudget(_ budget: Budget) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("budgets")
                .insert(budget)
                .execute()
            await loadFinancialData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateBudget(_ budget: Budget) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("budgets")
                .update(budget)
                .eq("id", value: budget.id)
                .execute()
            await loadFinancialData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteBudget(_ budget: Budget) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("budgets")
                .delete()
                .eq("id", value: budget.id)
                .execute()
            await loadFinancialData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Order Operations
    
    func createOrder(_ order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("orders")
                .insert(order)
                .execute()
            await loadFinancialData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateOrder(_ order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("orders")
                .update(order)
                .eq("id", value: order.id)
                .execute()
            await loadFinancialData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteOrder(_ order: Order) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("orders")
                .delete()
                .eq("id", value: order.id)
                .execute()
            await loadFinancialData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Vendor Operations
    
    func createVendor(_ vendor: Vendor) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("vendors")
                .insert(vendor)
                .execute()
            await loadFinancialData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateVendor(_ vendor: Vendor) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("vendors")
                .update(vendor)
                .eq("id", value: vendor.id)
                .execute()
            await loadFinancialData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteVendor(_ vendor: Vendor) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("vendors")
                .delete()
                .eq("id", value: vendor.id)
                .execute()
            await loadFinancialData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Analytics & Reporting
    
    func getFinancialSummary() -> FinancialSummary {
        let totalBudget = budgets.reduce(0) { $0 + $1.totalAmount }
        let totalSpent = orders.filter { $0.status != .cancelled }.reduce(0) { $0 + $1.totalAmount }
        let pendingOrders = orders.filter { $0.status == .pending || $0.status == .ordered }
        let pendingAmount = pendingOrders.reduce(0) { $0 + $1.totalAmount }
        
        return FinancialSummary(
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            totalRemaining: totalBudget - totalSpent,
            pendingAmount: pendingAmount,
            orderCount: orders.count,
            vendorCount: vendors.count,
            budgetCount: budgets.count
        )
    }
    
    func getOrdersByStatus(_ status: OrderStatus) -> [Order] {
        orders.filter { $0.status == status }
    }
    
    func getOrdersByVendor(_ vendorName: String) -> [Order] {
        orders.filter { $0.vendor == vendorName }
    }
    
    func getRecentOrders(limit: Int = 5) -> [Order] {
        Array(orders.prefix(limit))
    }
}

// MARK: - Supporting Types

struct FinancialSummary {
    let totalBudget: Decimal
    let totalSpent: Decimal
    let totalRemaining: Decimal
    let pendingAmount: Decimal
    let orderCount: Int
    let vendorCount: Int
    let budgetCount: Int
    
    var percentageUsed: Double {
        guard totalBudget > 0 else { return 0 }
        return Double(truncating: (totalSpent / totalBudget) as NSNumber) * 100
    }
    
    var isOverBudget: Bool {
        totalSpent > totalBudget
    }
}

