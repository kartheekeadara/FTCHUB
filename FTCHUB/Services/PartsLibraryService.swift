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
    
    @Published var revParts: [PartTemplate] = []
    @Published var tetrixParts: [PartTemplate] = []
    @Published var allParts: [PartTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        loadParts()
    }
    
    // MARK: - Loading Parts
    func loadParts() {
        isLoading = true
        errorMessage = nil
        
        do {
            revParts = try loadREVParts()
            tetrixParts = try loadTETRIXParts()
            allParts = revParts + tetrixParts
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadREVParts() throws -> [PartTemplate] {
        guard let url = Bundle.main.url(forResource: "REVParts", withExtension: "json") else {
            throw PartsError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([PartTemplate].self, from: data)
    }
    
    private func loadTETRIXParts() throws -> [PartTemplate] {
        guard let url = Bundle.main.url(forResource: "TETRIXParts", withExtension: "json") else {
            throw PartsError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([PartTemplate].self, from: data)
    }
    
    // MARK: - Search and Filter
    func searchParts(query: String) -> [PartTemplate] {
        guard !query.isEmpty else { return allParts }
        
        let lowercased = query.lowercased()
        return allParts.filter { part in
            part.name.lowercased().contains(lowercased) ||
            part.sku.lowercased().contains(lowercased) ||
            part.category.lowercased().contains(lowercased) ||
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
            imageUrl: nil,
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
struct PartTemplate: Codable, Identifiable {
    var id: String { sku }
    let sku: String
    let name: String
    let manufacturer: String
    let partNumber: String
    let category: String
    let description: String?
    let unitCost: Double?
    let lowStockThreshold: Int
    let specifications: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case sku, name, manufacturer, category, description, specifications
        case partNumber = "partNumber"
        case unitCost = "unitCost"
        case lowStockThreshold = "lowStockThreshold"
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

