//
//  LocalResourceStore.swift
//  FTCHUB
//
//  Created for Phase 1: Resources Enhancement
//  Local-only storage for bookmarks, recents, and view counts (no DB required)
//

import Foundation

/// Local-only storage for resource personalization data
@MainActor
final class LocalResourceStore {
    static let shared = LocalResourceStore()
    
    private let bookmarksKey = "ftchub.resources.bookmarks.v1"
    private let recentsKey = "ftchub.resources.recents.v1"
    private let viewCountsKey = "ftchub.resources.viewCounts.v1"
    private let maxRecentsCount = 50
    
    private init() {}
    
    // MARK: - Bookmarks
    
    func getBookmarks() -> [UUID] {
        guard let array = UserDefaults.standard.array(forKey: bookmarksKey) as? [String] else {
            return []
        }
        return array.compactMap { UUID(uuidString: $0) }
    }
    
    func addBookmark(_ resourceId: UUID) {
        var bookmarks = getBookmarks()
        if !bookmarks.contains(resourceId) {
            bookmarks.insert(resourceId, at: 0) // Add to front
            saveBookmarks(bookmarks)
        }
    }
    
    func removeBookmark(_ resourceId: UUID) {
        var bookmarks = getBookmarks()
        bookmarks.removeAll { $0 == resourceId }
        saveBookmarks(bookmarks)
    }
    
    func isBookmarked(_ resourceId: UUID) -> Bool {
        return getBookmarks().contains(resourceId)
    }
    
    private func saveBookmarks(_ bookmarks: [UUID]) {
        let stringArray = bookmarks.map { $0.uuidString }
        UserDefaults.standard.set(stringArray, forKey: bookmarksKey)
    }
    
    // MARK: - Recent Resources
    
    struct RecentResource: Codable {
        let resourceId: UUID
        let viewedAt: Date
    }
    
    func getRecentResources() -> [UUID] {
        guard let data = UserDefaults.standard.data(forKey: recentsKey),
              let recents = try? JSONDecoder().decode([RecentResource].self, from: data) else {
            return []
        }
        // Return most recent first, limit to maxRecentsCount
        return Array(recents.sorted { $0.viewedAt > $1.viewedAt }.prefix(maxRecentsCount).map { $0.resourceId })
    }
    
    func addRecentResource(_ resourceId: UUID) {
        var recents: [RecentResource]
        if let data = UserDefaults.standard.data(forKey: recentsKey),
           let decoded = try? JSONDecoder().decode([RecentResource].self, from: data) {
            recents = decoded
        } else {
            recents = []
        }
        
        // Remove existing entry for this resource
        recents.removeAll { $0.resourceId == resourceId }
        
        // Add new entry at the front
        recents.insert(RecentResource(resourceId: resourceId, viewedAt: Date()), at: 0)
        
        // Limit to maxRecentsCount
        if recents.count > maxRecentsCount {
            recents = Array(recents.prefix(maxRecentsCount))
        }
        
        if let encoded = try? JSONEncoder().encode(recents) {
            UserDefaults.standard.set(encoded, forKey: recentsKey)
        }
    }
    
    // MARK: - View Counts
    
    func getViewCount(for resourceId: UUID) -> Int {
        guard let dict = UserDefaults.standard.dictionary(forKey: viewCountsKey) as? [String: Int] else {
            return 0
        }
        return dict[resourceId.uuidString] ?? 0
    }
    
    func incrementViewCount(for resourceId: UUID) {
        var dict: [String: Int]
        if let existing = UserDefaults.standard.dictionary(forKey: viewCountsKey) as? [String: Int] {
            dict = existing
        } else {
            dict = [:]
        }
        
        dict[resourceId.uuidString] = (dict[resourceId.uuidString] ?? 0) + 1
        UserDefaults.standard.set(dict, forKey: viewCountsKey)
    }
    
    func getAllViewCounts() -> [UUID: Int] {
        guard let dict = UserDefaults.standard.dictionary(forKey: viewCountsKey) as? [String: Int] else {
            return [:]
        }
        var result: [UUID: Int] = [:]
        for (key, value) in dict {
            if let uuid = UUID(uuidString: key) {
                result[uuid] = value
            }
        }
        return result
    }
}


