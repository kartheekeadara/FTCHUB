//
//  ResourceDownloadManager.swift
//  FTCHUB
//
//  Created for Phase 1: Resources Enhancement
//  Manages downloading and storing resources for offline access
//

import Foundation
import Combine

/// Manages downloading resources (PDFs, videos) for offline access
@MainActor
final class ResourceDownloadManager: ObservableObject {
    static let shared = ResourceDownloadManager()
    
    @Published var downloadedResources: [DownloadedResource] = []
    @Published var activeDownloads: [UUID: DownloadProgress] = [:]
    
    struct DownloadedResource: Identifiable, Codable {
        let id: UUID
        let resourceId: UUID
        let fileName: String
        let fileSize: Int64
        let downloadedAt: Date
        let filePath: String
    }
    
    struct DownloadProgress {
        let resourceId: UUID
        var progress: Double
        var totalBytes: Int64?
        var downloadedBytes: Int64
    }
    
    private let downloadsDirectory: URL
    private let indexFileName = "downloads_index.json"
    private var downloadTasks: [UUID: URLSessionDownloadTask] = [:]
    
    private init() {
        // Create downloads directory in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        downloadsDirectory = appSupport.appendingPathComponent("ResourceDownloads", isDirectory: true)
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
        
        // Load existing downloads index
        loadDownloadsIndex()
    }
    
    // MARK: - Download Management
    
    func downloadResource(_ resource: FTCResource, url: URL) async throws {
        let resourceId = resource.id
        
        // Check if already downloaded
        if isDownloaded(resourceId: resourceId) {
            return
        }
        
        // Validate URL
        guard url.scheme != nil, (url.scheme == "http" || url.scheme == "https") else {
            throw DownloadError.invalidURL
        }
        
        // Track progress
        await MainActor.run {
            activeDownloads[resourceId] = DownloadProgress(
                resourceId: resourceId,
                progress: 0.0,
                totalBytes: nil,
                downloadedBytes: 0
            )
        }
        
        // Start download with proper error handling
        let (localURL, response) = try await URLSession.shared.download(from: url)
        
        // Validate response
        if let httpResponse = response as? HTTPURLResponse {
            guard (200...299).contains(httpResponse.statusCode) else {
                throw DownloadError.httpError(statusCode: httpResponse.statusCode)
            }
        }
        
        // Move to downloads directory
        let fileName = url.lastPathComponent.isEmpty ? "resource_\(resourceId.uuidString).pdf" : url.lastPathComponent
        let destinationURL = downloadsDirectory.appendingPathComponent(fileName)
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)
        
        // Move downloaded file
        try FileManager.default.moveItem(at: localURL, to: destinationURL)
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Create downloaded resource record
        let downloadedResource = DownloadedResource(
            id: UUID(),
            resourceId: resourceId,
            fileName: fileName,
            fileSize: fileSize,
            downloadedAt: Date(),
            filePath: destinationURL.path
        )
        
        // Add to list
        await MainActor.run {
            downloadedResources.append(downloadedResource)
            // Remove from active downloads
            activeDownloads.removeValue(forKey: resourceId)
            downloadTasks.removeValue(forKey: resourceId)
            // Save index
            saveDownloadsIndex()
        }
    }
    
    enum DownloadError: LocalizedError {
        case invalidURL
        case httpError(statusCode: Int)
        case fileSystemError
        case networkError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid download URL"
            case .httpError(let code):
                return "Download failed with error code \(code)"
            case .fileSystemError:
                return "Failed to save file"
            case .networkError:
                return "Network error occurred"
            }
        }
    }
    
    func isDownloaded(resourceId: UUID) -> Bool {
        return downloadedResources.contains { $0.resourceId == resourceId }
    }
    
    func getDownloadedFileURL(for resourceId: UUID) -> URL? {
        guard let downloaded = downloadedResources.first(where: { $0.resourceId == resourceId }) else {
            return nil
        }
        return URL(fileURLWithPath: downloaded.filePath)
    }
    
    func deleteDownload(resourceId: UUID) {
        guard let downloaded = downloadedResources.first(where: { $0.resourceId == resourceId }) else {
            return
        }
        
        // Delete file
        try? FileManager.default.removeItem(atPath: downloaded.filePath)
        
        // Remove from list
        downloadedResources.removeAll { $0.resourceId == resourceId }
        
        // Cancel download if in progress
        downloadTasks[resourceId]?.cancel()
        downloadTasks.removeValue(forKey: resourceId)
        activeDownloads.removeValue(forKey: resourceId)
        
        // Save index
        saveDownloadsIndex()
    }
    
    func getTotalStorageUsed() -> Int64 {
        return downloadedResources.reduce(0) { $0 + $1.fileSize }
    }
    
    // MARK: - Index Management
    
    private func loadDownloadsIndex() {
        let indexURL = downloadsDirectory.appendingPathComponent(indexFileName)
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([DownloadedResource].self, from: data) else {
            return
        }
        
        // Verify files still exist
        downloadedResources = decoded.filter { FileManager.default.fileExists(atPath: $0.filePath) }
        
        // If any files are missing, save updated index
        if downloadedResources.count != decoded.count {
            saveDownloadsIndex()
        }
    }
    
    private func saveDownloadsIndex() {
        let indexURL = downloadsDirectory.appendingPathComponent(indexFileName)
        guard let encoded = try? JSONEncoder().encode(downloadedResources) else {
            return
        }
        try? encoded.write(to: indexURL, options: .atomic)
    }
    
    // MARK: - Cleanup
    
    func cleanupOldDownloads(keepCount: Int = 10) {
        // Keep most recent downloads, remove oldest
        let sorted = downloadedResources.sorted { $0.downloadedAt > $1.downloadedAt }
        let toRemove = Array(sorted.suffix(from: keepCount))
        
        for downloaded in toRemove {
            deleteDownload(resourceId: downloaded.resourceId)
        }
    }
}

