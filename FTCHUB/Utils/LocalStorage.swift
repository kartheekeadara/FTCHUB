//
//  LocalStorage.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine
import SQLite3

/// Comprehensive local storage system for offline mode
@MainActor
class LocalStorage: ObservableObject {
    static let shared = LocalStorage()
    
    private var db: OpaquePointer?
    private let dbName = "ftchub_offline.db"
    
    @Published var isInitialized = false
    @Published var storageSize: Int64 = 0
    
    let objectWillChange = PassthroughSubject<Void, Never>()
    
    private init() {
        initializeDatabase()
    }
    
    deinit {
        Task { @MainActor in
            closeDatabase()
        }
    }
    
    // MARK: - Database Initialization
    private func initializeDatabase() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(dbName)
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            createTables()
            isInitialized = true
            updateStorageSize()
        } else {
            print("Unable to open database")
        }
    }
    
    private func createTables() {
        let createTablesSQL = """
        CREATE TABLE IF NOT EXISTS teams (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            last_modified INTEGER NOT NULL,
            sync_status TEXT DEFAULT 'pending'
        );
        
        CREATE TABLE IF NOT EXISTS profiles (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            last_modified INTEGER NOT NULL,
            sync_status TEXT DEFAULT 'pending'
        );
        
        CREATE TABLE IF NOT EXISTS events (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            last_modified INTEGER NOT NULL,
            sync_status TEXT DEFAULT 'pending'
        );
        
        CREATE TABLE IF NOT EXISTS inventory_items (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            last_modified INTEGER NOT NULL,
            sync_status TEXT DEFAULT 'pending'
        );
        
        CREATE TABLE IF NOT EXISTS scouting_reports (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            last_modified INTEGER NOT NULL,
            sync_status TEXT DEFAULT 'pending'
        );
        
        CREATE TABLE IF NOT EXISTS scouting_templates (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            last_modified INTEGER NOT NULL,
            sync_status TEXT DEFAULT 'pending'
        );
        
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            last_modified INTEGER NOT NULL,
            sync_status TEXT DEFAULT 'pending'
        );
        
        CREATE TABLE IF NOT EXISTS orders (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            last_modified INTEGER NOT NULL,
            sync_status TEXT DEFAULT 'pending'
        );
        
        CREATE TABLE IF NOT EXISTS sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_type TEXT NOT NULL,
            table_name TEXT NOT NULL,
            record_id TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            retry_count INTEGER DEFAULT 0
        );
        
        CREATE INDEX IF NOT EXISTS idx_sync_status ON teams(sync_status);
        CREATE INDEX IF NOT EXISTS idx_sync_status_profiles ON profiles(sync_status);
        CREATE INDEX IF NOT EXISTS idx_sync_status_events ON events(sync_status);
        CREATE INDEX IF NOT EXISTS idx_sync_status_inventory ON inventory_items(sync_status);
        CREATE INDEX IF NOT EXISTS idx_sync_status_scouting ON scouting_reports(sync_status);
        CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(created_at);
        """
        
        if sqlite3_exec(db, createTablesSQL, nil, nil, nil) == SQLITE_OK {
            print("Database tables created successfully")
        } else {
            print("Error creating tables: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    // MARK: - Generic CRUD Operations
    func save<T: Codable>(_ object: T, tableName: String, id: String) {
        guard let data = try? JSONEncoder().encode(object) else { return }
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        let insertSQL = """
        INSERT OR REPLACE INTO \(tableName) (id, data, last_modified, sync_status)
        VALUES (?, ?, ?, 'pending')
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, nil)
            sqlite3_bind_text(statement, 2, jsonString, -1, nil)
            sqlite3_bind_int64(statement, 3, timestamp)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Saved \(tableName) record: \(id)")
            } else {
                print("Error saving \(tableName) record: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
        updateStorageSize()
    }
    
    func load<T: Codable>(_ type: T.Type, tableName: String, id: String) -> T? {
        let selectSQL = "SELECT data FROM \(tableName) WHERE id = ?"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, nil)
            
            if sqlite3_step(statement) == SQLITE_ROW {
                if let dataString = sqlite3_column_text(statement, 0) {
                    let jsonString = String(cString: dataString)
                    if let data = jsonString.data(using: .utf8) {
                        return try? JSONDecoder().decode(type, from: data)
                    }
                }
            }
        }
        sqlite3_finalize(statement)
        return nil
    }
    
    func loadAll<T: Codable>(_ type: T.Type, tableName: String) -> [T] {
        let selectSQL = "SELECT data FROM \(tableName) ORDER BY last_modified DESC"
        var results: [T] = []
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let dataString = sqlite3_column_text(statement, 0) {
                    let jsonString = String(cString: dataString)
                    if let data = jsonString.data(using: .utf8),
                       let object = try? JSONDecoder().decode(type, from: data) {
                        results.append(object)
                    }
                }
            }
        }
        sqlite3_finalize(statement)
        return results
    }
    
    func delete(tableName: String, id: String) {
        let deleteSQL = "DELETE FROM \(tableName) WHERE id = ?"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, id, -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        updateStorageSize()
    }
    
    // MARK: - Sync Queue Management
    func addToSyncQueue(operationType: String, tableName: String, recordId: String, data: Data) {
        let insertSQL = """
        INSERT INTO sync_queue (operation_type, table_name, record_id, data, created_at)
        VALUES (?, ?, ?, ?, ?)
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, operationType, -1, nil)
            sqlite3_bind_text(statement, 2, tableName, -1, nil)
            sqlite3_bind_text(statement, 3, recordId, -1, nil)
            sqlite3_bind_blob(statement, 4, data.withUnsafeBytes { $0.baseAddress }, Int32(data.count), nil)
            sqlite3_bind_int64(statement, 5, Int64(Date().timeIntervalSince1970))
            
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func getSyncQueue() -> [SyncQueueItem] {
        let selectSQL = "SELECT * FROM sync_queue ORDER BY created_at ASC"
        var results: [SyncQueueItem] = []
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, selectSQL, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int64(statement, 0))
                let operationType = String(cString: sqlite3_column_text(statement, 1))
                let tableName = String(cString: sqlite3_column_text(statement, 2))
                let recordId = String(cString: sqlite3_column_text(statement, 3))
                let dataLength = sqlite3_column_bytes(statement, 4)
                let data = Data(bytes: sqlite3_column_blob(statement, 4), count: Int(dataLength))
                let createdAt = Int64(sqlite3_column_int64(statement, 5))
                let retryCount = Int(sqlite3_column_int(statement, 6))
                
                results.append(SyncQueueItem(
                    id: id,
                    operationType: operationType,
                    tableName: tableName,
                    recordId: recordId,
                    data: data,
                    createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt)),
                    retryCount: retryCount
                ))
            }
        }
        sqlite3_finalize(statement)
        return results
    }
    
    func removeFromSyncQueue(id: Int) {
        let deleteSQL = "DELETE FROM sync_queue WHERE id = ?"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    func incrementRetryCount(id: Int) {
        let updateSQL = "UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?"
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Storage Management
    private func updateStorageSize() {
        let fileURL = getDocumentsDirectory().appendingPathComponent(dbName)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            storageSize = attributes[.size] as? Int64 ?? 0
        } catch {
            print("Error getting storage size: \(error)")
        }
    }
    
    func clearAllData() {
        let tables = ["teams", "profiles", "events", "inventory_items", "scouting_reports", "scouting_templates", "tasks", "orders", "sync_queue"]
        
        for table in tables {
            let deleteSQL = "DELETE FROM \(table)"
            sqlite3_exec(db, deleteSQL, nil, nil, nil)
        }
        updateStorageSize()
    }
    
    func getStorageInfo() -> StorageInfo {
        let fileURL = getDocumentsDirectory().appendingPathComponent(dbName)
        var recordCount = 0
        
        let tables = ["teams", "profiles", "events", "inventory_items", "scouting_reports", "scouting_templates", "tasks", "orders"]
        for table in tables {
            let countSQL = "SELECT COUNT(*) FROM \(table)"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, countSQL, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    recordCount += Int(sqlite3_column_int(statement, 0))
                }
            }
            sqlite3_finalize(statement)
        }
        
        return StorageInfo(
            totalRecords: recordCount,
            storageSize: storageSize,
            lastModified: Date()
        )
    }
    
    // MARK: - Helper Methods
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
            db = nil
        }
    }
}

// MARK: - Supporting Types
struct SyncQueueItem {
    let id: Int
    let operationType: String
    let tableName: String
    let recordId: String
    let data: Data
    let createdAt: Date
    let retryCount: Int
}

struct StorageInfo {
    let totalRecords: Int
    let storageSize: Int64
    let lastModified: Date
}
