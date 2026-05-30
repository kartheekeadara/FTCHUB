//
//  LearningModuleView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct LearningModuleView: View {
    let module: LearningModule
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @StateObject private var progressManager = LearningProgressManager.shared
    @State private var selectedSection: LearningSection?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Sections
                sectionsList
                
                learningModuleFeedbackSection
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Bookmark button
                Button(action: {
                    bookmarkManager.toggleModuleBookmark(module.id)
                    DesignSystem.Haptics.selection()
                }) {
                    Image(systemName: bookmarkManager.isModuleBookmarked(module.id) ? "bookmark.fill" : "bookmark")
                        .foregroundColor(bookmarkManager.isModuleBookmarked(module.id) ? module.color : DesignSystem.Colors.textSecondary)
                }
            }
        }
        .sheet(item: $selectedSection) { section in
            LearningSectionView(section: section, moduleColor: module.color, moduleId: module.id)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon and title
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(module.color.opacity(0.15))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: module.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(module.color)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(module.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(module.description)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(3)
                    
                    // Progress indicator
                    let completionPercentage = progressManager.getCompletionPercentage(for: module)
                    if completionPercentage > 0 {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(Int(completionPercentage * 100))% Complete")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(module.color)
                                Spacer()
                                if progressManager.isModuleCompleted(module.id) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                        Text("Completed")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(.green)
                                }
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(DesignSystem.Colors.border.opacity(0.2))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: [module.color, module.color.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * completionPercentage, height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            
            // Flashcards button
            NavigationLink(destination: FlashcardDeckListView()) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.stack.fill")
                    Text("Study Flashcards")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .font(.subheadline)
                .foregroundColor(module.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(module.color.opacity(0.1))
                .cornerRadius(8)
            }
            
            // External link (if available)
            if let url = module.externalUrl {
                Link(destination: URL(string: url)!) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square")
                        Text("View External Resource")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(module.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(module.color.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    module.color.opacity(0.05),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var learningModuleFeedbackSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick feedback")
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            HStack(spacing: 12) {
                Button("This module helped") {
                    TelemetryService.shared.logEvent(
                        "learning_module_helpful",
                        parameters: ["moduleId": module.id.uuidString, "vote": "yes"]
                    )
                    DesignSystem.Haptics.notify(.success)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Not yet") {
                    TelemetryService.shared.logEvent(
                        "learning_module_helpful",
                        parameters: ["moduleId": module.id.uuidString, "vote": "not_yet"]
                    )
                    DesignSystem.Haptics.selection()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    // MARK: - Sections List
    private var sectionsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if module.sections.isEmpty {
                emptyStateView
            } else {
                Text("Sections")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                ForEach(module.sections) { section in
                    LearningSectionCard(
                        section: section,
                        moduleColor: module.color,
                        module: module
                    ) {
                        selectedSection = section
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text("No sections available")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Section Card
private struct LearningSectionCard: View {
    let section: LearningSection
    let moduleColor: Color
    let module: LearningModule
    let action: () -> Void
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @StateObject private var progressManager = LearningProgressManager.shared
    
    var body: some View {
        Button(action: {
            DesignSystem.Haptics.selection()
            action()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(section.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Bookmark button
                    Button(action: {
                        bookmarkManager.toggleSectionBookmark(section.id)
                        DesignSystem.Haptics.selection()
                    }) {
                        Image(systemName: bookmarkManager.isSectionBookmarked(section.id) ? "bookmark.fill" : "bookmark")
                            .font(.subheadline)
                            .foregroundColor(bookmarkManager.isSectionBookmarked(section.id) ? moduleColor : DesignSystem.Colors.textSecondary)
                    }
                }
                
                // Progress and arrow
                HStack {
                    // Section progress
                    let sectionProgress = progressManager.getSectionCompletionPercentage(for: section, in: module)
                    if sectionProgress > 0 {
                        HStack(spacing: 6) {
                            if progressManager.isSectionCompleted(section.id, in: module.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            Text("\(Int(sectionProgress * 100))%")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(moduleColor)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(moduleColor)
                }
            }
            .padding(16)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(moduleColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func contentIcon(for content: LearningContent) -> some View {
        let (icon, color) = contentIconInfo(for: content)
        return Image(systemName: icon)
            .font(.caption)
            .foregroundColor(color)
            .padding(6)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
    
    private func contentIconInfo(for content: LearningContent) -> (String, Color) {
        switch content {
        case .tutorial:
            return ("list.number", moduleColor)
        case .quiz:
            return ("questionmark.circle.fill", .blue)
        case .conceptCard:
            return ("lightbulb.fill", .yellow)
        case .codeExample:
            return ("chevron.left.forwardslash.chevron.right", .green)
        case .visualGuide:
            return ("eye.fill", .purple)
        case .knowledgeCheck:
            return ("checkmark.circle.fill", .orange)
        }
    }
}

// MARK: - Notes Sheet
struct NotesSheet: View {
    let moduleId: UUID
    @Binding var noteText: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notesManager = NotesManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Notes")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal)
                    .padding(.top)
                
                TextEditor(text: $noteText)
                    .font(.body)
                    .padding(8)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .padding(.horizontal)
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        notesManager.setNote(noteText, for: moduleId)
                        DesignSystem.Haptics.notify(.success)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

