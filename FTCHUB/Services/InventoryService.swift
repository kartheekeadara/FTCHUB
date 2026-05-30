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
    @Published private(set) var activeTeamId: UUID?
    
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
    
    func lowStockThreshold(for category: String?) -> Int {
        let items = items(in: category)
        guard !items.isEmpty else { return 1 }
        let thresholds = items.map { $0.lowStockThreshold }
        guard let average = thresholds.average else { return 1 }
        return max(1, Int(round(average)))
    }
    
    func items(in category: String?) -> [InventoryItem] {
        inventoryItems.filter { item in
            if let category = category, !category.isEmpty {
                return item.category?.localizedCaseInsensitiveCompare(category) == .orderedSame
            } else {
                return item.category == nil || item.category?.isEmpty == true
            }
        }
    }
    
    var currentTeamId: UUID? { activeTeamId }
    var hasTeamContext: Bool { activeTeamId != nil }
    
    func updateTeamContext(teamId: UUID?) {
        guard activeTeamId != teamId else { return }
        activeTeamId = teamId
        if teamId == nil {
            inventoryItems = []
            errorMessage = nil
        } else {
            Task { await loadInventoryItems() }
        }
    }
    
    func loadInventoryItems() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let teamId = activeTeamId else {
                inventoryItems = []
                errorMessage = "Join or create a team to manage inventory."
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
            DebugLog.log("Supabase connection failed, using sample data: \(error)")
            
            // Use sample data if Supabase fails (no connection, not configured, etc)
            self.inventoryItems = InventoryItem.sampleItems
            errorMessage = nil // Clear error since we're falling back to sample data
            TelemetryService.shared.logError(error, context: ["action": "load_inventory"])
        }
    }
    
    func createInventoryItem(item: InventoryItem) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let teamId = activeTeamId else {
                errorMessage = "Join or create a team to manage inventory."
                return
            }
            
            var itemToSave = item
            itemToSave.teamId = teamId
            
            try await supabase
                .from("inventory_items")
                .insert(itemToSave)
                .execute()
            await loadInventoryItems()
            TelemetryService.shared.logEvent("inventory_item_created")
        } catch {
            errorMessage = error.localizedDescription
            TelemetryService.shared.logError(error, context: ["action": "create_inventory_item"])
            throw error
        }
    }
    
    func updateInventoryItem(item: InventoryItem) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let teamId = activeTeamId else {
                errorMessage = "Join or create a team to manage inventory."
                return
            }
            
            let previousItem = inventoryItems.first { $0.id == item.id }
            var updatedItem = item
            updatedItem.teamId = teamId
            
            try await supabase
                .from("inventory_items")
                .update(updatedItem)
                .eq("id", value: updatedItem.id)
                .execute()
            await loadInventoryItems()
            if let previousItem {
                NotificationService.shared.handleInventoryStockChange(from: previousItem, to: updatedItem)
            }
            TelemetryService.shared.logEvent("inventory_item_updated")
        } catch {
            errorMessage = error.localizedDescription
            TelemetryService.shared.logError(error, context: ["action": "update_inventory_item"])
            throw error
        }
    }
    
    func deleteInventoryItem(item: InventoryItem) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard activeTeamId != nil else {
                errorMessage = "Join or create a team to manage inventory."
                return
            }
            
            try await supabase
                .from("inventory_items")
                .delete()
                .eq("id", value: item.id)
                .execute()
            await loadInventoryItems()
            TelemetryService.shared.logEvent("inventory_item_deleted")
        } catch {
            errorMessage = error.localizedDescription
            TelemetryService.shared.logError(error, context: ["action": "delete_inventory_item"])
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
    
    func updateLowStockThreshold(for category: String?, to threshold: Int) async throws {
        guard let teamId = activeTeamId else {
            errorMessage = "Join or create a team to manage inventory."
            return
        }
        
        let cappedThreshold = max(0, threshold)
        let targets = items(in: category)
        
        guard !targets.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            for item in targets {
                var updated = item
                updated.teamId = teamId
                updated.lowStockThreshold = cappedThreshold
                try await supabase
                    .from("inventory_items")
                    .update(updated)
                    .eq("id", value: updated.id)
                    .execute()
            }
            await loadInventoryItems()
            TelemetryService.shared.logEvent("inventory_threshold_updated", parameters: ["category": category ?? "uncategorized", "threshold": "\(cappedThreshold)"])
        } catch {
            errorMessage = error.localizedDescription
            TelemetryService.shared.logError(error, context: ["action": "update_low_stock_threshold"])
            throw error
        }
    }
}

private extension Array where Element == Int {
    var average: Double? {
        guard !isEmpty else { return nil }
        let total = reduce(0, +)
        return Double(total) / Double(count)
    }
}
