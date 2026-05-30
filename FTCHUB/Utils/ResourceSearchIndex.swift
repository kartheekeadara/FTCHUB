//
//  ResourceSearchIndex.swift
//  FTCHUB
//
//  Created for Phase 2: Resources Enhancement
//  In-memory search index for fast resource searching
//

import Foundation

/// Fast in-memory search index for resources
@MainActor
final class ResourceSearchIndex {
    static let shared = ResourceSearchIndex()
    
    // Tokenized index: lowercase word -> [resource IDs]
    private var index: [String: Set<UUID>] = [:]
    private var resources: [FTCResource] = []
    
    private init() {}
    
    // MARK: - Index Building
    
    func buildIndex(from resources: [FTCResource]) {
        self.resources = resources
        index.removeAll()
        
        for resource in resources {
            // Index title
            indexTokens(from: resource.title, for: resource.id)
            
            // Index description
            indexTokens(from: resource.description, for: resource.id)
            
            // Index explanation if present
            if let explanation = resource.explanation {
                indexTokens(from: explanation, for: resource.id)
            }
            
            // Index subpage titles and descriptions
            if let subPages = resource.subPages {
                for subPage in subPages {
                    indexTokens(from: subPage.title, for: resource.id)
                    indexTokens(from: subPage.description, for: resource.id)
                }
            }
            
            // Index category
            indexTokens(from: resource.category.displayName, for: resource.id)
        }
    }
    
    private func indexTokens(from text: String, for resourceId: UUID) {
        // Tokenize: split by whitespace and punctuation, lowercase
        let tokens = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && $0.count > 2 } // Ignore very short tokens
        
        for token in tokens {
            if index[token] == nil {
                index[token] = Set<UUID>()
            }
            index[token]?.insert(resourceId)
        }
    }
    
    // MARK: - Search
    
    /// Searches resources using the index
    func search(query: String) -> [FTCResource] {
        guard !query.isEmpty else {
            return resources
        }
        
        let queryTokens = query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        
        guard !queryTokens.isEmpty else {
            return resources
        }
        
        // Find resources that match any token (OR search)
        var matchingIds: Set<UUID> = []
        
        for token in queryTokens {
            // Exact match
            if let ids = index[token] {
                matchingIds.formUnion(ids)
            }
            
            // Prefix match (for partial words)
            for (indexToken, ids) in index {
                if indexToken.hasPrefix(token) {
                    matchingIds.formUnion(ids)
                }
            }
        }
        
        // Convert IDs back to resources, maintaining order
        let matchingResources = resources.filter { matchingIds.contains($0.id) }
        
        // Score and sort by relevance (simple scoring: more token matches = higher score)
        let scoredResources = matchingResources.map { resource -> (resource: FTCResource, score: Int) in
            var score = 0
            let resourceText = "\(resource.title) \(resource.description)".lowercased()
            
            for token in queryTokens {
                if resource.title.lowercased().contains(token) {
                    score += 10 // Title matches are most important
                }
                if resourceText.contains(token) {
                    score += 1
                }
            }
            
            return (resource, score)
        }
        .sorted { $0.score > $1.score }
        .map { $0.resource }
        
        return scoredResources
    }
    
    // MARK: - Filtering
    
    func filter(
        resources: [FTCResource],
        category: ResourceCategory? = nil,
        difficulty: ResourceDifficulty? = nil,
        isOfficial: Bool? = nil,
        featured: Bool? = nil
    ) -> [FTCResource] {
        return resources.filter { resource in
            var matches = true
            
            if let category = category {
                matches = matches && resource.category == category
            }
            
            if let difficulty = difficulty {
                matches = matches && resource.difficulty == difficulty
            }
            
            if let isOfficial = isOfficial {
                matches = matches && resource.isOfficial == isOfficial
            }
            
            if let featured = featured {
                matches = matches && resource.featured == featured
            }
            
            return matches
        }
    }
    
    // MARK: - Sorting
    
    enum SortOption {
        case relevance(query: String)
        case latest
        case popular
        case bookmarked
        case alphabetical
    }
    
    func sort(
        resources: [FTCResource],
        option: SortOption,
        bookmarkedIds: Set<UUID> = [],
        viewCounts: [UUID: Int] = [:]
    ) -> [FTCResource] {
        switch option {
        case .relevance:
            // Already sorted by search, but can refine
            return resources
            
        case .latest:
            return resources.sorted { resource1, resource2 in
                let date1 = resource1.lastUpdated ?? Date.distantPast
                let date2 = resource2.lastUpdated ?? Date.distantPast
                return date1 > date2
            }
            
        case .popular:
            return resources.sorted { resource1, resource2 in
                let count1 = viewCounts[resource1.id] ?? 0
                let count2 = viewCounts[resource2.id] ?? 0
                return count1 > count2
            }
            
        case .bookmarked:
            return resources.sorted { resource1, resource2 in
                let bookmarked1 = bookmarkedIds.contains(resource1.id)
                let bookmarked2 = bookmarkedIds.contains(resource2.id)
                if bookmarked1 && !bookmarked2 {
                    return true
                } else if !bookmarked1 && bookmarked2 {
                    return false
                }
                return resource1.title < resource2.title
            }
            
        case .alphabetical:
            return resources.sorted { $0.title < $1.title }
        }
    }
}

