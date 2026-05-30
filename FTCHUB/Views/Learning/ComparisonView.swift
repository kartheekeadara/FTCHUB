//
//  ComparisonView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

// MARK: - Comparison
struct Comparison: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let items: [ComparisonItem]
    let category: ResourceCategory
}

struct ComparisonItem: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let attributes: [ComparisonAttribute]
    let pros: [String]
    let cons: [String]
}

struct ComparisonAttribute {
    let name: String
    let value: String
    let isBetter: Bool? // nil = neutral, true = higher is better, false = lower is better
}

struct ComparisonView: View {
    let comparison: Comparison
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAttribute: String?
    
    private var comparisonColor: Color {
        LearningModule.defaultColor(for: comparison.category)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    // Comparison table
                    comparisonTable
                    
                    // Detailed comparison
                    detailedComparison
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle(comparison.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(comparison.description)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(4)
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    // MARK: - Comparison Table
    private var comparisonTable: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("Attribute")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                ForEach(comparison.items) { item in
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(comparisonColor.opacity(0.1))
                }
            }
            .background(DesignSystem.Colors.secondaryBackground)
            
            // Attribute rows
            if let firstItem = comparison.items.first {
                ForEach(firstItem.attributes, id: \.name) { attribute in
                    HStack(spacing: 0) {
                        Text(attribute.name)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        
                        ForEach(comparison.items) { item in
                            if let itemAttribute = item.attributes.first(where: { $0.name == attribute.name }) {
                                ComparisonValueView(
                                    value: itemAttribute.value,
                                    isBetter: itemAttribute.isBetter,
                                    color: comparisonColor
                                )
                            } else {
                                Text("-")
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                    }
                    .background(DesignSystem.Colors.cardBackground)
                    .overlay(
                        Rectangle()
                            .fill(DesignSystem.Colors.border)
                            .frame(height: 1),
                        alignment: .bottom
                    )
                }
            }
        }
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Detailed Comparison
    private var detailedComparison: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Comparison")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(comparison.items) { item in
                ComparisonItemCard(item: item, color: comparisonColor)
            }
        }
    }
}

// MARK: - Comparison Value View
struct ComparisonValueView: View {
    let value: String
    let isBetter: Bool?
    let color: Color
    
    var body: some View {
        HStack {
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let isBetter = isBetter {
                Image(systemName: isBetter ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundColor(isBetter ? .green : .orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Comparison Item Card
struct ComparisonItemCard: View {
    let item: ComparisonItem
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(item.name)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(item.description)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(4)
            
            // Pros
            if !item.pros.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Advantages")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    ForEach(item.pros, id: \.self) { pro in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(pro)
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                    }
                }
            }
            
            // Cons
            if !item.cons.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Disadvantages")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    ForEach(item.cons, id: \.self) { con in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(con)
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

