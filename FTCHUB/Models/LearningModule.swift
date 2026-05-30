//
//  LearningModule.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

// MARK: - Learning Module
struct LearningModule: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: ResourceCategory
    let difficulty: DifficultyLevel
    let estimatedTime: Int // minutes
    let icon: String
    let color: Color
    let sections: [LearningSection]
    let externalUrl: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: ResourceCategory,
        difficulty: DifficultyLevel = .beginner,
        estimatedTime: Int = 15,
        icon: String,
        color: Color? = nil,
        sections: [LearningSection] = [],
        externalUrl: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.icon = icon
        self.color = color ?? Self.defaultColor(for: category)
        self.sections = sections
        self.externalUrl = externalUrl
    }
    
    static func defaultColor(for category: ResourceCategory) -> Color {
        switch category {
        case .official: return .blue
        case .rules: return .purple
        case .community: return .green
        case .technical: return .orange
        case .programming: return .indigo
        case .strategy: return .pink
        case .safety: return .red
        case .awards: return .yellow
        case .video: return .red
        case .parts: return .gray
        }
    }
}

// MARK: - Difficulty Level
enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var icon: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Learning Section
struct LearningSection: Identifiable {
    let id: UUID
    let title: String
    let content: [LearningContent]
    let quiz: Quiz?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: [LearningContent] = [],
        quiz: Quiz? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.quiz = quiz
    }
}

// MARK: - Learning Content
enum LearningContent: Identifiable {
    case tutorial(TutorialContent)
    case quiz(Quiz)
    case conceptCard(ConceptCard)
    case codeExample(CodeExample)
    case visualGuide(VisualGuide)
    case knowledgeCheck(KnowledgeCheck)
    
    var id: UUID {
        switch self {
        case .tutorial(let content): return content.id
        case .quiz(let quiz): return quiz.id
        case .conceptCard(let card): return card.id
        case .codeExample(let example): return example.id
        case .visualGuide(let guide): return guide.id
        case .knowledgeCheck(let check): return check.id
        }
    }
}

// MARK: - Tutorial Content
struct TutorialContent: Identifiable {
    let id: UUID
    let title: String
    let steps: [TutorialStep]
    
    init(
        id: UUID = UUID(),
        title: String,
        steps: [TutorialStep] = []
    ) {
        self.id = id
        self.title = title
        self.steps = steps
    }
}

struct TutorialStep: Identifiable {
    let id: UUID
    let title: String
    let content: String
    let imageName: String?
    let codeExample: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        imageName: String? = nil,
        codeExample: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.imageName = imageName
        self.codeExample = codeExample
    }
}

// MARK: - Quiz
struct Quiz: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let questions: [QuizQuestion]
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        questions: [QuizQuestion] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.questions = questions
    }
}

// MARK: - Quiz Question
struct QuizQuestion: Identifiable {
    let id: UUID
    let question: String
    let type: QuestionType
    let options: [String]
    let correctAnswers: Set<Int> // Indices of correct answers
    let explanation: String
    
    init(
        id: UUID = UUID(),
        question: String,
        type: QuestionType,
        options: [String],
        correctAnswers: Set<Int>,
        explanation: String = ""
    ) {
        self.id = id
        self.question = question
        self.type = type
        self.options = options
        self.correctAnswers = correctAnswers
        self.explanation = explanation
    }
}

enum QuestionType {
    case multipleChoice // Single correct answer
    case multipleSelect // Multiple correct answers
    case trueFalse
    case matching // Pairs of items
}

// MARK: - Concept Card
struct ConceptCard: Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let detailedExplanation: String
    let relatedConcepts: [String]
    let visualExample: String? // Image name or description
    
    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        detailedExplanation: String,
        relatedConcepts: [String] = [],
        visualExample: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.detailedExplanation = detailedExplanation
        self.relatedConcepts = relatedConcepts
        self.visualExample = visualExample
    }
}

// MARK: - Code Example
struct CodeExample: Identifiable {
    let id: UUID
    let title: String
    let language: String
    let code: String
    let explanation: String
    let lineExplanations: [Int: String]? // Line number to explanation mapping
    
    init(
        id: UUID = UUID(),
        title: String,
        language: String = "java",
        code: String,
        explanation: String,
        lineExplanations: [Int: String]? = nil
    ) {
        self.id = id
        self.title = title
        self.language = language
        self.code = code
        self.explanation = explanation
        self.lineExplanations = lineExplanations
    }
}

// MARK: - Visual Guide
struct VisualGuide: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: VisualGuideType
    let interactiveElements: [InteractiveElement]
    let imageName: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: VisualGuideType,
        interactiveElements: [InteractiveElement] = [],
        imageName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.interactiveElements = interactiveElements
        self.imageName = imageName
    }
}

enum VisualGuideType {
    case diagram
    case flowchart
    case comparison
    case animation
}

struct InteractiveElement: Identifiable {
    let id: UUID
    let label: String
    let description: String
    let position: CGPoint // Relative position (0.0 to 1.0)
    
    init(
        id: UUID = UUID(),
        label: String,
        description: String,
        position: CGPoint
    ) {
        self.id = id
        self.label = label
        self.description = description
        self.position = position
    }
}

// MARK: - Knowledge Check
struct KnowledgeCheck: Identifiable {
    let id: UUID
    let question: String
    let correctAnswer: String
    let explanation: String
    
    init(
        id: UUID = UUID(),
        question: String,
        correctAnswer: String,
        explanation: String
    ) {
        self.id = id
        self.question = question
        self.correctAnswer = correctAnswer
        self.explanation = explanation
    }
}

