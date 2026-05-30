//
//  LearningSectionView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct LearningSectionView: View {
    let section: LearningSection
    let moduleColor: Color
    let moduleId: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedContent: LearningContent?
    @State private var showingQuiz = false
    @StateObject private var progressManager = LearningProgressManager.shared
    
    init(section: LearningSection, moduleColor: Color, moduleId: UUID? = nil) {
        self.section = section
        self.moduleColor = moduleColor
        self.moduleId = moduleId
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Section header
                    sectionHeader
                    
                    // Content list
                    contentList
                    
                    // Quiz button (if available)
                    if let quiz = section.quiz {
                        quizButton(quiz: quiz)
                    }
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle(section.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedContent) { content in
                ContentDetailView(
                    content: content,
                    moduleColor: moduleColor,
                    sectionId: section.id,
                    moduleId: moduleId
                )
            }
            .sheet(isPresented: $showingQuiz) {
                if let quiz = section.quiz {
                    QuizView(quiz: quiz, moduleColor: moduleColor)
                }
            }
        }
    }
    
    // MARK: - Section Header
    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if !section.content.isEmpty {
                Text("\(section.content.count) \(section.content.count == 1 ? "item" : "items")")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Content List
    private var contentList: some View {
        VStack(spacing: 16) {
            ForEach(section.content, id: \.id) { content in
                ContentCard(
                    content: content,
                    moduleColor: moduleColor,
                    isCompleted: moduleId != nil ? progressManager.isContentCompleted(content.id, in: moduleId!) : false
                ) {
                    selectedContent = content
                }
            }
        }
    }
    
    // MARK: - Quiz Button
    private func quizButton(quiz: Quiz) -> some View {
        Button(action: {
            showingQuiz = true
            DesignSystem.Haptics.selection()
        }) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Take Quiz")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("\(quiz.questions.count) questions")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [moduleColor, moduleColor.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
    }
}

// MARK: - Content Card
struct ContentCard: View {
    let content: LearningContent
    let moduleColor: Color
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            DesignSystem.Haptics.selection()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(contentColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: contentIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(contentColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(contentTitle)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(contentDescription)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(contentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var contentIcon: String {
        switch content {
        case .tutorial: return "list.number"
        case .quiz: return "questionmark.circle.fill"
        case .conceptCard: return "lightbulb.fill"
        case .codeExample: return "chevron.left.forwardslash.chevron.right"
        case .visualGuide: return "eye.fill"
        case .knowledgeCheck: return "checkmark.circle.fill"
        }
    }
    
    private var contentColor: Color {
        switch content {
        case .tutorial: return moduleColor
        case .quiz: return .blue
        case .conceptCard: return .yellow
        case .codeExample: return .green
        case .visualGuide: return .purple
        case .knowledgeCheck: return .orange
        }
    }
    
    private var contentTitle: String {
        switch content {
        case .tutorial(let tutorial): return tutorial.title
        case .quiz(let quiz): return quiz.title
        case .conceptCard(let card): return card.title
        case .codeExample(let example): return example.title
        case .visualGuide(let guide): return guide.title
        case .knowledgeCheck(let check): return check.question
        }
    }
    
    private var contentDescription: String {
        switch content {
        case .tutorial(let tutorial): return "\(tutorial.steps.count) steps"
        case .quiz(let quiz): return quiz.description.isEmpty ? "\(quiz.questions.count) questions" : quiz.description
        case .conceptCard(let card): return card.summary
        case .codeExample(let example): return example.explanation
        case .visualGuide(let guide): return guide.description
        case .knowledgeCheck: return "Quick knowledge check"
        }
    }
}

// MARK: - Content Detail View
struct ContentDetailView: View {
    let content: LearningContent
    let moduleColor: Color
    let sectionId: UUID?
    let moduleId: UUID?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var progressManager = LearningProgressManager.shared
    
    init(content: LearningContent, moduleColor: Color, sectionId: UUID? = nil, moduleId: UUID? = nil) {
        self.content = content
        self.moduleColor = moduleColor
        self.sectionId = sectionId
        self.moduleId = moduleId
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch content {
                    case .tutorial(let tutorial):
                        InteractiveTutorialView(tutorial: tutorial, moduleColor: moduleColor)
                    case .quiz(let quiz):
                        QuizView(quiz: quiz, moduleColor: moduleColor)
                    case .conceptCard(let card):
                        ConceptCardView(card: card, moduleColor: moduleColor)
                    case .codeExample(let example):
                        CodeExampleView(example: example, moduleColor: moduleColor)
                    case .visualGuide(let guide):
                        VisualGuideView(guide: guide, moduleColor: moduleColor)
                    case .knowledgeCheck(let knowledgeCheck):
                        KnowledgeCheckView(check: knowledgeCheck, moduleColor: moduleColor)
                    }
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Mark content as completed
                        if let sectionId = sectionId, let moduleId = moduleId {
                            progressManager.markContentCompleted(content.id, in: sectionId, moduleId: moduleId)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Update last accessed time
                if let moduleId = moduleId {
                    _ = progressManager.getProgress(for: moduleId)
                }
            }
        }
    }
}

