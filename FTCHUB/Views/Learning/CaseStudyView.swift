//
//  CaseStudyView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CaseStudyView: View {
    let caseStudy: CaseStudy
    @Environment(\.dismiss) private var dismiss
    
    private var caseStudyColor: Color {
        LearningModule.defaultColor(for: caseStudy.category)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    // Sections
                    ForEach(caseStudy.sections) { section in
                        CaseStudySectionView(section: section, color: caseStudyColor)
                    }
                    
                    // Key Takeaways
                    if !caseStudy.keyTakeaways.isEmpty {
                        keyTakeawaysSection
                    }
                    
                    // Related Concepts
                    if !caseStudy.relatedConcepts.isEmpty {
                        relatedConceptsSection
                    }
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle(caseStudy.title)
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
        VStack(alignment: .leading, spacing: 16) {
            Text(caseStudy.description)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(4)
            
            HStack(spacing: 12) {
                // Category badge
                Text(caseStudy.category.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(caseStudyColor.opacity(0.2))
                    .foregroundColor(caseStudyColor)
                    .cornerRadius(8)
                
                // Difficulty badge
                HStack(spacing: 4) {
                    Image(systemName: caseStudy.difficulty.icon)
                    Text(caseStudy.difficulty.rawValue)
                }
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(caseStudy.difficulty.color.opacity(0.15))
                .foregroundColor(caseStudy.difficulty.color)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    // MARK: - Key Takeaways Section
    private var keyTakeawaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Key Takeaways")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            ForEach(Array(caseStudy.keyTakeaways.enumerated()), id: \.offset) { index, takeaway in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(caseStudyColor)
                        .clipShape(Circle())
                    
                    Text(takeaway)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    // MARK: - Related Concepts Section
    private var relatedConceptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Concepts")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            FlowLayout(spacing: 8) {
                ForEach(caseStudy.relatedConcepts, id: \.self) { concept in
                    Text(concept)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(caseStudyColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(caseStudyColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
}

// MARK: - Case Study Section View
struct CaseStudySectionView: View {
    let section: CaseStudySection
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(section.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(section.content)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(4)
            
            // Image (if available)
            if let imageName = section.imageName {
                #if canImport(UIKit)
                if let image = UIImage(named: imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(DesignSystem.Colors.secondaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
                #else
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                #endif
            }
            
            // Code example (if available)
            if let codeExample = section.codeExample {
                CodeBlock(code: codeExample, language: "java")
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
}

// MARK: - Flow Layout (for wrapping tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flowLayout(containerWidth: proposal.width ?? 0, subviews: subviews)
        return CGSize(width: result.bounds.width, height: result.bounds.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flowLayout(containerWidth: bounds.width, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    private func flowLayout(containerWidth: CGFloat, subviews: Subviews) -> (bounds: CGRect, frames: [CGRect]) {
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        let bounds = CGRect(x: 0, y: 0, width: containerWidth, height: currentY + lineHeight)
        return (bounds, frames)
    }
}

