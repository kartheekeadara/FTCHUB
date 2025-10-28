//
//  SyncService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()
    
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var pendingOperations: Int = 0
    
    private let supabase = SupabaseService.shared.client
    private let localStorage = LocalStorage.shared
    private var syncTimer: Timer?
    
    private init() {
        startPeriodicSync()
    }
    
    // MARK: - Sync Management
    func startPeriodicSync() {
        // Sync every 30 seconds when online
        syncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncIfNeeded()
            }
        }
    }
    
    func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    func syncIfNeeded() async {
        guard !isSyncing else { return }
        await performFullSync()
    }
    
    func performFullSync() async {
        isSyncing = true
        syncError = nil
        syncProgress = 0.0
        
        do {
            // 1. Sync pending operations to server
            await syncPendingOperations()
            syncProgress = 0.3
            
            // 2. Pull latest data from server
            await pullLatestData()
            syncProgress = 0.7
            
            // 3. Resolve conflicts
            await resolveConflicts()
            syncProgress = 1.0
            
            lastSyncDate = Date()
            pendingOperations = localStorage.getSyncQueue().count
            
        } catch {
            syncError = error.localizedDescription
            print("Sync failed: \(error)")
        }
        
        isSyncing = false
    }
    
    // MARK: - Pending Operations Sync
    private func syncPendingOperations() async {
        let queueItems = localStorage.getSyncQueue()
        let totalItems = queueItems.count
        
        for (index, item) in queueItems.enumerated() {
            do {
                try await syncQueueItem(item)
                localStorage.removeFromSyncQueue(id: item.id)
            } catch {
                print("Failed to sync item \(item.id): \(error)")
                localStorage.incrementRetryCount(id: item.id)
                
                // Remove items that have failed too many times
                if item.retryCount >= 5 {
                    localStorage.removeFromSyncQueue(id: item.id)
                }
            }
            
            syncProgress = 0.3 + (0.4 * Double(index) / Double(totalItems))
        }
    }
    
    private func syncQueueItem(_ item: SyncQueueItem) async throws {
        switch item.operationType {
        case "CREATE":
            try await createRecord(tableName: item.tableName, data: item.data)
        case "UPDATE":
            try await updateRecord(tableName: item.tableName, recordId: item.recordId, data: item.data)
        case "DELETE":
            try await deleteRecord(tableName: item.tableName, recordId: item.recordId)
        default:
            throw SyncError.unknownOperation
        }
    }
    
    // MARK: - Server Operations
    private func createRecord(tableName: String, data: Data) async throws {
        switch tableName {
        case "teams":
            let team = try JSONDecoder().decode(Team.self, from: data)
            _ = try await supabase.from("teams").insert(team).execute()
        case "profiles":
            let profile = try JSONDecoder().decode(Profile.self, from: data)
            _ = try await supabase.from("profiles").insert(profile).execute()
        case "events":
            let event = try JSONDecoder().decode(Event.self, from: data)
            _ = try await supabase.from("events").insert(event).execute()
        case "inventory_items":
            let item = try JSONDecoder().decode(InventoryItem.self, from: data)
            _ = try await supabase.from("inventory_items").insert(item).execute()
        case "scouting_reports":
            let report = try JSONDecoder().decode(ScoutingReport.self, from: data)
            _ = try await supabase.from("scouting_reports").insert(report).execute()
        case "scouting_templates":
            let template = try JSONDecoder().decode(ScoutingTemplate.self, from: data)
            _ = try await supabase.from("scouting_templates").insert(template).execute()
        case "tasks":
            let task = try JSONDecoder().decode(TeamTask.self, from: data)
            _ = try await supabase.from("tasks").insert(task).execute()
        case "orders":
            let order = try JSONDecoder().decode(Order.self, from: data)
            _ = try await supabase.from("orders").insert(order).execute()
        default:
            throw SyncError.unknownTable
        }
    }
    
    private func updateRecord(tableName: String, recordId: String, data: Data) async throws {
        switch tableName {
        case "teams":
            let team = try JSONDecoder().decode(Team.self, from: data)
            _ = try await supabase.from("teams").update(team).eq("id", value: recordId).execute()
        case "profiles":
            let profile = try JSONDecoder().decode(Profile.self, from: data)
            _ = try await supabase.from("profiles").update(profile).eq("id", value: recordId).execute()
        case "events":
            let event = try JSONDecoder().decode(Event.self, from: data)
            _ = try await supabase.from("events").update(event).eq("id", value: recordId).execute()
        case "inventory_items":
            let item = try JSONDecoder().decode(InventoryItem.self, from: data)
            _ = try await supabase.from("inventory_items").update(item).eq("id", value: recordId).execute()
        case "scouting_reports":
            let report = try JSONDecoder().decode(ScoutingReport.self, from: data)
            _ = try await supabase.from("scouting_reports").update(report).eq("id", value: recordId).execute()
        case "scouting_templates":
            let template = try JSONDecoder().decode(ScoutingTemplate.self, from: data)
            _ = try await supabase.from("scouting_templates").update(template).eq("id", value: recordId).execute()
        case "tasks":
            let task = try JSONDecoder().decode(TeamTask.self, from: data)
            _ = try await supabase.from("tasks").update(task).eq("id", value: recordId).execute()
        case "orders":
            let order = try JSONDecoder().decode(Order.self, from: data)
            _ = try await supabase.from("orders").update(order).eq("id", value: recordId).execute()
        default:
            throw SyncError.unknownTable
        }
    }
    
    private func deleteRecord(tableName: String, recordId: String) async throws {
        _ = try await supabase.from(tableName).delete().eq("id", value: recordId).execute()
    }
    
    // MARK: - Pull Latest Data
    private func pullLatestData() async {
        do {
            // Pull teams
            let teams: [Team] = try await supabase.from("teams").select().execute().value
            for team in teams {
                localStorage.save(team, tableName: "teams", id: team.id.uuidString)
            }
            
            // Pull profiles
            let profiles: [Profile] = try await supabase.from("profiles").select().execute().value
            for profile in profiles {
                localStorage.save(profile, tableName: "profiles", id: profile.id.uuidString)
            }
            
            // Pull events
            let events: [Event] = try await supabase.from("events").select().execute().value
            for event in events {
                localStorage.save(event, tableName: "events", id: event.id.uuidString)
            }
            
            // Pull inventory items
            let inventoryItems: [InventoryItem] = try await supabase.from("inventory_items").select().execute().value
            for item in inventoryItems {
                localStorage.save(item, tableName: "inventory_items", id: item.id.uuidString)
            }
            
            // Pull scouting reports
            let scoutingReports: [ScoutingReport] = try await supabase.from("scouting_reports").select().execute().value
            for report in scoutingReports {
                localStorage.save(report, tableName: "scouting_reports", id: report.id.uuidString)
            }
            
            // Pull scouting templates
            let scoutingTemplates: [ScoutingTemplate] = try await supabase.from("scouting_templates").select().execute().value
            for template in scoutingTemplates {
                localStorage.save(template, tableName: "scouting_templates", id: template.id.uuidString)
            }
            
            // Pull tasks
            let tasks: [TeamTask] = try await supabase.from("tasks").select().execute().value
            for task in tasks {
                localStorage.save(task, tableName: "tasks", id: task.id.uuidString)
            }
            
            // Pull orders
            let orders: [Order] = try await supabase.from("orders").select().execute().value
            for order in orders {
                localStorage.save(order, tableName: "orders", id: order.id.uuidString)
            }
            
        } catch {
            print("Failed to pull latest data: \(error)")
            // Don't throw error to prevent sync failure
        }
    }
    
    // MARK: - Conflict Resolution
    private func resolveConflicts() async {
        // Simple last-writer-wins conflict resolution
        // In a production app, you might want more sophisticated conflict resolution
        print("Resolving conflicts...")
        // This is where you'd implement conflict resolution logic
    }
    
    // MARK: - Manual Sync Operations
    func syncNow() async {
        await performFullSync()
    }
    
    func clearSyncQueue() {
        let queueItems = localStorage.getSyncQueue()
        for item in queueItems {
            localStorage.removeFromSyncQueue(id: item.id)
        }
        pendingOperations = 0
    }
    
    func getSyncStatus() -> SyncStatus {
        let queueItems = localStorage.getSyncQueue()
        let storageInfo = localStorage.getStorageInfo()
        
        return SyncStatus(
            isSyncing: isSyncing,
            lastSyncDate: lastSyncDate,
            pendingOperations: queueItems.count,
            totalRecords: storageInfo.totalRecords,
            storageSize: storageInfo.storageSize,
            syncError: syncError
        )
    }
}

// MARK: - Supporting Types
enum SyncError: Error, LocalizedError {
    case unknownOperation
    case unknownTable
    case networkError
    case dataCorruption
    
    var errorDescription: String? {
        switch self {
        case .unknownOperation:
            return "Unknown sync operation"
        case .unknownTable:
            return "Unknown table name"
        case .networkError:
            return "Network connection error"
        case .dataCorruption:
            return "Data corruption detected"
        }
    }
}

struct SyncStatus {
    let isSyncing: Bool
    let lastSyncDate: Date?
    let pendingOperations: Int
    let totalRecords: Int
    let storageSize: Int64
    let syncError: String?
}
