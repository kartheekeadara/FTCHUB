//
//  ExternalDataCache.swift
//  FTCHUB
//
//  Disk cache for external FTC Scout / Orange Alliance data.
//

import Foundation

@MainActor
final class ExternalDataCache {
    static let shared = ExternalDataCache()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let defaultTTL: TimeInterval = 3600

    private init() {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        cacheDirectory = base.appendingPathComponent("ExternalDataCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func save<T: Encodable>(_ value: T, key: String) {
        let url = cacheDirectory.appendingPathComponent(safeFilename(key) + ".json")
        let envelope = CacheEnvelope(savedAt: Date(), payload: AnyEncodable(value))
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, key: String, ttl: TimeInterval? = nil) -> T? {
        let url = cacheDirectory.appendingPathComponent(safeFilename(key) + ".json")
        guard let data = try? Data(contentsOf: url),
              let envelope = try? JSONDecoder().decode(CacheEnvelope.self, from: data) else {
            return nil
        }
        let maxAge = ttl ?? defaultTTL
        guard Date().timeIntervalSince(envelope.savedAt) < maxAge else {
            try? fileManager.removeItem(at: url)
            return nil
        }
        return envelope.payload.decode(as: T.self)
    }

    func clearAll() {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else { return }
        for url in contents { try? fileManager.removeItem(at: url) }
    }

    private func safeFilename(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}

private struct CacheEnvelope: Codable {
    let savedAt: Date
    let payload: AnyEncodable
}

private struct AnyEncodable: Codable {
    private let data: Data

    init<T: Encodable>(_ value: T) {
        self.data = (try? JSONEncoder().encode(value)) ?? Data()
    }

    func decode<T: Decodable>(as type: T.Type) -> T? {
        try? JSONDecoder().decode(T.self, from: data)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.data = try container.decode(Data.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}
