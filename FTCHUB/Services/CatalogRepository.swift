//
//  CatalogRepository.swift
//  FTCHUB
//
//  Remote-first parts catalog with disk caching, ETag support, and version checks.
//

import Foundation

// MARK: - Remote Manifest Schema (v1)

/// Root manifest served at `PARTS_CATALOG_MANIFEST_URL`.
///
/// **Single file:** put every part in `parts`.
///
/// **Mega catalog (recommended for full vendor catalogs):** set `part_chunk_urls` to a list of
/// JSON URLs (absolute, or relative to the manifest file’s directory). Each chunk is either a raw
/// `[PartTemplate]` array or `{"parts":[...]}`. The app downloads the index, then fetches every
/// chunk and merges into one in-memory list (later chunks override the same `id`).
struct CatalogManifest: Codable, Sendable {
    let version: Int
    let generatedAt: String
    let baseImageURL: String?
    let parts: [PartTemplate]
    /// Optional list of URLs to additional JSON part lists (see struct doc).
    let partChunkURLs: [String]?
    
    enum CodingKeys: String, CodingKey {
        case version
        case generatedAt = "generated_at"
        case baseImageURL = "base_image_url"
        case parts
        case partChunkURLs = "part_chunk_urls"
    }
    
    init(
        version: Int,
        generatedAt: String,
        baseImageURL: String?,
        parts: [PartTemplate],
        partChunkURLs: [String]? = nil
    ) {
        self.version = version
        self.generatedAt = generatedAt
        self.baseImageURL = baseImageURL
        self.parts = parts
        self.partChunkURLs = partChunkURLs
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decode(Int.self, forKey: .version)
        generatedAt = try c.decode(String.self, forKey: .generatedAt)
        baseImageURL = try c.decodeIfPresent(String.self, forKey: .baseImageURL)
        parts = try c.decodeIfPresent([PartTemplate].self, forKey: .parts) ?? []
        partChunkURLs = try c.decodeIfPresent([String].self, forKey: .partChunkURLs)
    }
    
    /// Merged catalog for caching and UI (chunk URL list stripped after resolution).
    func mergedCopy(parts: [PartTemplate]) -> CatalogManifest {
        CatalogManifest(
            version: version,
            generatedAt: generatedAt,
            baseImageURL: baseImageURL,
            parts: parts,
            partChunkURLs: nil
        )
    }
}

// MARK: - Cache Metadata

private struct CatalogCacheMetadata: Codable, Sendable {
    let etag: String?
    let lastModified: String?
    let manifestVersion: Int
    let fetchedAt: Date
}

// MARK: - Catalog Repository

actor CatalogRepository {
    static let shared = CatalogRepository()
    
    private let fileManager = FileManager.default
    private let session: URLSession
    
    private var cachedManifest: CatalogManifest?
    private var lastFetchDate: Date?
    
    private let cacheDirectory: URL
    private let manifestCacheFile: URL
    private let metadataCacheFile: URL
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 600
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
        
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.cacheDirectory = appSupport.appendingPathComponent("catalog", isDirectory: true)
        self.manifestCacheFile = cacheDirectory.appendingPathComponent("manifest.json")
        self.metadataCacheFile = cacheDirectory.appendingPathComponent("metadata.json")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Public API
    
    /// Fetches the catalog manifest, using cache when fresh or network unavailable.
    /// - Parameters:
    ///   - manifestURL: The URL to the remote manifest (pass from Config on main actor).
    ///   - forceRefresh: If true, bypasses freshness checks and re-downloads.
    /// - Returns: The catalog manifest with all parts.
    func fetchManifest(manifestURL: URL?, forceRefresh: Bool = false) async throws -> CatalogManifest {
        if !forceRefresh, let cached = cachedManifest, isCacheFresh() {
            return cached
        }
        
        guard let manifestURL = manifestURL else {
            return try loadCachedManifestOrThrow()
        }
        
        do {
            let (manifest, metadata) = try await downloadManifest(from: manifestURL)
            cachedManifest = manifest
            lastFetchDate = Date()
            try persistToCache(manifest: manifest, metadata: metadata)
            return manifest
        } catch {
            if let cached = try? loadCachedManifest() {
                cachedManifest = cached
                return cached
            }
            throw error
        }
    }
    
    /// Returns the resolved image URL for a part, handling relative paths.
    /// - Parameters:
    ///   - part: The part template.
    ///   - manifest: Optional manifest for base URL.
    ///   - baseImageURL: Fallback base URL if manifest doesn't specify one.
    func resolvedImageURL(for part: PartTemplate, manifest: CatalogManifest? = nil, baseImageURL: String? = nil) -> URL? {
        guard let imagePath = part.imageURL, !imagePath.isEmpty else { return nil }
        
        if imagePath.hasPrefix("http://") || imagePath.hasPrefix("https://") {
            return URL(string: imagePath)
        }
        
        let base = manifest?.baseImageURL ?? baseImageURL
        guard let base = base, !base.isEmpty else { return nil }
        
        let cleanBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        let cleanPath = imagePath.hasPrefix("/") ? String(imagePath.dropFirst()) : imagePath
        return URL(string: "\(cleanBase)/\(cleanPath)")
    }
    
    /// Clears all cached catalog data.
    func clearCache() throws {
        cachedManifest = nil
        lastFetchDate = nil
        try? fileManager.removeItem(at: manifestCacheFile)
        try? fileManager.removeItem(at: metadataCacheFile)
    }
    
    /// Returns the last known manifest version without fetching.
    func cachedManifestVersion() -> Int? {
        if let cached = cachedManifest {
            return cached.version
        }
        guard let metadata = loadCachedMetadata() else { return nil }
        return metadata.manifestVersion
    }
    
    // MARK: - Private: Network
    
    private func downloadManifest(from url: URL) async throws -> (CatalogManifest, CatalogCacheMetadata) {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let metadata = loadCachedMetadata() {
            if let etag = metadata.etag {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            if let lastModified = metadata.lastModified {
                request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
            }
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CatalogError.invalidResponse
        }
        
        if httpResponse.statusCode == 304 {
            return try (loadCachedManifestOrThrow(), loadCachedMetadata()!)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw CatalogError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let indexManifest = try JSONDecoder().decode(CatalogManifest.self, from: data)
        let mergedManifest = try await mergeChunkedManifest(index: indexManifest, manifestURL: url)
        
        let newMetadata = CatalogCacheMetadata(
            etag: httpResponse.value(forHTTPHeaderField: "ETag"),
            lastModified: httpResponse.value(forHTTPHeaderField: "Last-Modified"),
            manifestVersion: mergedManifest.version,
            fetchedAt: Date()
        )
        
        return (mergedManifest, newMetadata)
    }
    
    /// Resolves optional `part_chunk_urls` and returns a single manifest with all parts merged.
    private func mergeChunkedManifest(index: CatalogManifest, manifestURL: URL) async throws -> CatalogManifest {
        guard let chunkPaths = index.partChunkURLs, !chunkPaths.isEmpty else {
            return index.mergedCopy(parts: index.parts)
        }
        
        let resolvedChunkURLs: [URL] = chunkPaths.compactMap { resolveChunkURL($0, manifestURL: manifestURL) }
        guard resolvedChunkURLs.count == chunkPaths.count else {
            throw CatalogError.invalidChunkURL
        }
        
        var byId: [String: PartTemplate] = [:]
        for p in index.parts {
            byId[p.id] = p
        }
        
        // Download chunks concurrently, then merge in manifest order so later chunks override same `id`.
        var indexedChunks: [(Int, [PartTemplate])] = []
        try await withThrowingTaskGroup(of: (Int, [PartTemplate]).self) { group in
            for (i, chunkURL) in resolvedChunkURLs.enumerated() {
                group.addTask {
                    let parts = try await self.downloadPartsChunk(from: chunkURL)
                    return (i, parts)
                }
            }
            for try await item in group {
                indexedChunks.append(item)
            }
        }
        for (_, chunkParts) in indexedChunks.sorted(by: { $0.0 < $1.0 }) {
            for p in chunkParts {
                byId[p.id] = p
            }
        }
        
        let mergedList = byId.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return index.mergedCopy(parts: mergedList)
    }
    
    private func resolveChunkURL(_ pathOrURL: String, manifestURL: URL) -> URL? {
        let trimmed = pathOrURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        let baseDir = manifestURL.deletingLastPathComponent()
        if trimmed.hasPrefix("/") {
            guard let scheme = manifestURL.scheme, let host = manifestURL.host else { return nil }
            var c = URLComponents()
            c.scheme = scheme
            c.host = host
            c.path = trimmed
            return c.url
        }
        return URL(string: trimmed, relativeTo: baseDir)?.absoluteURL
    }
    
    private func downloadPartsChunk(from url: URL) async throws -> [PartTemplate] {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CatalogError.chunkHTTPError(url: url.absoluteString)
        }
        return try Self.decodePartsChunk(data: data)
    }
    
    private static func decodePartsChunk(data: Data) throws -> [PartTemplate] {
        let decoder = JSONDecoder()
        if let array = try? decoder.decode([PartTemplate].self, from: data) {
            return array
        }
        struct Envelope: Decodable {
            let parts: [PartTemplate]
        }
        return try decoder.decode(Envelope.self, from: data).parts
    }
    
    // MARK: - Private: Caching
    
    private func isCacheFresh() -> Bool {
        guard let fetchDate = lastFetchDate else { return false }
        let staleDuration: TimeInterval = 60 * 60
        return Date().timeIntervalSince(fetchDate) < staleDuration
    }
    
    private func persistToCache(manifest: CatalogManifest, metadata: CatalogCacheMetadata) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let manifestData = try encoder.encode(manifest)
        try manifestData.write(to: manifestCacheFile, options: .atomic)
        
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: metadataCacheFile, options: .atomic)
    }
    
    private func loadCachedManifest() throws -> CatalogManifest {
        let data = try Data(contentsOf: manifestCacheFile)
        return try JSONDecoder().decode(CatalogManifest.self, from: data)
    }
    
    private func loadCachedManifestOrThrow() throws -> CatalogManifest {
        guard fileManager.fileExists(atPath: manifestCacheFile.path) else {
            throw CatalogError.noCachedManifest
        }
        return try loadCachedManifest()
    }
    
    private func loadCachedMetadata() -> CatalogCacheMetadata? {
        guard let data = try? Data(contentsOf: metadataCacheFile) else { return nil }
        return try? JSONDecoder().decode(CatalogCacheMetadata.self, from: data)
    }
}

// MARK: - Errors

enum CatalogError: LocalizedError {
    case noManifestURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noCachedManifest
    case decodingFailed(underlying: Error)
    case invalidChunkURL
    case chunkHTTPError(url: String)
    
    var errorDescription: String? {
        switch self {
        case .noManifestURL:
            return "Parts catalog URL not configured"
        case .invalidResponse:
            return "Invalid response from catalog server"
        case .httpError(let statusCode):
            return "Catalog server returned status \(statusCode)"
        case .noCachedManifest:
            return "No cached catalog available"
        case .decodingFailed(let underlying):
            return "Failed to decode catalog: \(underlying.localizedDescription)"
        case .invalidChunkURL:
            return "Invalid or unresolvable part_chunk_urls entry"
        case .chunkHTTPError(let url):
            return "Failed to download catalog chunk: \(url)"
        }
    }
}
