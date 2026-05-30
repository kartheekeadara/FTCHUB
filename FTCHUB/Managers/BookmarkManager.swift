//
//  BookmarkManager.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import Foundation
import Combine

class BookmarkManager: ObservableObject {
    static let shared = BookmarkManager()
    
    @Published private(set) var bookmarkedModuleIds: Set<UUID> = []
    @Published private(set) var bookmarkedSectionIds: Set<UUID> = []
    
    private let moduleBookmarksKey = "bookmarked_module_ids"
    private let sectionBookmarksKey = "bookmarked_section_ids"
    private let achievementManager = AchievementManager.shared
    
    private init() {
        loadBookmarks()
    }
    
    // MARK: - Module Bookmarks
    func isModuleBookmarked(_ moduleId: UUID) -> Bool {
        bookmarkedModuleIds.contains(moduleId)
    }
    
    func toggleModuleBookmark(_ moduleId: UUID) {
        if bookmarkedModuleIds.contains(moduleId) {
            bookmarkedModuleIds.remove(moduleId)
        } else {
            bookmarkedModuleIds.insert(moduleId)
        }
        saveBookmarks()
        updateAchievementStats()
    }
    
    func addModuleBookmark(_ moduleId: UUID) {
        bookmarkedModuleIds.insert(moduleId)
        saveBookmarks()
    }
    
    func removeModuleBookmark(_ moduleId: UUID) {
        bookmarkedModuleIds.remove(moduleId)
        saveBookmarks()
    }
    
    // MARK: - Section Bookmarks
    func isSectionBookmarked(_ sectionId: UUID) -> Bool {
        bookmarkedSectionIds.contains(sectionId)
    }
    
    func toggleSectionBookmark(_ sectionId: UUID) {
        if bookmarkedSectionIds.contains(sectionId) {
            bookmarkedSectionIds.remove(sectionId)
        } else {
            bookmarkedSectionIds.insert(sectionId)
        }
        saveBookmarks()
        updateAchievementStats()
    }
    
    func addSectionBookmark(_ sectionId: UUID) {
        bookmarkedSectionIds.insert(sectionId)
        saveBookmarks()
    }
    
    func removeSectionBookmark(_ sectionId: UUID) {
        bookmarkedSectionIds.remove(sectionId)
        saveBookmarks()
    }
    
    // MARK: - Persistence
    private func loadBookmarks() {
        // Load module bookmarks
        if let data = UserDefaults.standard.data(forKey: moduleBookmarksKey),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            bookmarkedModuleIds = Set(ids.compactMap { UUID(uuidString: $0) })
        }
        
        // Load section bookmarks
        if let data = UserDefaults.standard.data(forKey: sectionBookmarksKey),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            bookmarkedSectionIds = Set(ids.compactMap { UUID(uuidString: $0) })
        }
    }
    
    private func saveBookmarks() {
        // Save module bookmarks
        let moduleIds = Array(bookmarkedModuleIds).map { $0.uuidString }
        if let data = try? JSONEncoder().encode(moduleIds) {
            UserDefaults.standard.set(data, forKey: moduleBookmarksKey)
        }
        
        // Save section bookmarks
        let sectionIds = Array(bookmarkedSectionIds).map { $0.uuidString }
        if let data = try? JSONEncoder().encode(sectionIds) {
            UserDefaults.standard.set(data, forKey: sectionBookmarksKey)
        }
    }
    
    private func updateAchievementStats() {
        let totalBookmarks = bookmarkedModuleIds.count + bookmarkedSectionIds.count
        achievementManager.updateBookmarkCount(totalBookmarks)
    }
}

