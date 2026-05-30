//
//  LearningProgressManager.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 12/21/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LearningProgressManager: ObservableObject {
    static let shared = LearningProgressManager()
    
    @Published var moduleProgress: [UUID: ModuleProgress] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let moduleProgressKey = "learningModuleProgress"
    private let sectionProgressKey = "learningSectionProgress"
    private let contentProgressKey = "learningContentProgress"
    private let quizScoresKey = "learningQuizScores"
    
    private init() {
        loadProgress()
    }
    
    // MARK: - Progress Tracking
    
    func markContentCompleted(_ contentId: UUID, in sectionId: UUID, moduleId: UUID) {
        var progress = getOrCreateModuleProgress(moduleId)
        progress.completedContent.insert(contentId)
        progress.lastAccessed = Date()
        moduleProgress[moduleId] = progress
        saveProgress()
    }
    
    func markSectionCompleted(_ sectionId: UUID, in moduleId: UUID) {
        var progress = getOrCreateModuleProgress(moduleId)
        progress.completedSections.insert(sectionId)
        progress.lastAccessed = Date()
        moduleProgress[moduleId] = progress
        saveProgress()
    }
    
    func markModuleCompleted(_ moduleId: UUID) {
        var progress = getOrCreateModuleProgress(moduleId)
        progress.isCompleted = true
        progress.completedDate = Date()
        progress.lastAccessed = Date()
        moduleProgress[moduleId] = progress
        saveProgress()
    }
    
    func recordQuizScore(_ score: Double, for quizId: UUID, in moduleId: UUID) {
        var progress = getOrCreateModuleProgress(moduleId)
        progress.quizScores[quizId] = score
        progress.lastAccessed = Date()
        moduleProgress[moduleId] = progress
        saveProgress()
    }
    
    func getProgress(for moduleId: UUID) -> ModuleProgress {
        return getOrCreateModuleProgress(moduleId)
    }
    
    func isModuleCompleted(_ moduleId: UUID) -> Bool {
        return getOrCreateModuleProgress(moduleId).isCompleted
    }
    
    func isSectionCompleted(_ sectionId: UUID, in moduleId: UUID) -> Bool {
        return getOrCreateModuleProgress(moduleId).completedSections.contains(sectionId)
    }
    
    func isContentCompleted(_ contentId: UUID, in moduleId: UUID) -> Bool {
        return getOrCreateModuleProgress(moduleId).completedContent.contains(contentId)
    }
    
    func getCompletionPercentage(for module: LearningModule) -> Double {
        let progress = getOrCreateModuleProgress(module.id)
        let totalContent = module.sections.flatMap { $0.content }.count
        let totalSections = module.sections.count
        
        guard totalContent > 0 || totalSections > 0 else { return 0 }
        
        let contentProgress = Double(progress.completedContent.count) / Double(totalContent)
        let sectionProgress = Double(progress.completedSections.count) / Double(totalSections)
        
        return (contentProgress + sectionProgress) / 2.0
    }
    
    func getSectionCompletionPercentage(for section: LearningSection, in module: LearningModule) -> Double {
        let progress = getOrCreateModuleProgress(module.id)
        let totalContent = section.content.count
        guard totalContent > 0 else { return 0 }
        
        let completedCount = section.content.filter { progress.completedContent.contains($0.id) }.count
        return Double(completedCount) / Double(totalContent)
    }
    
    // MARK: - Private Helpers
    
    private func getOrCreateModuleProgress(_ moduleId: UUID) -> ModuleProgress {
        if let existing = moduleProgress[moduleId] {
            return existing
        }
        let new = ModuleProgress(moduleId: moduleId)
        moduleProgress[moduleId] = new
        return new
    }
    
    // MARK: - Persistence
    
    private func saveProgress() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(moduleProgress) {
            userDefaults.set(encoded, forKey: moduleProgressKey)
        }
    }
    
    private func loadProgress() {
        guard let data = userDefaults.data(forKey: moduleProgressKey),
              let decoded = try? JSONDecoder().decode([UUID: ModuleProgress].self, from: data) else {
            return
        }
        moduleProgress = decoded
    }
    
    func resetProgress(for moduleId: UUID) {
        moduleProgress.removeValue(forKey: moduleId)
        saveProgress()
    }
    
    func resetAllProgress() {
        moduleProgress.removeAll()
        saveProgress()
    }
    
    /// Most recently opened module that is not fully completed, for a "continue learning" affordance.
    func resumeCandidate(from catalog: [LearningModule]) -> LearningModule? {
        let candidates = moduleProgress.values.filter { !$0.isCompleted }
        guard let best = candidates.max(by: { $0.lastAccessed < $1.lastAccessed }) else {
            return nil
        }
        return catalog.first { $0.id == best.moduleId }
    }
}

// MARK: - Progress Models

struct ModuleProgress: Codable {
    let moduleId: UUID
    var completedSections: Set<UUID>
    var completedContent: Set<UUID>
    var quizScores: [UUID: Double]
    var isCompleted: Bool
    var completedDate: Date?
    var lastAccessed: Date
    var timeSpent: TimeInterval // in seconds
    
    init(moduleId: UUID) {
        self.moduleId = moduleId
        self.completedSections = []
        self.completedContent = []
        self.quizScores = [:]
        self.isCompleted = false
        self.completedDate = nil
        self.lastAccessed = Date()
        self.timeSpent = 0
    }
}

