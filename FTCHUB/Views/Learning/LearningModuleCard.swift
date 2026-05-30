//
//  LearningModuleCard.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct LearningModuleCard: View {
    let module: LearningModule
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @StateObject private var progressManager = LearningProgressManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            HStack(alignment: .top, spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(module.color.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: module.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(module.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(module.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        // Bookmark button
                        Button(action: {
                            bookmarkManager.toggleModuleBookmark(module.id)
                            DesignSystem.Haptics.selection()
                        }) {
                            Image(systemName: bookmarkManager.isModuleBookmarked(module.id) ? "bookmark.fill" : "bookmark")
                                .font(.subheadline)
                                .foregroundColor(bookmarkManager.isModuleBookmarked(module.id) ? module.color : DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    Text(module.description)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Progress bar
                    let completionPercentage = progressManager.getCompletionPercentage(for: module)
                    if completionPercentage > 0 {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(Int(completionPercentage * 100))% Complete")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(module.color)
                                Spacer()
                                if progressManager.isModuleCompleted(module.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(DesignSystem.Colors.border.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [module.color, module.color.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * completionPercentage, height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(16)
            
            // Section count and metadata
            if !module.sections.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack {
                    HStack(spacing: 12) {
                        Label("\(module.sections.count) \(module.sections.count == 1 ? "section" : "sections")", systemImage: "list.bullet")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Label("\(module.estimatedTime) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        // Difficulty badge
                        HStack(spacing: 4) {
                            Image(systemName: module.difficulty.icon)
                                .font(.caption2)
                            Text(module.difficulty.rawValue)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(module.difficulty.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(module.difficulty.color.opacity(0.15))
                        .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(module.color.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

