//
//  PartsLibraryService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine

@MainActor
class PartsLibraryService: ObservableObject {
    static let shared = PartsLibraryService()
    
    // MARK: - Published State
    
    @Published private(set) var allParts: [PartTemplate] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var catalogSource: CatalogSource = .bundledOnly
    @Published private(set) var lastRefreshDate: Date?
    
    enum CatalogSource: Equatable {
        case bundledOnly
        case remoteAndBundled(manifestVersion: Int)
        case cachedRemote(manifestVersion: Int)
    }
    
    // MARK: - Internal Storage
    
    private var bundledParts: [PartTemplate] = []
    private var remoteParts: [PartTemplate] = []
    private var remoteManifest: CatalogManifest?
    
    private init() {
        loadBundledParts()
        Task { await loadRemoteCatalog(forceRefresh: false) }
    }
    
    // MARK: - Public API
    
    /// Refreshes the catalog from network (if configured) and merges with bundled.
    func refreshCatalog() async {
        await loadRemoteCatalog(forceRefresh: true)
    }
    
    /// Returns the resolved image URL for a part, handling relative paths from manifest.
    func resolvedImageURL(for part: PartTemplate) async -> URL? {
        await CatalogRepository.shared.resolvedImageURL(
            for: part,
            manifest: remoteManifest,
            baseImageURL: Config.partsCatalogBaseImageURL
        )
    }
    
    // MARK: - Loading: Bundled
    
    private func loadBundledParts() {
        var parts: [PartTemplate] = []
        if let rev = try? loadJSONResource(named: "REVParts") {
            parts.append(contentsOf: rev)
        }
        if let tetrix = try? loadJSONResource(named: "TETRIXParts") {
            parts.append(contentsOf: tetrix)
        }
        bundledParts = parts
        rebuildAllParts()
    }
    
    private func loadJSONResource(named name: String) throws -> [PartTemplate] {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw PartsError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([PartTemplate].self, from: data)
    }
    
    // MARK: - Loading: Remote
    
    private func loadRemoteCatalog(forceRefresh: Bool) async {
        guard let urlString = Config.partsCatalogManifestURL,
              let manifestURL = URL(string: urlString) else {
            catalogSource = .bundledOnly
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let manifest = try await CatalogRepository.shared.fetchManifest(
                manifestURL: manifestURL,
                forceRefresh: forceRefresh
            )
            remoteManifest = manifest
            remoteParts = manifest.parts
            catalogSource = .remoteAndBundled(manifestVersion: manifest.version)
            lastRefreshDate = Date()
            rebuildAllParts()
        } catch CatalogError.noCachedManifest {
            catalogSource = .bundledOnly
        } catch {
            errorMessage = error.localizedDescription
            if let version = await CatalogRepository.shared.cachedManifestVersion() {
                catalogSource = .cachedRemote(manifestVersion: version)
            } else {
                catalogSource = .bundledOnly
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Merge Logic
    
    private func rebuildAllParts() {
        var merged: [String: PartTemplate] = [:]
        for part in bundledParts {
            merged[part.id] = part
        }
        for part in remoteParts {
            merged[part.id] = part
        }
        allParts = merged.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    // MARK: - Search and Filter
    
    func searchParts(query: String) -> [PartTemplate] {
        guard !query.isEmpty else { return allParts }
        
        let lowercased = query.lowercased()
        return allParts.filter { part in
            part.name.lowercased().contains(lowercased) ||
            part.sku.lowercased().contains(lowercased) ||
            part.category.lowercased().contains(lowercased) ||
            part.manufacturer.lowercased().contains(lowercased) ||
            (part.description?.lowercased().contains(lowercased) ?? false)
        }
    }
    
    func filterByCategory(_ category: String) -> [PartTemplate] {
        allParts.filter { $0.category == category }
    }
    
    func filterByManufacturer(_ manufacturer: String) -> [PartTemplate] {
        allParts.filter { $0.manufacturer == manufacturer }
    }
    
    var categories: [String] {
        Array(Set(allParts.map { $0.category })).sorted()
    }
    
    var manufacturers: [String] {
        Array(Set(allParts.map { $0.manufacturer })).sorted()
    }
    
    var subcategories: [String] {
        Array(Set(allParts.compactMap { $0.subcategory })).sorted()
    }
    
    // MARK: - Conversion to Inventory Item
    
    func createInventoryItem(from template: PartTemplate, teamId: UUID, quantity: Int = 0, location: String? = nil) -> InventoryItem {
        return InventoryItem(
            id: UUID(),
            teamId: teamId,
            sku: template.sku,
            name: template.name,
            manufacturer: template.manufacturer,
            partNumber: template.partNumber,
            category: template.category,
            location: location,
            quantityOnHand: quantity,
            lowStockThreshold: template.lowStockThreshold,
            unitCost: template.unitCost != nil ? Decimal(template.unitCost!) : nil,
            description: template.description,
            imageUrl: template.imageURL,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Bulk Import
    
    func importParts(templates: [PartTemplate], teamId: UUID, defaultQuantity: Int = 0) -> [InventoryItem] {
        return templates.map { template in
            createInventoryItem(from: template, teamId: teamId, quantity: defaultQuantity)
        }
    }
}

// MARK: - Part Template Model
struct PartTemplate: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sku: String
    let name: String
    let manufacturer: String
    let partNumber: String
    let category: String
    let subcategory: String?
    let description: String?
    let unitCost: Double?
    let lowStockThreshold: Int
    let specifications: [String: String]?
    let imageURL: String?
    let productURL: String?
    let compatibleTags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id, sku, name, manufacturer, category, subcategory, description, specifications
        case partNumber = "partNumber"
        case unitCost = "unitCost"
        case lowStockThreshold = "lowStockThreshold"
        case imageURL = "image"
        case productURL = "productURL"
        case compatibleTags = "compatibleTags"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sku = try container.decode(String.self, forKey: .sku)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? sku
        name = try container.decode(String.self, forKey: .name)
        manufacturer = try container.decode(String.self, forKey: .manufacturer)
        partNumber = try container.decode(String.self, forKey: .partNumber)
        category = try container.decode(String.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        unitCost = try container.decodeIfPresent(Double.self, forKey: .unitCost)
        lowStockThreshold = try container.decodeIfPresent(Int.self, forKey: .lowStockThreshold) ?? 1
        specifications = try container.decodeIfPresent([String: String].self, forKey: .specifications)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        productURL = try container.decodeIfPresent(String.self, forKey: .productURL)
        compatibleTags = try container.decodeIfPresent([String].self, forKey: .compatibleTags)
    }
    
    init(
        id: String? = nil,
        sku: String,
        name: String,
        manufacturer: String,
        partNumber: String,
        category: String,
        subcategory: String? = nil,
        description: String? = nil,
        unitCost: Double? = nil,
        lowStockThreshold: Int = 1,
        specifications: [String: String]? = nil,
        imageURL: String? = nil,
        productURL: String? = nil,
        compatibleTags: [String]? = nil
    ) {
        self.id = id ?? sku
        self.sku = sku
        self.name = name
        self.manufacturer = manufacturer
        self.partNumber = partNumber
        self.category = category
        self.subcategory = subcategory
        self.description = description
        self.unitCost = unitCost
        self.lowStockThreshold = lowStockThreshold
        self.specifications = specifications
        self.imageURL = imageURL
        self.productURL = productURL
        self.compatibleTags = compatibleTags
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PartTemplate, rhs: PartTemplate) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Errors
enum PartsError: LocalizedError {
    case fileNotFound
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Parts catalog file not found"
        case .decodingFailed:
            return "Failed to decode parts data"
        }
    }
}

