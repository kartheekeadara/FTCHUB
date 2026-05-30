//
//  ResourceManifestManager.swift
//  FTCHUB
//
//  Created for Phase 1: Resources Enhancement
//  Manages remote manifest fetching and local caching for resource metadata updates
//

import Foundation

/// Manages resource manifest (metadata only) for freshness without requiring DB
@MainActor
final class ResourceManifestManager {
    static let shared = ResourceManifestManager()
    
    struct ResourceManifest: Codable {
        let version: String
        let lastUpdated: Date
        let resources: [ResourceManifestItem]
    }
    
    struct ResourceManifestItem: Codable {
        let id: String
        let title: String?
        let description: String?
        let url: String?
        let category: String?
        let featured: Bool?
        let isOfficial: Bool?
        let lastUpdated: Date?
        let canonicalHash: String?
    }
    
    private let manifestCacheURL: URL
    private let manifestURL: URL? // Optional remote manifest URL
    private var cachedManifest: ResourceManifest?
    
    private init() {
        // Cache location in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        manifestCacheURL = appSupport.appendingPathComponent("resource_manifest.json")
        
        // TODO: Set your CDN/manifest URL here when ready
        // manifestURL = URL(string: "https://your-cdn/ftchub/manifest.json")
        manifestURL = nil
        
        // Load cached manifest on init
        loadCachedManifest()
    }
    
    // MARK: - Manifest Fetching
    
    /// Updates manifest from remote if available, falls back to cache, then bundle
    func updateManifestIfNeeded() async {
        // Try remote fetch first (if URL is configured)
        if let remoteURL = manifestURL {
            if let remoteManifest = await fetchRemoteManifest(from: remoteURL) {
                // Save to cache
                saveManifestToCache(remoteManifest)
                cachedManifest = remoteManifest
                return
            }
        }
        
        // Fallback to cached manifest
        if cachedManifest != nil {
            return
        }
        
        // Final fallback: load from bundle (will be handled by ResourcesService)
    }
    
    private func fetchRemoteManifest(from url: URL) async -> ResourceManifest? {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 10.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success
                break
            case 304:
                // Not modified - use cached version
                return nil
            default:
                // Error status code
                return nil
            }
            
            // Validate data size (manifest should be small)
            guard data.count < 100_000 else { // 100KB limit
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let manifest = try decoder.decode(ResourceManifest.self, from: data)
            
            // Validate manifest structure
            guard !manifest.resources.isEmpty || !manifest.version.isEmpty else {
                return nil
            }
            
            return manifest
        } catch {
            // Silently fail - manifest is optional
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    private func loadCachedManifest() {
        guard FileManager.default.fileExists(atPath: manifestCacheURL.path),
              let data = try? Data(contentsOf: manifestCacheURL) else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        cachedManifest = try? decoder.decode(ResourceManifest.self, from: data)
    }
    
    private func saveManifestToCache(_ manifest: ResourceManifest) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(manifest) else {
            return
        }
        try? data.write(to: manifestCacheURL, options: .atomic)
    }
    
    // MARK: - Manifest Application
    
    /// Applies manifest metadata to resources, updating fields like lastUpdated, featured, etc.
    func applyManifest(to resources: [FTCResource]) -> [FTCResource] {
        guard let manifest = cachedManifest else {
            return resources
        }
        
        var updatedResources = resources
        
        for (index, resource) in updatedResources.enumerated() {
            if let manifestItem = manifest.resources.first(where: { $0.id == resource.id.uuidString }) {
                // Create updated resource with new metadata from manifest
                updatedResources[index] = FTCResource(
                    id: resource.id,
                    title: manifestItem.title ?? resource.title,
                    description: manifestItem.description ?? resource.description,
                    explanation: resource.explanation,
                    url: manifestItem.url ?? resource.url,
                    category: resource.category,
                    icon: resource.icon,
                    subPages: resource.subPages,
                    featured: manifestItem.featured ?? resource.featured,
                    isOfficial: manifestItem.isOfficial ?? resource.isOfficial,
                    lastUpdated: manifestItem.lastUpdated ?? resource.lastUpdated,
                    difficulty: resource.difficulty,
                    estimatedTimeMinutes: resource.estimatedTimeMinutes
                )
            }
        }
        
        return updatedResources
    }
    
    func getManifestLastUpdated() -> Date? {
        return cachedManifest?.lastUpdated
    }
}

