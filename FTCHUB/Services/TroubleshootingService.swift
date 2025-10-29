//
//  TroubleshootingService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine

@MainActor
class TroubleshootingService: ObservableObject {
    static let shared = TroubleshootingService()
    
    @Published var guides: [TroubleshootingGuide] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var categories: [String] {
        Array(Set(guides.map { $0.category })).sorted()
    }
    
    private init() {
        loadGuides()
    }
    
    func loadGuides() {
        guard let url = Bundle.main.url(forResource: "TroubleshootingGuides", withExtension: "json") else {
            errorMessage = "Troubleshooting guides file not found"
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            guides = try decoder.decode([TroubleshootingGuide].self, from: data)
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load troubleshooting guides: \(error)")
        }
    }
    
    func searchGuides(query: String) -> [TroubleshootingGuide] {
        guard !query.isEmpty else { return guides }
        
        return guides.filter { guide in
            guide.title.localizedCaseInsensitiveContains(query) ||
            guide.symptoms.contains(where: { $0.localizedCaseInsensitiveContains(query) }) ||
            guide.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) })
        }
    }
    
    func getGuide(byId id: String) -> TroubleshootingGuide? {
        guides.first(where: { $0.id == id })
    }
}

// MARK: - Models
struct TroubleshootingGuide: Identifiable, Codable {
    let id: String
    let title: String
    let category: String
    let difficulty: Difficulty
    let timeEstimate: String
    let tags: [String]
    let symptoms: [String]
    let causes: [String]
    let solutions: [Solution]
    let prevention: [String]
    let relatedIssues: [String]
}

struct Solution: Codable {
    let step: Int
    let action: String
    let details: String
    let image: String?
}

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

import SwiftUI
extension Color {
    // Already defined in SwiftUI
}

