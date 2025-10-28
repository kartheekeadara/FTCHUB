//
//  RulesReferenceView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct RulesReferenceView: View {
    @State private var searchText = ""
    @State private var selectedCategory = RuleCategory.all
    
    enum RuleCategory: String, CaseIterable {
        case all = "All"
        case game = "Game Rules"
        case robot = "Robot Rules"
        case safety = "Safety"
        case scoring = "Scoring"
        case penalties = "Penalties"
        
        var icon: String {
            switch self {
            case .all: return "book.fill"
            case .game: return "gamecontroller.fill"
            case .robot: return "gear"
            case .safety: return "shield.fill"
            case .scoring: return "target"
            case .penalties: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var filteredRules: [Rule] {
        var rules = sampleRules
        
        if selectedCategory != .all {
            rules = rules.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            rules = rules.filter { rule in
                rule.title.localizedCaseInsensitiveContains(searchText) ||
                rule.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return rules
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(RuleCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Rules List
                if filteredRules.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Spacer()
                        
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("No Rules Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Try adjusting your search or category filter")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    List(filteredRules) { rule in
                        RuleRowView(rule: rule)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Rules Reference")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct Rule: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let category: RulesReferenceView.RuleCategory
    let ruleNumber: String
}

struct RuleRowView: View {
    let rule: Rule
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(rule.ruleNumber)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(4)
                
                Text(rule.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            Text(rule.content)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(3)
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct CategoryButton: View {
    let category: RulesReferenceView.RuleCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.tertiaryBackground)
            .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
            .cornerRadius(DesignSystem.CornerRadius.sm)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search rules...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// Sample data
private let sampleRules: [Rule] = [
    Rule(title: "Robot Size Limits", content: "Robots must fit within an 18\" x 18\" x 18\" cube at the start of the match.", category: .robot, ruleNumber: "RG01"),
    Rule(title: "Autonomous Period", content: "The autonomous period lasts 30 seconds. Robots must be fully autonomous during this time.", category: .game, ruleNumber: "RG02"),
    Rule(title: "Safety Requirements", content: "All robots must have a kill switch that can be activated by the drive team.", category: .safety, ruleNumber: "RG03"),
    Rule(title: "Scoring Objects", content: "Teams score points by placing game pieces in scoring zones. Each piece has different point values.", category: .scoring, ruleNumber: "RG04"),
    Rule(title: "Penalty System", content: "Penalties are assessed for rule violations. Each penalty results in a 10-point deduction.", category: .penalties, ruleNumber: "RG05")
]

#Preview {
    RulesReferenceView()
}