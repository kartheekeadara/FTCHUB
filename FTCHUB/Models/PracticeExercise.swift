//
//  PracticeExercise.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

// MARK: - Practice Exercise
struct PracticeExercise: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: ExerciseType
    let difficulty: DifficultyLevel
    let estimatedTime: Int // minutes
    let content: ExerciseContent
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: ExerciseType,
        difficulty: DifficultyLevel = .beginner,
        estimatedTime: Int = 10,
        content: ExerciseContent
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.content = content
    }
}

enum ExerciseType {
    case dragAndDrop
    case codeCompletion
    case designDecision
    case troubleshooting
    case configuration
    case matching
}

enum ExerciseContent {
    case dragAndDrop(DragAndDropExercise)
    case codeCompletion(CodeCompletionExercise)
    case designDecision(DesignDecisionExercise)
    case troubleshooting(TroubleshootingExercise)
    case configuration(ConfigurationExercise)
    case matching(MatchingExercise)
}

// MARK: - Drag and Drop Exercise
struct DragAndDropExercise {
    let instructions: String
    let items: [DraggableItem]
    let targets: [DropTarget]
    let correctMapping: [UUID: UUID] // itemId -> targetId
    
    struct DraggableItem: Identifiable {
        let id: UUID
        let label: String
        let icon: String
    }
    
    struct DropTarget: Identifiable {
        let id: UUID
        let label: String
        let description: String
    }
}

// MARK: - Code Completion Exercise
struct CodeCompletionExercise {
    let instructions: String
    let codeTemplate: String
    let blanks: [CodeBlank]
    let options: [String: [String]] // blankId -> options
    let correctAnswers: [String: String] // blankId -> correct option
    
    struct CodeBlank: Identifiable {
        let id: UUID
        let placeholder: String
        let lineNumber: Int
    }
}

// MARK: - Design Decision Exercise
struct DesignDecisionExercise {
    let scenario: String
    let question: String
    let options: [DesignOption]
    let correctAnswer: UUID
    let explanation: String
    
    struct DesignOption: Identifiable {
        let id: UUID
        let title: String
        let description: String
        let pros: [String]
        let cons: [String]
    }
}

// MARK: - Troubleshooting Exercise
struct TroubleshootingExercise {
    let problem: String
    let symptoms: [String]
    let steps: [TroubleshootingStep]
    let correctPath: [UUID] // sequence of step IDs
    
    struct TroubleshootingStep: Identifiable {
        let id: UUID
        let question: String
        let options: [String]
        let nextStepIds: [String: UUID] // option -> next step ID
        let isSolution: Bool
        let solution: String?
    }
}

// MARK: - Configuration Exercise
struct ConfigurationExercise {
    let instructions: String
    let components: [ConfigurableComponent]
    let constraints: [String]
    let correctConfiguration: [String: String] // componentId -> value
    
    struct ConfigurableComponent: Identifiable {
        let id: UUID
        let name: String
        let type: ComponentType
        let options: [String]
        let description: String
    }
    
    enum ComponentType {
        case motor
        case gearRatio
        case wheelSize
        case sensor
    }
}

// MARK: - Matching Exercise
struct MatchingExercise {
    let instructions: String
    let leftItems: [MatchItem]
    let rightItems: [MatchItem]
    let correctPairs: [UUID: UUID] // leftId -> rightId
    
    struct MatchItem: Identifiable {
        let id: UUID
        let label: String
        let description: String?
    }
}

