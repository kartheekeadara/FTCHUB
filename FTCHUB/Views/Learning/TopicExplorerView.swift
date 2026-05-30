//
//  TopicExplorerView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct TopicExplorerView: View {
    let modules: [LearningModule]
    @State private var selectedTopic: TopicNode?
    
    private var topicTree: TopicTree {
        TopicTree(modules: modules)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Explore Topics")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Visualize relationships between topics and discover new learning paths")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                // Topic visualization
                topicVisualization
                
                // Related topics
                if let selected = selectedTopic {
                    relatedTopicsSection(selected)
                }
            }
            .padding()
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Topic Explorer")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Topic Visualization
    private var topicVisualization: some View {
        VStack(spacing: 16) {
            // Main topics (categories)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(topicTree.rootNodes) { node in
                    TopicNodeCard(
                        node: node,
                        isSelected: selectedTopic?.id == node.id,
                        onSelect: {
                            selectedTopic = selectedTopic?.id == node.id ? nil : node
                        }
                    )
                }
            }
            
            // Subtopics (if a topic is selected)
            if let selected = selectedTopic, !selected.children.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Related Topics")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(selected.children) { child in
                                TopicNodeCard(
                                    node: child,
                                    isSelected: false,
                                    onSelect: {
                                        selectedTopic = child
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Related Topics Section
    private func relatedTopicsSection(_ topic: TopicNode) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About \(topic.title)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let module = topic.module {
                NavigationLink(destination: LearningModuleView(module: module)) {
                    LearningModuleCard(module: module)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
}

// MARK: - Topic Tree
struct TopicTree {
    let rootNodes: [TopicNode]
    
    init(modules: [LearningModule]) {
        // Group modules by category
        var categoryNodes: [ResourceCategory: [LearningModule]] = [:]
        for module in modules {
            if categoryNodes[module.category] == nil {
                categoryNodes[module.category] = []
            }
            categoryNodes[module.category]?.append(module)
        }
        
        // Create topic nodes
        rootNodes = categoryNodes.map { category, modules in
            TopicNode(
                id: UUID(),
                title: category.displayName,
                description: "\(modules.count) modules",
                category: category,
                children: modules.map { module in
                    TopicNode(
                        id: module.id,
                        title: module.title,
                        description: module.description,
                        category: category,
                        module: module,
                        children: []
                    )
                }
            )
        }
    }
}

// MARK: - Topic Node
struct TopicNode: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: ResourceCategory
    var module: LearningModule?
    var children: [TopicNode]
}

// MARK: - Topic Node Card
struct TopicNodeCard: View {
    let node: TopicNode
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var nodeColor: Color {
        LearningModule.defaultColor(for: node.category)
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(nodeColor.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: categoryIcon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(nodeColor)
                }
                
                // Title
                Text(node.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Description
                Text(node.description)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Children count
                if !node.children.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.branch")
                            .font(.caption2)
                        Text("\(node.children.count)")
                            .font(.caption2)
                    }
                    .foregroundColor(nodeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(nodeColor.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(
                        isSelected ? nodeColor : DesignSystem.Colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var categoryIcon: String {
        switch node.category {
        case .technical: return "gearshape.2.fill"
        case .programming: return "laptopcomputer"
        case .strategy: return "brain.head.profile"
        case .parts: return "wrench.and.screwdriver.fill"
        case .safety: return "shield.fill"
        default: return "book.fill"
        }
    }
}

