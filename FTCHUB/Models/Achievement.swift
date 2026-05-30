//
//  Achievement.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let color: AchievementColor
    let category: AchievementCategory
    let requirement: AchievementRequirement
    let unlockedAt: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        color: AchievementColor,
        category: AchievementCategory,
        requirement: AchievementRequirement,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.category = category
        self.requirement = requirement
        self.unlockedAt = unlockedAt
    }
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
}

// MARK: - Achievement Color
enum AchievementColor: String, Codable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"
    case rainbow = "Rainbow"
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 0.98)
        case .rainbow: return .purple
        }
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String, Codable {
    case quiz = "Quiz Master"
    case learning = "Learner"
    case explorer = "Explorer"
    case speed = "Speed Demon"
    case perfectionist = "Perfectionist"
    case dedication = "Dedication"
    
    var icon: String {
        switch self {
        case .quiz: return "questionmark.circle.fill"
        case .learning: return "book.fill"
        case .explorer: return "map.fill"
        case .speed: return "bolt.fill"
        case .perfectionist: return "star.fill"
        case .dedication: return "flame.fill"
        }
    }
}

// MARK: - Achievement Requirement
enum AchievementRequirement: Codable {
    case completeQuiz(quizId: UUID, perfectScore: Bool)
    case completeModule(moduleId: UUID)
    case completeTutorial(tutorialId: UUID)
    case bookmarkCount(count: Int)
    case quizCount(count: Int)
    case moduleCount(count: Int)
    case perfectQuizScore(quizId: UUID)
    case viewAllModules
    case completeAllQuizzes
}

// MARK: - Achievement Data
struct AchievementData {
    static let allAchievements: [Achievement] = [
        // Quiz Achievements
        Achievement(
            title: "First Quiz",
            description: "Complete your first quiz",
            icon: "1.circle.fill",
            color: .bronze,
            category: .quiz,
            requirement: .quizCount(count: 1)
        ),
        Achievement(
            title: "Quiz Master",
            description: "Complete 10 quizzes",
            icon: "questionmark.circle.fill",
            color: .silver,
            category: .quiz,
            requirement: .quizCount(count: 10)
        ),
        Achievement(
            title: "Perfect Score",
            description: "Get 100% on any quiz",
            icon: "star.fill",
            color: .gold,
            category: .perfectionist,
            requirement: .completeQuiz(quizId: UUID(), perfectScore: true)
        ),
        Achievement(
            title: "Quiz Champion",
            description: "Complete 25 quizzes",
            icon: "trophy.fill",
            color: .platinum,
            category: .quiz,
            requirement: .quizCount(count: 25)
        ),
        
        // Learning Achievements
        Achievement(
            title: "First Steps",
            description: "Complete your first tutorial",
            icon: "figure.walk",
            color: .bronze,
            category: .learning,
            requirement: .completeTutorial(tutorialId: UUID())
        ),
        Achievement(
            title: "Knowledge Seeker",
            description: "Complete 5 modules",
            icon: "book.fill",
            color: .silver,
            category: .learning,
            requirement: .moduleCount(count: 5)
        ),
        Achievement(
            title: "Master Learner",
            description: "Complete 15 modules",
            icon: "graduationcap.fill",
            color: .gold,
            category: .learning,
            requirement: .moduleCount(count: 15)
        ),
        
        // Explorer Achievements
        Achievement(
            title: "Bookmark Collector",
            description: "Bookmark 10 items",
            icon: "bookmark.fill",
            color: .bronze,
            category: .explorer,
            requirement: .bookmarkCount(count: 10)
        ),
        Achievement(
            title: "Explorer",
            description: "View all available modules",
            icon: "map.fill",
            color: .silver,
            category: .explorer,
            requirement: .viewAllModules
        ),
        
        // Perfectionist Achievements
        Achievement(
            title: "Flawless",
            description: "Get perfect scores on 5 quizzes",
            icon: "checkmark.seal.fill",
            color: .gold,
            category: .perfectionist,
            requirement: .completeAllQuizzes
        )
    ]
}

