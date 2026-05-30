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
    @Published var storageInfo: StorageInfo?
    @Published var syncStatus: SyncStatus?
    
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let supabase = SupabaseService.shared.client
    
    // Enhanced offline storage
    private let localStorage = LocalStorage.shared
    private let syncService = SyncService.shared
    private var notificationObservers = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: .ftchubSyncQueueDidMutate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStorageInfo()
            }
            .store(in: &notificationObservers)
        
        // Only start network monitoring if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            startNetworkMonitoring()
            loadOfflineData()
            updateStorageInfo()
        } else {
            // Set mock values for previews
            self.isOnline = true
            self.isOfflineMode = false
            self.pendingSyncCount = 0
            self.lastSyncDate = Date()
            self.storageInfo = StorageInfo(totalRecords: 0, storageSize: 0, lastModified: Date())
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
                self?.updateStorageInfo()
            }
        }
        networkMonitor.start(queue: queue)
    }
    
    // MARK: - Offline Data Management
    func saveOfflineData<T: Codable>(_ data: T, tableName: String, id: String) {
        localStorage.save(data, tableName: tableName, id: id)
        updateStorageInfo()
    }
    
    func loadOfflineData<T: Codable>(_ type: T.Type, tableName: String, id: String) -> T? {
        return localStorage.load(type, tableName: tableName, id: id)
    }
    
    func loadAllOfflineData<T: Codable>(_ type: T.Type, tableName: String) -> [T] {
        return localStorage.loadAll(type, tableName: tableName)
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
        // Always save locally first
        saveOfflineData(event, tableName: "events", id: event.id.uuidString)
        
        if isOnline {
            do {
                try await supabase
                    .from("events")
                    .insert(event)
                    .execute()
            } catch {
                // If online save fails, queue for offline sync
                queueOfflineOperation(.createEvent(event))
            }
        } else {
            queueOfflineOperation(.createEvent(event))
        }
    }
    
    func createOfflineInventoryItem(_ item: InventoryItem) async {
        // Always save locally first
        saveOfflineData(item, tableName: "inventory_items", id: item.id.uuidString)
        
        if isOnline {
            do {
                _ = try await supabase
                    .from("inventory_items")
                    .insert(item)
                    .execute()
            } catch {
                // If online save fails, queue for offline sync
                queueOfflineOperation(.createInventoryItem(item))
            }
        } else {
            queueOfflineOperation(.createInventoryItem(item))
        }
    }
    
    func createOfflineScoutingReport(_ report: ScoutingReport) async {
        // Always save locally first
        saveOfflineData(report, tableName: "scouting_reports", id: report.id.uuidString)
        
        if isOnline {
            do {
                _ = try await supabase
                    .from("scouting_reports")
                    .insert(report)
                    .execute()
            } catch {
                // If online save fails, queue for offline sync
                queueOfflineOperation(.createScoutingReport(report))
            }
        } else {
            queueOfflineOperation(.createScoutingReport(report))
        }
    }
    
    // MARK: - Sync Operations
    private func queueOfflineOperation(_ operation: SyncOperation) {
        // Add to sync queue using the new sync service
        switch operation {
        case .createEvent(let event):
            if let data = try? JSONEncoder().encode(event) {
                localStorage.addToSyncQueue(operationType: "CREATE", tableName: "events", recordId: event.id.uuidString, data: data)
            }
        case .createInventoryItem(let item):
            if let data = try? JSONEncoder().encode(item) {
                localStorage.addToSyncQueue(operationType: "CREATE", tableName: "inventory_items", recordId: item.id.uuidString, data: data)
            }
        case .createScoutingReport(let report):
            if let data = try? JSONEncoder().encode(report) {
                localStorage.addToSyncQueue(operationType: "CREATE", tableName: "scouting_reports", recordId: report.id.uuidString, data: data)
            }
        default:
            // Handle other operations as needed
            break
        }
        updateStorageInfo()
    }
    
    func syncPendingChanges() async {
        guard isOnline else { return }
        
        isOfflineMode = false
        await syncService.performFullSync()
        updateStorageInfo()
    }
    
    private func performSyncOperation(_ operation: SyncOperation) async throws {
        switch operation {
        case .createEvent(let event):
            try await supabase
                .from("events")
                .insert(event)
                .execute()
            
        case .updateEvent(let event):
            try await supabase
                .from("events")
                .update(event)
                .eq("id", value: event.id)
                .execute()
            
        case .deleteEvent(let eventId):
            try await supabase
                .from("events")
                .delete()
                .eq("id", value: eventId)
                .execute()
            
        case .createInventoryItem(let item):
            try await supabase
                .from("inventory_items")
                .insert(item)
                .execute()
            
        case .updateInventoryItem(let item):
            try await supabase
                .from("inventory_items")
                .update(item)
                .eq("id", value: item.id)
                .execute()
            
        case .deleteInventoryItem(let itemId):
            try await supabase
                .from("inventory_items")
                .delete()
                .eq("id", value: itemId)
                .execute()
            
        case .createScoutingReport(let report):
            try await supabase
                .from("scouting_reports")
                .insert(report)
                .execute()
            
        case .updateScoutingReport(let report):
            try await supabase
                .from("scouting_reports")
                .update(report)
                .eq("id", value: report.id)
                .execute()
            
        case .deleteScoutingReport(let reportId):
            try await supabase
                .from("scouting_reports")
                .delete()
                .eq("id", value: reportId)
                .execute()
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
    
    // MARK: - Storage Management
    private func updateStorageInfo() {
        storageInfo = localStorage.getStorageInfo()
        syncStatus = syncService.getSyncStatus()
        pendingSyncCount = syncStatus?.pendingOperations ?? 0
        lastSyncDate = syncStatus?.lastSyncDate
    }
    
    func clearAllOfflineData() {
        localStorage.clearAllData()
        updateStorageInfo()
    }
    
    func getStorageInfo() -> StorageInfo? {
        return storageInfo
    }
    
    func getSyncStatus() -> SyncStatus? {
        return syncStatus
    }
    
    // MARK: - Manual Sync
    func syncNow() async {
        await syncService.syncNow()
        updateStorageInfo()
    }
    
    func clearSyncQueue() {
        syncService.clearSyncQueue()
        updateStorageInfo()
    }
}

// MARK: - Legacy Support (kept for compatibility)
// The old OfflineStorage class has been replaced by LocalStorage
// This enum is kept for backward compatibility with existing sync operations

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

