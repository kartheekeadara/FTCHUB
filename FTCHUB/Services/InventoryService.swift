//
//  InventoryService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class InventoryService: ObservableObject {
    @Published var inventoryItems: [InventoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var searchText = ""
    @Published var selectedCategory: String? = nil
    @Published var sortOption: SortOption = .name
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case sku = "SKU"
        case quantity = "Quantity"
        case category = "Category"
        case dateAdded = "Date Added"
    }
    
    private let supabase = SupabaseService.shared.client
    
    init() {
        // Don't automatically load data in init to prevent preview crashes
        
        // Set up mock data for previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.inventoryItems = InventoryItem.sampleItems
        }
    }
    
    var filteredItems: [InventoryItem] {
        var items = inventoryItems
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.sku.localizedCaseInsensitiveContains(searchText) ||
                item.manufacturer?.localizedCaseInsensitiveContains(searchText) == true ||
                item.partNumber?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        // Sort items
        switch sortOption {
        case .name:
            items.sort { $0.name < $1.name }
        case .sku:
            items.sort { $0.sku < $1.sku }
        case .quantity:
            items.sort { $0.quantityOnHand > $1.quantityOnHand }
        case .category:
            items.sort { ($0.category ?? "") < ($1.category ?? "") }
        case .dateAdded:
            items.sort { $0.createdAt > $1.createdAt }
        }
        
        return items
    }
    
    var categories: [String] {
        let allCategories = inventoryItems.compactMap { $0.category }
        return Array(Set(allCategories)).sorted()
    }
    
    var lowStockItems: [InventoryItem] {
        return inventoryItems.filter { $0.isLowStock }
    }
    
    var outOfStockItems: [InventoryItem] {
        return inventoryItems.filter { $0.quantityOnHand == 0 }
    }
    
    func loadInventoryItems() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // TODO: Replace with actual team_id from AuthService.currentUser.teamId
            guard let teamId = UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else { // Example UUID
                errorMessage = "Team ID not available."
                return
            }
            
            let items: [InventoryItem] = try await supabase
                .from("inventory_items")
                .select()
                .eq("team_id", value: teamId)
                .order("name", ascending: true)
                .execute()
                .value
            
            self.inventoryItems = items
        } catch {
            print("Supabase connection failed, using sample data: \(error)")
            
            // Use sample data if Supabase fails (no connection, not configured, etc)
            self.inventoryItems = InventoryItem.sampleItems
            errorMessage = nil // Clear error since we're falling back to sample data
        }
    }
    
    func createInventoryItem(item: InventoryItem) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("inventory_items")
                .insert(item)
                .execute()
            await loadInventoryItems()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateInventoryItem(item: InventoryItem) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("inventory_items")
                .update(item)
                .eq("id", value: item.id)
                .execute()
            await loadInventoryItems()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteInventoryItem(item: InventoryItem) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("inventory_items")
                .delete()
                .eq("id", value: item.id)
                .execute()
            await loadInventoryItems()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func adjustStock(item: InventoryItem, adjustment: Int, reason: String) async throws {
        let updatedItem = InventoryItem(
            id: item.id,
            teamId: item.teamId,
            sku: item.sku,
            name: item.name,
            manufacturer: item.manufacturer,
            partNumber: item.partNumber,
            category: item.category,
            location: item.location,
            quantityOnHand: max(0, item.quantityOnHand + adjustment),
            lowStockThreshold: item.lowStockThreshold,
            unitCost: item.unitCost,
            description: item.description,
            imageUrl: item.imageUrl,
            createdAt: item.createdAt,
            updatedAt: Date()
        )
        
        try await updateInventoryItem(item: updatedItem)
        
        // TODO: Log stock transaction
        // try await logStockTransaction(itemId: item.id, adjustment: adjustment, reason: reason)
    }
}
