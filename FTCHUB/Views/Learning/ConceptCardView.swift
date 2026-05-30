//
//  ConceptCardView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ConceptCardView: View {
    let card: ConceptCard
    let moduleColor: Color
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text(card.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            // Summary (always visible)
            Text(card.summary)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(4)
            
            // Expand button
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
                DesignSystem.Haptics.selection()
            }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "Learn More")
                        .fontWeight(.semibold)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.subheadline)
                .foregroundColor(moduleColor)
            }
            
            // Detailed explanation (expandable)
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    Text("Detailed Explanation")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(card.detailedExplanation)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineSpacing(4)
                    
                    // Visual example (if available)
                    if let visualExample = card.visualExample {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Visual Example")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Group {
                                #if canImport(UIKit)
                                if let image = UIImage(named: visualExample) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } else {
                                    Image(systemName: "photo")
                                        .font(.system(size: 48))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                        .background(DesignSystem.Colors.secondaryBackground)
                                }
                                #else
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(DesignSystem.Colors.secondaryBackground)
                                #endif
                            }
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                    }
                    
                    // Related concepts
                    if !card.relatedConcepts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Related Concepts")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            ForEach(card.relatedConcepts, id: \.self) { concept in
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(moduleColor)
                                    Text(concept)
                                        .font(.subheadline)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(moduleColor.opacity(0.2), lineWidth: 1)
        )
    }
}

