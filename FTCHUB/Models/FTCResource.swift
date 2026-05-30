//
//  FTCResource.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI
#if canImport(SafariServices)
import SafariServices
#endif

struct FTCResource: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let explanation: String?
    let url: String
    let category: ResourceCategory
    let icon: String
    let subPages: [ResourceSubPage]?
    let featured: Bool?
    let isOfficial: Bool?
    let lastUpdated: Date?
    let difficulty: ResourceDifficulty?
    let estimatedTimeMinutes: Int?
    
    init(id: UUID = UUID(), title: String, description: String, explanation: String? = nil, url: String, category: ResourceCategory, icon: String, subPages: [ResourceSubPage]? = nil, featured: Bool? = nil, isOfficial: Bool? = nil, lastUpdated: Date? = nil, difficulty: ResourceDifficulty? = nil, estimatedTimeMinutes: Int? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.explanation = explanation
        self.url = url
        self.category = category
        self.icon = icon
        self.subPages = subPages
        self.featured = featured
        self.isOfficial = isOfficial
        self.lastUpdated = lastUpdated
        self.difficulty = difficulty
        self.estimatedTimeMinutes = estimatedTimeMinutes
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, explanation, url, category, icon, subPages
        case featured, isOfficial, lastUpdated, difficulty, estimatedTimeMinutes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        url = try container.decode(String.self, forKey: .url)
        let categoryString = try container.decode(String.self, forKey: .category)
        category = ResourceCategory.from(string: categoryString)
        icon = try container.decode(String.self, forKey: .icon)
        subPages = try container.decodeIfPresent([ResourceSubPage].self, forKey: .subPages)
        featured = try container.decodeIfPresent(Bool.self, forKey: .featured)
        isOfficial = try container.decodeIfPresent(Bool.self, forKey: .isOfficial)
        
        // Decode lastUpdated as ISO8601 string
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .lastUpdated) {
            let formatter = ISO8601DateFormatter()
            lastUpdated = formatter.date(from: dateString)
        } else {
            lastUpdated = nil
        }
        
        if let difficultyString = try? container.decodeIfPresent(String.self, forKey: .difficulty) {
            difficulty = ResourceDifficulty.from(string: difficultyString)
        } else {
            difficulty = nil
        }
        
        estimatedTimeMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedTimeMinutes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(explanation, forKey: .explanation)
        try container.encode(url, forKey: .url)
        try container.encode(category.stringValue, forKey: .category)
        try container.encode(icon, forKey: .icon)
        try container.encodeIfPresent(subPages, forKey: .subPages)
        try container.encodeIfPresent(featured, forKey: .featured)
        try container.encodeIfPresent(isOfficial, forKey: .isOfficial)
        if let lastUpdated = lastUpdated {
            let formatter = ISO8601DateFormatter()
            try container.encode(formatter.string(from: lastUpdated), forKey: .lastUpdated)
        }
        try container.encodeIfPresent(difficulty?.stringValue, forKey: .difficulty)
        try container.encodeIfPresent(estimatedTimeMinutes, forKey: .estimatedTimeMinutes)
    }
    
    static func == (lhs: FTCResource, rhs: FTCResource) -> Bool {
        lhs.id == rhs.id
    }
}

enum ResourceDifficulty: String, Codable {
    case beginner
    case intermediate
    case advanced
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var stringValue: String {
        return rawValue
    }
    
    static func from(string: String) -> ResourceDifficulty {
        return ResourceDifficulty(rawValue: string.lowercased()) ?? .beginner
    }
}

struct ResourceSubPage: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let url: String
    let description: String
    
    init(title: String, url: String, description: String, id: UUID = UUID()) {
        self.id = id
        self.title = title
        self.url = url
        self.description = description
    }
    
    enum CodingKeys: String, CodingKey {
        case title, url, description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        title = try container.decode(String.self, forKey: .title)
        url = try container.decode(String.self, forKey: .url)
        description = try container.decode(String.self, forKey: .description)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(url, forKey: .url)
        try container.encode(description, forKey: .description)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ResourceSubPage, rhs: ResourceSubPage) -> Bool {
        lhs.id == rhs.id
    }
}

enum ResourceCategory: Codable, CaseIterable {
    case official
    case rules
    case community
    case technical
    case programming
    case strategy
    case safety
    case awards
    case video
    case parts
    
    var displayName: String {
        switch self {
        case .official: return "Official"
        case .rules: return "Rules"
        case .community: return "Community"
        case .technical: return "Technical"
        case .programming: return "Programming"
        case .strategy: return "Strategy"
        case .safety: return "Safety"
        case .awards: return "Awards"
        case .video: return "Video"
        case .parts: return "Parts"
        }
    }
    
    var stringValue: String {
        switch self {
        case .official: return "official"
        case .rules: return "rules"
        case .community: return "community"
        case .technical: return "technical"
        case .programming: return "programming"
        case .strategy: return "strategy"
        case .safety: return "safety"
        case .awards: return "awards"
        case .video: return "video"
        case .parts: return "parts"
        }
    }
    
    static func from(string: String) -> ResourceCategory {
        switch string.lowercased() {
        case "official": return .official
        case "rules": return .rules
        case "community": return .community
        case "technical": return .technical
        case "programming": return .programming
        case "strategy": return .strategy
        case "safety": return .safety
        case "awards": return .awards
        case "video": return .video
        case "parts": return .parts
        default: return .community
        }
    }
}

struct ResourceCard: View {
    let resource: FTCResource
    let action: () -> Void
    
    private var categoryColor: Color {
        switch resource.category {
        case .official: return .blue
        case .rules: return .purple
        case .community: return .green
        case .technical: return .orange
        case .programming: return .indigo
        case .strategy: return .pink
        case .safety: return .red
        case .awards: return .yellow
        case .video: return .red
        case .parts: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: resource.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(categoryColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Category badge
                Text(resource.category.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.2))
                    .foregroundColor(categoryColor)
                    .cornerRadius(6)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#if canImport(SafariServices)
struct ResourceBrowserView: View {
    let resource: FTCResource
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            SafariView(url: URL(string: resource.url)!)
                .navigationTitle(resource.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        // Remove deprecated property
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

