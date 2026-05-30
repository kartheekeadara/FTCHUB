//
//  EnhancedSearchView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct EnhancedSearchView: View {
    @Binding var searchText: String
    @State private var searchHistory: [String] = []
    @State private var recentSearches: [String] = []
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                TextField("Search modules, concepts, quizzes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .onSubmit {
                        if !searchText.isEmpty && !recentSearches.contains(searchText) {
                            recentSearches.insert(searchText, at: 0)
                            if recentSearches.count > 10 {
                                recentSearches.removeLast()
                            }
                            saveSearchHistory()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isSearchFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(12)
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            
            // Recent searches
            if searchText.isEmpty && !recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Searches")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Button("Clear") {
                            recentSearches.removeAll()
                            saveSearchHistory()
                        }
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recentSearches, id: \.self) { search in
                                Button(action: {
                                    searchText = search
                                    isSearchFocused = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.fill")
                                            .font(.caption2)
                                        Text(search)
                                            .font(.caption)
                                    }
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(DesignSystem.Colors.cardBackground)
                                    .cornerRadius(DesignSystem.CornerRadius.md)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            loadSearchHistory()
        }
    }
    
    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: "search_history")
        }
    }
    
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "search_history"),
           let history = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = history
        }
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let query: String
    let modules: [LearningModule]
    let onModuleSelected: (LearningModule) -> Void
    
    private var results: SearchResults {
        SearchResults(query: query, modules: modules)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if results.isEmpty {
                    emptyState
                } else {
                    // Modules
                    if !results.modules.isEmpty {
                        resultsSection(title: "Modules", items: results.modules) { module in
                            onModuleSelected(module)
                        }
                    }
                    
                    // Sections
                    if !results.sections.isEmpty {
                        resultsSection(title: "Sections", items: results.sections) { section in
                            // Handle section selection
                        }
                    }
                    
                    // Content
                    if !results.content.isEmpty {
                        resultsSection(title: "Content", items: results.content) { content in
                            // Handle content selection
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text("No results found")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text("Try different keywords or check your spelling")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    @ViewBuilder
    private func resultsSection<T: Identifiable>(title: String, items: [T], action: @escaping (T) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(Array(items.prefix(5)), id: \.id) { item in
                if let module = item as? LearningModule {
                    Button(action: {
                        action(item)
                    }) {
                        HStack {
                            Image(systemName: module.icon)
                                .foregroundColor(module.color)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Text(module.description)
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .padding()
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                }
            }
        }
    }
}

// MARK: - Search Results
struct SearchResults {
    let query: String
    let modules: [LearningModule]
    var sections: [LearningSection] = []
    var content: [LearningContent] = []
    
    init(query: String, modules: [LearningModule]) {
        self.query = query
        let lowerQuery = query.lowercased()
        
        // Search modules
        self.modules = modules.filter { module in
            module.title.lowercased().contains(lowerQuery) ||
            module.description.lowercased().contains(lowerQuery)
        }
        
        // Search sections
        for module in modules {
            for section in module.sections {
                if section.title.lowercased().contains(lowerQuery) {
                    sections.append(section)
                }
            }
        }
        
        // Search content
        for module in modules {
            for section in module.sections {
                for content in section.content {
                    switch content {
                    case .tutorial(let tutorial):
                        if tutorial.title.lowercased().contains(lowerQuery) {
                            self.content.append(content)
                        }
                    case .quiz(let quiz):
                        if quiz.title.lowercased().contains(lowerQuery) {
                            self.content.append(content)
                        }
                    case .conceptCard(let card):
                        if card.title.lowercased().contains(lowerQuery) ||
                           card.summary.lowercased().contains(lowerQuery) {
                            self.content.append(content)
                        }
                    default:
                        break
                    }
                }
            }
        }
    }
    
    var isEmpty: Bool {
        modules.isEmpty && sections.isEmpty && content.isEmpty
    }
}

