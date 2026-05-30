//
//  ResourcesService.swift
//  FTCHUB
//
//  Created for Phase 5: Resources Page Major Overhaul
//

import Foundation
import Combine
import Supabase

@MainActor
class ResourcesService: ObservableObject {
    static let shared: ResourcesService = {
        let service = ResourcesService()
        // Ensure resources are loaded immediately
        return service
    }()
    
    @Published var resources: [FTCResource]
    @Published var bookmarkedResources: [FTCResource] = []
    @Published var recentResources: [FTCResource] = []
    @Published var popularResources: [FTCResource] = []
    @Published var recentSearches: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    private weak var authService: AuthService?
    private let localStore = LocalResourceStore.shared
    private let manifestManager = ResourceManifestManager.shared
    private let searchIndex = ResourceSearchIndex.shared
    private let spotlightIndexer = ResourceSpotlightIndexer.shared
    
    // Search and filter state
    @Published var searchQuery: String = ""
    @Published var selectedCategory: ResourceCategory?
    @Published var selectedDifficulty: ResourceDifficulty?
    @Published var selectedSortOption: SortOption = .alphabetical
    @Published var showOfficialOnly: Bool = false
    @Published var showFeaturedOnly: Bool = false
    
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case latest = "Latest"
        case popular = "Popular"
        case bookmarked = "Bookmarked"
        case alphabetical = "Alphabetical"
    }
    
    // Load default resources from JSON bundle
    private static func loadDefaultResources() -> [FTCResource] {
        guard let url = Bundle.main.url(forResource: "defaultResources", withExtension: "json") else {
            // Fallback to empty array if JSON not found
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([FTCResource].self, from: data)
        } catch {
            DebugLog.log("Failed to load default resources from JSON: \(error)")
            return []
        }
    }
    
    // Static default resources that are available immediately (no async loading needed)
    // Using fixed UUIDs to avoid generation overhead
    private static let defaultResources: [FTCResource] = loadDefaultResources()
    
    // Legacy hardcoded resources as fallback (kept for backward compatibility)
    private static let legacyDefaultResources: [FTCResource] = [
        FTCResource(
            id: UUID(uuidString: "2c690c8f-b044-4bd5-beb2-f31247d52409")!,
            title: "FTC Rules & Game Manual",
            description: "Complete collection of all FTC game rules, robot rules, game manual parts, rule updates, and official documentation. Essential reading for all teams.",
            explanation: nil,
            url: "https://www.firstinspires.org/robotics/ftc/game-and-season",
            category: .rules,
            icon: "book.closed.fill",
            subPages: [
                ResourceSubPage(title: "Game Manual Part 1 - Game Rules", url: "https://www.firstinspires.org/sites/default/files/uploads/robotics/ftc/game-manual-part-1.pdf", description: "Complete game rules including field setup, game play, scoring, match procedures, and alliance selection"),
                ResourceSubPage(title: "Game Manual Part 2 - Robot Rules", url: "https://www.firstinspires.org/sites/default/files/uploads/robotics/ftc/game-manual-part-2.pdf", description: "Robot constraints, size limits, weight requirements, part legality, inspection requirements, and safety rules"),
                ResourceSubPage(title: "Game & Season Overview", url: "https://www.firstinspires.org/robotics/ftc/game-and-season", description: "Official game and season information, rule updates, game manual downloads, and season resources"),
                ResourceSubPage(title: "Rule Updates & Q&A", url: "https://www.firstinspires.org/robotics/ftc/forum", description: "Official rule updates, Q&A forum, rule clarifications, and interpretations from FIRST"),
                ResourceSubPage(title: "Inspection Checklist", url: "https://www.firstinspires.org/robotics/ftc/competition", description: "Robot inspection requirements, checklist, common violations, and preparation guide"),
                ResourceSubPage(title: "Part Legality & Legal Parts List", url: "https://www.firstinspires.org/robotics/ftc/legal-parts", description: "Official list of legal parts, part legality rules, custom part requirements, and part restrictions"),
                ResourceSubPage(title: "Safety Rules & Requirements", url: "https://www.firstinspires.org/robotics/ftc/safety", description: "Safety requirements, electrical safety, mechanical safety, and competition safety protocols"),
                ResourceSubPage(title: "Awards & Judging Criteria", url: "https://www.firstinspires.org/robotics/ftc/awards", description: "Award categories, judging criteria, Engineering Portfolio requirements, and presentation guidelines")
            ]
        ),
        FTCResource(
            id: UUID(uuidString: "a54c084b-de08-4df1-8934-881fc63986e7")!,
            title: "Robot Design & Mechanisms",
            description: "Comprehensive guide to robot design principles, drivetrains, linear motion systems, intakes, arms, and design tradeoffs. Learn from gm0.org and FTC best practices to build competitive robots.",
            explanation: nil,
            url: "https://gm0.org/en/latest/docs/common-mechanisms/",
            category: .technical,
            icon: "gearshape.2.fill",
            subPages: []
        ),
        FTCResource(
            id: UUID(uuidString: "70363b6c-2e87-43dd-99ef-725b7bfcbe81")!,
            title: "Programming & Software",
            description: "Complete guide to FTC programming from getting started to advanced techniques. Learn Blocks and Java programming, control systems, autonomous programming, sensor integration, and SDK usage.",
            explanation: nil,
            url: "https://gm0.org/en/latest/docs/software/",
            category: .programming,
            icon: "laptopcomputer",
            subPages: []
        ),
        FTCResource(
            id: UUID(uuidString: "60cd6290-e52e-4202-a66c-2f2cff2720d4")!,
            title: "Electronics & Control Systems",
            description: "Complete guide to FTC electronics including Control Hub, Expansion Hub, motors, servos, sensors, wiring, and driver station setup. Learn proper electrical safety and system configuration.",
            explanation: nil,
            url: "https://gm0.org/en/latest/docs/power-and-electronics/",
            category: .technical,
            icon: "cpu.fill",
            subPages: []
        ),
        FTCResource(
            id: UUID(uuidString: "708852a0-d105-469e-bb90-f2f93b9f5ada")!,
            title: "Team Management & Strategy",
            description: "Comprehensive guide to starting and organizing FTC teams, outreach and community engagement, competition strategy, awards and judging, and effective team communication.",
            explanation: nil,
            url: "https://gm0.org/en/latest/docs/being-a-team/",
            category: .strategy,
            icon: "person.3.fill",
            subPages: []
        ),
        FTCResource(
            id: UUID(uuidString: "c5d6bf7e-33c5-4400-b382-63af71e1d087")!,
            title: "Competition Preparation & Manufacturing",
            description: "Complete guide to competition preparation, game manual understanding, custom manufacturing techniques, hardware components, and troubleshooting. Learn how to prepare for competition day and manufacture custom parts.",
            explanation: nil,
            url: "https://gm0.org/en/latest/docs/custom-manufacturing/",
            category: .parts,
            icon: "wrench.and.screwdriver.fill",
            subPages: []
        )
    ]
    
    private init() {
        // Initialize with resources from JSON bundle immediately - synchronous load for instant availability
        // This ensures resources are ready instantly when the view appears
        if Self.defaultResources.isEmpty {
            // Fallback to legacy hardcoded resources if JSON load failed
            self.resources = Self.legacyDefaultResources
        } else {
        self.resources = Self.defaultResources
        }
        self.isLoading = false
        
        // Load bookmarks and recents from local store
        updateBookmarkedResources()
        updateRecentResources()
        updatePopularResources()
        
        // Build search index
        searchIndex.buildIndex(from: self.resources)
        
        // Index in CoreSpotlight
        spotlightIndexer.indexResources(self.resources)
        
        // Try to update manifest in background (non-blocking)
        Task.detached(priority: .utility) {
            do {
                await self.manifestManager.updateManifestIfNeeded()
                await MainActor.run {
                    // Apply manifest updates to resources
                    let updatedResources = self.manifestManager.applyManifest(to: self.resources)
                    // Compare by IDs since resources may have different metadata
                    let updatedIds = Set(updatedResources.map { $0.id })
                    let currentIds = Set(self.resources.map { $0.id })
                    if updatedIds != currentIds || updatedResources.count != self.resources.count {
                        self.resources = updatedResources
                        // Rebuild index after manifest update
                        self.searchIndex.buildIndex(from: self.resources)
                        self.spotlightIndexer.indexResources(self.resources)
                        // Update derived lists
                        self.updateBookmarkedResources()
                        self.updateRecentResources()
                        self.updatePopularResources()
                    }
                }
            } catch {
                // Silently fail - manifest update is optional
                DebugLog.log("Manifest update failed: \(error.localizedDescription)")
            }
        }
    }
    
    func bindAuthService(_ service: AuthService) {
        authService = service
    }
    
    // MARK: - Resource Loading
    
    /// Loads all resources from the database
    /// Returns immediately if resources are already loaded
    func loadResources() async throws {
        // If resources are already loaded, return immediately (no async work needed)
        if !resources.isEmpty {
            return
        }
        
        // Don't set isLoading for already-loaded resources check - instant return
        // Only set loading state if we actually need to load
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Always load hardcoded resources first for immediate availability
        // This ensures resources are available instantly without waiting for database
        await loadHardcodedResources()
        
        // Database loading is completely optional and non-blocking
        // Resources are already available from hardcoded list
    }
    
    /// Fallback: Load hardcoded resources
    private func loadHardcodedResources() async {
        // Resources are already loaded synchronously in init, so this is a no-op
        // Kept for backward compatibility if any code still calls it
        if resources.isEmpty {
            if Self.defaultResources.isEmpty {
                resources = Self.legacyDefaultResources
            } else {
            resources = Self.defaultResources
            }
        }
        
        // Try to update manifest
        await manifestManager.updateManifestIfNeeded()
        resources = manifestManager.applyManifest(to: resources)
    }
    
    // MARK: - Bookmarks
    
    func loadBookmarks() async throws {
        updateBookmarkedResources()
    }
    
    func addBookmark(_ resource: FTCResource) async throws {
        localStore.addBookmark(resource.id)
        updateBookmarkedResources()
    }
    
    func removeBookmark(_ resource: FTCResource) async throws {
        localStore.removeBookmark(resource.id)
        updateBookmarkedResources()
    }
    
    func isBookmarked(_ resource: FTCResource) -> Bool {
        return localStore.isBookmarked(resource.id)
    }
    
    private func updateBookmarkedResources() {
        let bookmarkIds = localStore.getBookmarks()
        bookmarkedResources = resources.filter { bookmarkIds.contains($0.id) }
    }
    
    // MARK: - Resource Tracking
    
    func incrementViewCount(_ resource: FTCResource) async {
        localStore.incrementViewCount(for: resource.id)
        localStore.addRecentResource(resource.id)
        updateRecentResources()
        updatePopularResources()
    }
    
    func markAsRead(_ resource: FTCResource) async throws {
        localStore.addRecentResource(resource.id)
        updateRecentResources()
    }
    
    private func updateRecentResources() {
        let recentIds = localStore.getRecentResources()
        recentResources = recentIds.compactMap { id in
            resources.first { $0.id == id }
        }
    }
    
    private func updatePopularResources() {
        let viewCounts = localStore.getAllViewCounts()
        popularResources = resources.sorted { resource1, resource2 in
            let count1 = viewCounts[resource1.id] ?? 0
            let count2 = viewCounts[resource2.id] ?? 0
            return count1 > count2
        }
    }
    
    // MARK: - Search & Filter
    
    /// Returns filtered and sorted resources based on current search/filter state
    var filteredResources: [FTCResource] {
        var result = resources
        
        // Apply search (only if query is not empty and has meaningful content)
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty && trimmedQuery.count >= 2 {
            result = searchIndex.search(query: trimmedQuery)
        } else if !trimmedQuery.isEmpty {
            // Query too short, return empty or all results
            // Return all for better UX
        }
        
        // Apply filters
        result = searchIndex.filter(
            resources: result,
            category: selectedCategory,
            difficulty: selectedDifficulty,
            isOfficial: showOfficialOnly ? true : nil,
            featured: showFeaturedOnly ? true : nil
        )
        
        // Apply sorting
        let bookmarkedIds = Set(localStore.getBookmarks())
        let viewCounts = localStore.getAllViewCounts()
        
        let sortOption: ResourceSearchIndex.SortOption
        switch selectedSortOption {
        case .relevance:
            sortOption = .relevance(query: searchQuery)
        case .latest:
            sortOption = .latest
        case .popular:
            sortOption = .popular
        case .bookmarked:
            sortOption = .bookmarked
        case .alphabetical:
            sortOption = .alphabetical
        }
        
        result = searchIndex.sort(
            resources: result,
            option: sortOption,
            bookmarkedIds: bookmarkedIds,
            viewCounts: viewCounts
        )
        
        return result
    }
    
    func clearFilters() {
        searchQuery = ""
        selectedCategory = nil
        selectedDifficulty = nil
        showOfficialOnly = false
        showFeaturedOnly = false
        selectedSortOption = .alphabetical
        // Rebuild index to ensure fresh search results
        rebuildSearchIndex()
    }
    
    func rebuildSearchIndex() {
        searchIndex.buildIndex(from: resources)
    }
}
