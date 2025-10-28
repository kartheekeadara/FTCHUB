//
//  OfflineService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Network
import Supabase

@MainActor
class OfflineService: ObservableObject {
    @Published var isOnline = true
    @Published var isOfflineMode = false
    @Published var pendingSyncCount = 0
    @Published var lastSyncDate: Date?
    
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let supabase = SupabaseService.shared.client
    
    // Offline storage
    private let offlineStorage = OfflineStorage()
    private var syncQueue: [SyncOperation] = []
    
    init() {
        // Only start network monitoring if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            startNetworkMonitoring()
            loadOfflineData()
        } else {
            // Set mock values for previews
            self.isOnline = true
            self.isOfflineMode = false
            self.pendingSyncCount = 0
            self.lastSyncDate = Date()
        }
    }
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
                if self?.isOnline == true {
                    await self?.syncPendingChanges()
                }
            }
        }
        networkMonitor.start(queue: queue)
    }
    
    // MARK: - Offline Data Management
    func saveOfflineData<T: Codable>(_ data: T, key: String) {
        offlineStorage.save(data, forKey: key)
    }
    
    func loadOfflineData<T: Codable>(_ type: T.Type, key: String) -> T? {
        return offlineStorage.load(type, forKey: key)
    }
    
    private func loadOfflineData() {
        // Load critical data for offline mode
        Task {
            await loadTeamDataOffline()
            await loadInventoryDataOffline()
            await loadScoutingDataOffline()
        }
    }
    
    // MARK: - Offline Operations
    func createOfflineEvent(_ event: Event) async {
        if isOnline {
            do {
                try await supabase
                    .from("events")
                    .insert(event)
                    .execute() as! Event
            } catch {
                // If online save fails, queue for offline
                queueOfflineOperation(.createEvent(event))
            }
        } else {
            queueOfflineOperation(.createEvent(event))
        }
        
        // Always save locally for offline access
        saveOfflineData(event, key: "event_\(event.id)")
    }
    
    func createOfflineInventoryItem(_ item: InventoryItem) async {
        if isOnline {
            do {
                try await supabase
                    .from("inventory_items")
                    .insert(item)
                    .execute() as! Event
            } catch {
                queueOfflineOperation(.createInventoryItem(item))
            }
        } else {
            queueOfflineOperation(.createInventoryItem(item))
        }
        
        saveOfflineData(item, key: "inventory_\(item.id)")
    }
    
    func createOfflineScoutingReport(_ report: ScoutingReport) async {
        if isOnline {
            do {
                try await supabase
                    .from("scouting_reports")
                    .insert(report)
                    .execute() as! Event
            } catch {
                queueOfflineOperation(.createScoutingReport(report))
            }
        } else {
            queueOfflineOperation(.createScoutingReport(report))
        }
        
        saveOfflineData(report, key: "scouting_report_\(report.id)")
    }
    
    // MARK: - Sync Operations
    private func queueOfflineOperation(_ operation: SyncOperation) {
        syncQueue.append(operation)
        pendingSyncCount = syncQueue.count
    }
    
    func syncPendingChanges() async {
        guard isOnline else { return }
        
        isOfflineMode = false
        var successCount = 0
        
        for operation in syncQueue {
            do {
                try await performSyncOperation(operation)
                successCount += 1
            } catch {
                print("Sync failed for operation: \(operation), error: \(error)")
            }
        }
        
        // Remove successful operations
        if successCount > 0 {
            syncQueue.removeFirst(successCount)
            pendingSyncCount = syncQueue.count
            lastSyncDate = Date()
        }
    }
    
    private func performSyncOperation(_ operation: SyncOperation) async throws {
        switch operation {
        case .createEvent(let event):
            try await supabase
                .from("events")
                .insert(event)
                .execute() as! InventoryItem
            
        case .updateEvent(let event):
            try await supabase
                .from("events")
                .update(event)
                .eq("id", value: event.id)
                .execute() as! InventoryItem
            
        case .deleteEvent(let eventId):
            try await supabase
                .from("events")
                .delete()
                .eq("id", value: eventId)
                .execute() as! InventoryItem
            
        case .createInventoryItem(let item):
            try await supabase
                .from("inventory_items")
                .insert(item)
                .execute() as! InventoryItem
            
        case .updateInventoryItem(let item):
            try await supabase
                .from("inventory_items")
                .update(item)
                .eq("id", value: item.id)
                .execute() as! InventoryItem
            
        case .deleteInventoryItem(let itemId):
            try await supabase
                .from("inventory_items")
                .delete()
                .eq("id", value: itemId)
                .execute() as! InventoryItem
            
        case .createScoutingReport(let report):
            try await supabase
                .from("scouting_reports")
                .insert(report)
                .execute() as! InventoryItem
            
        case .updateScoutingReport(let report):
            try await supabase
                .from("scouting_reports")
                .update(report)
                .eq("id", value: report.id)
                .execute() as! InventoryItem
            
        case .deleteScoutingReport(let reportId):
            try await supabase
                .from("scouting_reports")
                .delete()
                .eq("id", value: reportId)
                .execute() as! InventoryItem
        }
    }
    
    // MARK: - Offline Data Loading
    private func loadTeamDataOffline() async {
        // Load team data for offline access
        // This would typically load from local storage
    }
    
    private func loadInventoryDataOffline() async {
        // Load inventory data for offline access
    }
    
    private func loadScoutingDataOffline() async {
        // Load scouting data for offline access
    }
    
    // MARK: - Offline Mode Toggle
    func enableOfflineMode() {
        isOfflineMode = true
        // Disable network operations
    }
    
    func disableOfflineMode() {
        isOfflineMode = false
        Task {
            await syncPendingChanges()
        }
    }
}

// MARK: - Offline Storage
class OfflineStorage {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func save<T: Codable>(_ data: T, forKey key: String) {
        let url = documentsDirectory.appendingPathComponent("\(key).json")
        
        do {
            let encodedData = try JSONEncoder().encode(data)
            try encodedData.write(to: url)
        } catch {
            print("Failed to save offline data: \(error)")
        }
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let url = documentsDirectory.appendingPathComponent("\(key).json")
        
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to load offline data: \(error)")
            return nil
        }
    }
    
    func delete(forKey key: String) {
        let url = documentsDirectory.appendingPathComponent("\(key).json")
        try? fileManager.removeItem(at: url)
    }
    
    func clearAll() {
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear offline data: \(error)")
        }
    }
}

// MARK: - Sync Operations
enum SyncOperation {
    case createEvent(Event)
    case updateEvent(Event)
    case deleteEvent(UUID)
    case createInventoryItem(InventoryItem)
    case updateInventoryItem(InventoryItem)
    case deleteInventoryItem(UUID)
    case createScoutingReport(ScoutingReport)
    case updateScoutingReport(ScoutingReport)
    case deleteScoutingReport(UUID)
}

