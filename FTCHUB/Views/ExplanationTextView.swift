//
//  ExplanationTextView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

// Helper view for formatted explanation text
struct ExplanationTextView: View {
    let text: String
    let categoryColor: Color
    
    private var paragraphs: [String] {
        text.components(separatedBy: "\n\n")
    }
    
    private var sections: [ContentSection] {
        var sections: [ContentSection] = []
        var currentSection: ContentSection?
        
        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("**") && trimmed.contains("**") {
                // New section heading
                if let section = currentSection {
                    sections.append(section)
                }
                let heading = trimmed.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespaces)
                currentSection = ContentSection(heading: heading, content: [])
            } else if let section = currentSection {
                // Add content to current section
                var updatedContent = section.content
                updatedContent.append(trimmed)
                currentSection = ContentSection(heading: section.heading, content: updatedContent)
            } else {
                // Content before first section
                if sections.isEmpty {
                    sections.append(ContentSection(heading: nil, content: [trimmed]))
                } else {
                    sections[sections.count - 1].content.append(trimmed)
                }
            }
        }
        
        if let section = currentSection {
            sections.append(section)
        }
        
        return sections.filter { !$0.content.isEmpty || $0.heading != nil }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                if let heading = section.heading {
                    // Skip Key Concepts, Quick Overview, and Key Highlights sections
                    if heading.contains("Key Concepts") || heading.contains("Quick Overview") || heading.contains("Key Highlights") {
                        // Skip these sections - don't render them
                    } else {
                        // Regular section with heading - create a card
                    SectionCard(
                        title: heading,
                        content: section.content,
                        categoryColor: categoryColor,
                        index: index
                    )
                    }
                } else {
                    // Content without heading - enhanced intro section
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(section.content, id: \.self) { content in
                            ContentParagraph(text: content, categoryColor: categoryColor)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        categoryColor.opacity(0.05),
                                        categoryColor.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(categoryColor.opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
    }
}

struct ContentSection {
    let heading: String?
    var content: [String]
}

struct SectionCard: View {
    let title: String
    let content: [String]
    let categoryColor: Color
    let index: Int
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Enhanced Section Header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                Text(title)
                            .font(.system(size: 19, weight: .bold, design: .default))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if content.count > 0 {
                            Text("\(content.count) section\(content.count == 1 ? "" : "s")")
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                
                Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .buttonStyle(.plain)
            
            // Section Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Array(content.enumerated()), id: \.offset) { index, paragraph in
                            VStack(alignment: .leading, spacing: 0) {
                    ContentParagraph(text: paragraph, categoryColor: categoryColor)
                                
                                // Add divider between paragraphs (except last)
                                if index < content.count - 1 {
                                    Divider()
                                        .padding(.top, 20)
                                        .padding(.bottom, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            categoryColor.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: categoryColor.opacity(0.08), radius: 12, x: 0, y: 4)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [
                            categoryColor.opacity(0.3),
                            categoryColor.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

struct ContentParagraph: View {
    let text: String
    let categoryColor: Color
    
    var body: some View {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") {
            // Enhanced bullet point with more spacing
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.25))
                        .frame(width: 8, height: 8)
                        .offset(y: 12)
                }
                
                Text(trimmed.replacingOccurrences(of: "^[•-]\\s*", with: "", options: .regularExpression))
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineSpacing(10)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 4)
            .padding(.vertical, 6)
        } else if trimmed.hasPrefix("Step ") || trimmed.hasPrefix("**Step ") {
            // Step indicator with better spacing
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "number")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(categoryColor)
                }
                .offset(y: 4)
                
                Text(trimmed.replacingOccurrences(of: "\\*\\*", with: "", options: .regularExpression))
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineSpacing(10)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
        } else if !trimmed.isEmpty {
            // Enhanced regular paragraph with better spacing - break into smaller chunks if too long
            let sentences = trimmed.components(separatedBy: ". ").filter { !$0.isEmpty }
            if sentences.count > 3 {
                // Long paragraph - break into smaller chunks
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(sentences, id: \.self) { sentence in
                        Text(sentence + (sentence.hasSuffix(".") ? "" : "."))
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineSpacing(10)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 8)
            } else {
                // Short paragraph - display normally
            Text(trimmed)
                    .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineSpacing(10)
                .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Key Concepts Card (Visual Grid Layout)
struct KeyConceptsCard: View {
    let content: [String]
    let categoryColor: Color
    
    private var concepts: [(title: String, description: String)] {
        content.compactMap { paragraph in
            let trimmed = paragraph.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") {
                // Remove bullet and bold markers
                var clean = trimmed.replacingOccurrences(of: "^[•-]\\s*", with: "", options: .regularExpression)
                clean = clean.replacingOccurrences(of: "\\*\\*", with: "", options: .regularExpression)
                clean = clean.trimmingCharacters(in: .whitespaces)
                
                // Split by colon to separate title and description
                if let colonRange = clean.range(of: ":") {
                    let title = String(clean[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let desc = String(clean[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    return (title: title, description: desc)
                } else if let dashRange = clean.range(of: " - ") {
                    let title = String(clean[..<dashRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    let desc = String(clean[dashRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    return (title: title, description: desc)
                } else {
                    // No separator - use whole text as title
                    return (title: clean, description: "")
                }
            }
            return nil
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(categoryColor)
                }
                
                Text("Key Concepts")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Grid of concept cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(Array(concepts.enumerated()), id: \.offset) { index, concept in
                    ResourceKeyConceptCard(
                        title: concept.title,
                        description: concept.description,
                        categoryColor: categoryColor,
                        index: index
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            categoryColor.opacity(0.08),
                            categoryColor.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: categoryColor.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(categoryColor.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - Individual Key Concept Card (for Resources)
struct ResourceKeyConceptCard: View {
    let title: String
    let description: String
    let categoryColor: Color
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .default))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if !description.isEmpty {
                Text(description)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineSpacing(6)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: categoryColor.opacity(0.08), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(categoryColor.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Quick Overview Card
struct QuickOverviewCard: View {
    let content: [String]
    let categoryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(categoryColor)
                }
                
                Text("Quick Overview")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(content, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineSpacing(10)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            categoryColor.opacity(0.08),
                            categoryColor.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: categoryColor.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(categoryColor.opacity(0.2), lineWidth: 1.5)
        )
    }
}

