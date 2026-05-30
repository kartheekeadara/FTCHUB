//
//  AchievementManager.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import Foundation
import Combine

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published private(set) var unlockedAchievements: Set<UUID> = []
    @Published private(set) var achievementStats: AchievementStats = AchievementStats()
    
    private let unlockedAchievementsKey = "unlocked_achievements"
    private let achievementStatsKey = "achievement_stats"
    
    private init() {
        loadAchievements()
    }
    
    // MARK: - Achievement Checking
    func isUnlocked(_ achievementId: UUID) -> Bool {
        unlockedAchievements.contains(achievementId)
    }
    
    func checkAchievements() {
        let allAchievements = AchievementData.allAchievements
        var newlyUnlocked: [Achievement] = []
        
        for achievement in allAchievements {
            if !isUnlocked(achievement.id) && checkRequirement(achievement.requirement) {
                unlockAchievement(achievement.id)
                newlyUnlocked.append(achievement)
            }
        }
        
        if !newlyUnlocked.isEmpty {
            // Notify about new achievements (could trigger celebration UI)
            NotificationCenter.default.post(
                name: .achievementsUnlocked,
                object: newlyUnlocked
            )
        }
    }
    
    // MARK: - Requirement Checking
    private func checkRequirement(_ requirement: AchievementRequirement) -> Bool {
        switch requirement {
        case .completeQuiz(let quizId, let perfectScore):
            if perfectScore {
                return achievementStats.perfectQuizScores.contains(quizId)
            }
            return achievementStats.completedQuizzes.contains(quizId)
            
        case .completeModule(let moduleId):
            return achievementStats.completedModules.contains(moduleId)
            
        case .completeTutorial(let tutorialId):
            return achievementStats.completedTutorials.contains(tutorialId)
            
        case .bookmarkCount(let count):
            return achievementStats.bookmarkCount >= count
            
        case .quizCount(let count):
            return achievementStats.completedQuizzes.count >= count
            
        case .moduleCount(let count):
            return achievementStats.completedModules.count >= count
            
        case .perfectQuizScore(let quizId):
            return achievementStats.perfectQuizScores.contains(quizId)
            
        case .viewAllModules:
            // This would need to track viewed modules
            return false // Placeholder
            
        case .completeAllQuizzes:
            // This would need to know total quiz count
            return false // Placeholder
        }
    }
    
    // MARK: - Achievement Actions
    func unlockAchievement(_ achievementId: UUID) {
        unlockedAchievements.insert(achievementId)
        saveAchievements()
    }
    
    // MARK: - Stats Updates
    func recordQuizCompletion(quizId: UUID, score: Int, totalQuestions: Int) {
        achievementStats.completedQuizzes.insert(quizId)
        
        if score == totalQuestions {
            achievementStats.perfectQuizScores.insert(quizId)
        }
        
        saveStats()
        checkAchievements()
    }
    
    func recordModuleCompletion(moduleId: UUID) {
        achievementStats.completedModules.insert(moduleId)
        saveStats()
        checkAchievements()
    }
    
    func recordTutorialCompletion(tutorialId: UUID) {
        achievementStats.completedTutorials.insert(tutorialId)
        saveStats()
        checkAchievements()
    }
    
    func updateBookmarkCount(_ count: Int) {
        achievementStats.bookmarkCount = count
        saveStats()
        checkAchievements()
    }
    
    // MARK: - Persistence
    private func loadAchievements() {
        // Load unlocked achievements
        if let data = UserDefaults.standard.data(forKey: unlockedAchievementsKey),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            unlockedAchievements = Set(ids.compactMap { UUID(uuidString: $0) })
        }
        
        // Load stats
        if let data = UserDefaults.standard.data(forKey: achievementStatsKey),
           let stats = try? JSONDecoder().decode(AchievementStats.self, from: data) {
            achievementStats = stats
        }
    }
    
    private func saveAchievements() {
        let ids = Array(unlockedAchievements).map { $0.uuidString }
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: unlockedAchievementsKey)
        }
    }
    
    private func saveStats() {
        if let data = try? JSONEncoder().encode(achievementStats) {
            UserDefaults.standard.set(data, forKey: achievementStatsKey)
        }
    }
}

// MARK: - Achievement Stats
struct AchievementStats: Codable {
    var completedQuizzes: Set<UUID> = []
    var completedModules: Set<UUID> = []
    var completedTutorials: Set<UUID> = []
    var perfectQuizScores: Set<UUID> = []
    var bookmarkCount: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case completedQuizzes
        case completedModules
        case completedTutorials
        case perfectQuizScores
        case bookmarkCount
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let quizStrings = try container.decode([String].self, forKey: .completedQuizzes)
        completedQuizzes = Set(quizStrings.compactMap { UUID(uuidString: $0) })
        
        let moduleStrings = try container.decode([String].self, forKey: .completedModules)
        completedModules = Set(moduleStrings.compactMap { UUID(uuidString: $0) })
        
        let tutorialStrings = try container.decode([String].self, forKey: .completedTutorials)
        completedTutorials = Set(tutorialStrings.compactMap { UUID(uuidString: $0) })
        
        let perfectStrings = try container.decode([String].self, forKey: .perfectQuizScores)
        perfectQuizScores = Set(perfectStrings.compactMap { UUID(uuidString: $0) })
        
        bookmarkCount = try container.decode(Int.self, forKey: .bookmarkCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Array(completedQuizzes).map { $0.uuidString }, forKey: .completedQuizzes)
        try container.encode(Array(completedModules).map { $0.uuidString }, forKey: .completedModules)
        try container.encode(Array(completedTutorials).map { $0.uuidString }, forKey: .completedTutorials)
        try container.encode(Array(perfectQuizScores).map { $0.uuidString }, forKey: .perfectQuizScores)
        try container.encode(bookmarkCount, forKey: .bookmarkCount)
    }
}

// MARK: - Notification
extension Notification.Name {
    static let achievementsUnlocked = Notification.Name("achievementsUnlocked")
}

