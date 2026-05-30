//
//  DecodeScoringViewModel.swift
//  FTCHUB
//
//  Created by GPT-5 Codex on 11/8/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class DecodeScoringViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    enum ArtifactColor: String, CaseIterable, Identifiable {
        case none
        case green
        case purple
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .none:
                return "None"
            case .green:
                return "Green"
            case .purple:
                return "Purple"
            }
        }
        
        var symbol: String {
            switch self {
            case .none:
                return "–"
            case .green:
                return "G"
            case .purple:
                return "P"
            }
        }
        
        var tint: Color {
            switch self {
            case .none:
                return DesignSystem.Colors.textTertiary
            case .green:
                return Color.green
            case .purple:
                return Color.purple
            }
        }
    }
    
    enum TeleopBasePosition: String, CaseIterable, Identifiable {
        case none
        case partial
        case full
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .partial: return "Partial"
            case .full: return "Full"
            }
        }
        
        var points: Int {
            switch self {
            case .none: return 0
            case .partial: return Constants.teleopPartialBasePoints
            case .full: return Constants.teleopFullBasePoints
            }
        }
    }
    
    enum RandomizationMotif: Int, CaseIterable, Identifiable {
        case none = 0
        case motif1 = 1
        case motif2 = 2
        case motif3 = 3
        
        var id: Int { rawValue }
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .motif1: return "Motif 1"
            case .motif2: return "Motif 2"
            case .motif3: return "Motif 3"
            }
        }
        
        var fullDescription: String {
            switch self {
            case .none: return "No pattern selected"
            case .motif1: return "Motif 1 (ID 21)"
            case .motif2: return "Motif 2 (ID 22)"
            case .motif3: return "Motif 3 (ID 23)"
            }
        }
        
        var pattern: [ArtifactColor]? {
            switch self {
            case .none:
                return nil
            case .motif1:
                return [.green, .purple, .purple]
            case .motif2:
                return [.purple, .green, .purple]
            case .motif3:
                return [.purple, .purple, .green]
            }
        }
        
        static func random() -> RandomizationMotif {
            return [.motif1, .motif2, .motif3].randomElement() ?? .motif1
        }
    }
    
    // MARK: - Constants
    
    private enum Constants {
        static let autoLeaveValue = 3
        static let autoClassifiedValue = 3
        static let autoOverflowValue = 1
        static let autoPatternValue = 2
        
        static let teleopClassifiedValue = 3
        static let teleopOverflowValue = 1
        static let teleopDepotValue = 1
        static let teleopPatternValue = 2
        static let teleopPartialBasePoints = 5
        static let teleopFullBasePoints = 10
        static let teleopBonusBothFull = 10
        
        static let foulMinorValue = 5
        static let foulMajorValue = 15
        
        static let movementRPThreshold = 16
        static let goalRPThreshold = 36
        static let patternRPThreshold = 18
        
        static let classifierSlots = 9
        static let maxArtifacts = 1000
    }
    
    // MARK: - Published State
    
    @Published var randomization: RandomizationMotif = .none
    
    @Published var autoOverflowArtifacts = 0
    @Published var autoClassifiedArtifacts = 0
    @Published var autoClassifierState: [ArtifactColor] = Array(repeating: .none, count: Constants.classifierSlots)
    @Published var robot1AutoLeaves = false
    @Published var robot2AutoLeaves = false
    
    @Published var teleopDepotArtifacts = 0
    @Published var teleopOverflowArtifacts = 0
    @Published var teleopClassifiedArtifacts = 0
    @Published var teleopClassifierState: [ArtifactColor] = Array(repeating: .none, count: Constants.classifierSlots)
    @Published var robot1TeleopBase: TeleopBasePosition = .none
    @Published var robot2TeleopBase: TeleopBasePosition = .none
    
    @Published var minorFouls = 0
    @Published var majorFouls = 0
    
    // MARK: - Scoring Computations
    
    var autoLeavePoints: Int {
        (robot1AutoLeaves ? Constants.autoLeaveValue : 0) +
        (robot2AutoLeaves ? Constants.autoLeaveValue : 0)
    }
    
    var autoArtifactPoints: Int {
        autoClassifiedArtifacts * Constants.autoClassifiedValue +
        autoOverflowArtifacts * Constants.autoOverflowValue
    }
    
    var autoPatternMatches: Int {
        guard let pattern = randomization.pattern, !pattern.isEmpty else { return 0 }
        return matches(in: autoClassifierState, pattern: pattern)
    }
    
    var autoPatternPoints: Int {
        autoPatternMatches * Constants.autoPatternValue
    }
    
    var autoPoints: Int {
        autoLeavePoints + autoArtifactPoints + autoPatternPoints
    }
    
    var teleopArtifactPoints: Int {
        teleopClassifiedArtifacts * Constants.teleopClassifiedValue +
        teleopOverflowArtifacts * Constants.teleopOverflowValue
    }
    
    var teleopDepotPoints: Int {
        teleopDepotArtifacts * Constants.teleopDepotValue
    }
    
    var teleopPatternMatches: Int {
        guard let pattern = randomization.pattern, !pattern.isEmpty else { return 0 }
        return matches(in: teleopClassifierState, pattern: pattern)
    }
    
    var teleopPatternPoints: Int {
        teleopPatternMatches * Constants.teleopPatternValue
    }
    
    var teleopBasePoints: Int {
        let baseSum = robot1TeleopBase.points + robot2TeleopBase.points
        let bonus = (robot1TeleopBase == .full && robot2TeleopBase == .full) ? Constants.teleopBonusBothFull : 0
        return baseSum + bonus
    }
    
    var teleopPoints: Int {
        teleopArtifactPoints + teleopDepotPoints + teleopPatternPoints + teleopBasePoints
    }
    
    var foulPointsCommitted: Int {
        minorFouls * Constants.foulMinorValue + majorFouls * Constants.foulMajorValue
    }
    
    var preFoulTotal: Int {
        autoPoints + teleopPoints
    }
    
    // MARK: - Ranking Point Progress
    
    var movementProgress: (value: Int, goal: Int, achieved: Bool) {
        let value = autoLeavePoints + teleopBasePoints
        return (value, Constants.movementRPThreshold, value >= Constants.movementRPThreshold)
    }
    
    var goalProgress: (value: Int, goal: Int, achieved: Bool) {
        let value = autoClassifiedArtifacts + autoOverflowArtifacts + teleopClassifiedArtifacts + teleopOverflowArtifacts
        return (value, Constants.goalRPThreshold, value >= Constants.goalRPThreshold)
    }
    
    var patternProgress: (value: Int, goal: Int, achieved: Bool) {
        let value = autoPatternPoints + teleopPatternPoints
        return (value, Constants.patternRPThreshold, value >= Constants.patternRPThreshold)
    }
    
    // MARK: - Validation
    
    var validationMessages: [String] {
        var messages: [String] = []
        
        let autoGaps = nonContiguousIndexes(in: autoClassifierState)
        if !autoGaps.isEmpty {
            let gates = autoGaps.map { "\($0 + 1)" }.joined(separator: ", ")
            messages.append("Auto classifier artifacts must be contiguous after the first empty slot. Check gates: \(gates).")
        }
        
        let teleopGaps = nonContiguousIndexes(in: teleopClassifierState)
        if !teleopGaps.isEmpty {
            let gates = teleopGaps.map { "\($0 + 1)" }.joined(separator: ", ")
            messages.append("Teleop classifier artifacts must be contiguous after the first empty slot. Check gates: \(gates).")
        }
        
        return messages
    }
    
    var hasWarnings: Bool {
        !validationMessages.isEmpty
    }
    
    // MARK: - Helpers
    
    func setAutoClassifier(at index: Int, to color: ArtifactColor) {
        guard autoClassifierState.indices.contains(index) else { return }
        autoClassifierState[index] = color
    }
    
    func setTeleopClassifier(at index: Int, to color: ArtifactColor) {
        guard teleopClassifierState.indices.contains(index) else { return }
        teleopClassifierState[index] = color
    }
    
    func rollRandomization() {
        randomization = RandomizationMotif.random()
    }
    
    func reset() {
        randomization = .none
        autoOverflowArtifacts = 0
        autoClassifiedArtifacts = 0
        autoClassifierState = Array(repeating: .none, count: Constants.classifierSlots)
        robot1AutoLeaves = false
        robot2AutoLeaves = false
        
        teleopDepotArtifacts = 0
        teleopOverflowArtifacts = 0
        teleopClassifiedArtifacts = 0
        teleopClassifierState = Array(repeating: .none, count: Constants.classifierSlots)
        robot1TeleopBase = .none
        robot2TeleopBase = .none
        
        minorFouls = 0
        majorFouls = 0
    }
    
    // MARK: - Private
    
    private func matches(in state: [ArtifactColor], pattern: [ArtifactColor]) -> Int {
        guard !pattern.isEmpty else { return 0 }
        var count = 0
        for (index, color) in state.enumerated() {
            if color == pattern[index % pattern.count] {
                count += 1
            }
        }
        return count
    }
    
    private func nonContiguousIndexes(in state: [ArtifactColor]) -> [Int] {
        var sawGap = false
        var indexes: [Int] = []
        for (idx, color) in state.enumerated() {
            if color == .none {
                sawGap = true
            } else if sawGap {
                indexes.append(idx)
            }
        }
        return indexes
    }
}

