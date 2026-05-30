//
//  ResourceSpotlightIndexer.swift
//  FTCHUB
//
//  Created for Phase 2: Resources Enhancement
//  CoreSpotlight indexing for deep linking and system-wide search
//

import Foundation
@preconcurrency import CoreSpotlight
import MobileCoreServices

/// Manages CoreSpotlight indexing for resources
@MainActor
final class ResourceSpotlightIndexer {
    static let shared = ResourceSpotlightIndexer()
    
    private init() {}
    
    // MARK: - Indexing
    
    /// Indexes all resources in CoreSpotlight
    func indexResources(_ resources: [FTCResource]) {
        let searchableItems = resources.map { resource -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            
            // Basic metadata
            attributeSet.title = resource.title
            attributeSet.contentDescription = resource.description
            attributeSet.keywords = [
                resource.title,
                resource.category.displayName,
                resource.description
            ]
            
            // Add subpage titles as keywords
            if let subPages = resource.subPages {
                let subPageTitles = subPages.map { $0.title }
                attributeSet.keywords?.append(contentsOf: subPageTitles)
            }
            
            // Add difficulty and category
            if let difficulty = resource.difficulty {
                attributeSet.keywords?.append(difficulty.displayName)
            }
            attributeSet.keywords?.append(resource.category.displayName)
            
            // Unique identifier
            let uniqueIdentifier = "ftchub.resource.\(resource.id.uuidString)"
            
            // Create searchable item
            let item = CSSearchableItem(
                uniqueIdentifier: uniqueIdentifier,
                domainIdentifier: "ftchub.resources",
                attributeSet: attributeSet
            )
            
            return item
        }
        
        // Index items
        let itemsToIndex = searchableItems
        CSSearchableIndex.default().indexSearchableItems(itemsToIndex) { error in
            if let error = error {
                DebugLog.log("Error indexing resources in Spotlight: \(error)")
            } else {
                DebugLog.log("Successfully indexed \(searchableItems.count) resources in Spotlight")
            }
        }
    }
    
    /// Removes all indexed resources
    func deindexAllResources() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["ftchub.resources"]) { error in
            if let error = error {
                DebugLog.log("Error deindexing resources: \(error)")
            }
        }
    }
    
    /// Updates index for a single resource
    func updateResource(_ resource: FTCResource) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = resource.title
        attributeSet.contentDescription = resource.description
        
        let uniqueIdentifier = "ftchub.resource.\(resource.id.uuidString)"
        let item = CSSearchableItem(
            uniqueIdentifier: uniqueIdentifier,
            domainIdentifier: "ftchub.resources",
            attributeSet: attributeSet
        )
        
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                DebugLog.log("Error updating resource in Spotlight: \(error)")
            }
        }
    }
    
    /// Removes a resource from the index
    func removeResource(_ resourceId: UUID) {
        let uniqueIdentifier = "ftchub.resource.\(resourceId.uuidString)"
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [uniqueIdentifier]) { error in
            if let error = error {
                DebugLog.log("Error removing resource from Spotlight: \(error)")
            }
        }
    }
}

