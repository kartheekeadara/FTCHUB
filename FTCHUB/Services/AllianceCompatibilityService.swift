//
//  AllianceCompatibilityService.swift
//  FTCHUB
//
//  Phase 3: Alliance Compatibility Calculator
//  Analyzes phase coverage, complementary strengths, and historical synergy
//

import Foundation
import Combine
import Supabase

@MainActor
class AllianceCompatibilityService: ObservableObject {
    static let shared = AllianceCompatibilityService()
    
    @Published var compatibilityScores: [CompatibilityScore] = []
    @Published var recommendations: [CompatibilityRecommendation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    private let statisticsService = StatisticsService.shared
    
    private init() {}
    
    // MARK: - Data Models
    
    struct CompatibilityScore: Codable, Identifiable {
        let id: UUID
        let overall: Double
        let phaseCoverage: Double
        let complementaryStrengths: Double
        let historicalSynergy: Double
        let strategicCompatibility: Double
        let reliability: Double
        
        let autoCoverage: Double
        let teleopCoverage: Double
        let endgameCoverage: Double
        
        let recommendationLevel: RecommendationLevel
        let keyStrengths: [String]
        let potentialWeaknesses: [String]
        let strategicNotes: String
        
        let captainTeamNumber: String
        let partner1TeamNumber: String?
        let partner2TeamNumber: String?
        let eventName: String?
        let calculatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case overall = "overall_compatibility"
            case phaseCoverage = "phase_coverage_score"
            case complementaryStrengths = "complementary_strengths_score"
            case historicalSynergy = "historical_synergy_score"
            case strategicCompatibility = "strategic_compatibility_score"
            case reliability = "reliability_score"
            case autoCoverage = "auto_coverage"
            case teleopCoverage = "teleop_coverage"
            case endgameCoverage = "endgame_coverage"
            case recommendationLevel = "recommendation_level"
            case keyStrengths = "key_strengths"
            case potentialWeaknesses = "potential_weaknesses"
            case strategicNotes = "strategic_notes"
            case captainTeamNumber = "captain_team_number"
            case partner1TeamNumber = "partner1_team_number"
            case partner2TeamNumber = "partner2_team_number"
            case eventName = "event_name"
            case calculatedAt = "calculated_at"
        }
    }
    
    enum RecommendationLevel: String, Codable {
        case excellent = "excellent"  // 0.75-1.0
        case good = "good"           // 0.50-0.74
        case moderate = "moderate"   // 0.25-0.49
        case poor = "poor"           // 0.0-0.24
        
        var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .moderate: return "Moderate"
            case .poor: return "Poor"
            }
        }
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .yellow
            case .moderate: return .orange
            case .poor: return .red
            }
        }
        
        static func fromScore(_ score: Double) -> RecommendationLevel {
            if score >= 0.75 { return .excellent }
            else if score >= 0.50 { return .good }
            else if score >= 0.25 { return .moderate }
            else { return .poor }
        }
    }
    
    struct PhaseCoverageAnalysis: Codable {
        let auto: Double
        let teleop: Double
        let endgame: Double
        let gaps: [String]
        let strengths: [String]
    }
    
    struct CompatibilityRecommendation: Codable, Identifiable {
        let id: UUID
        let captainTeamNumber: String
        let partner1TeamNumber: String
        let partner2TeamNumber: String
        let compatibilityScore: Double
        let recommendationLevel: RecommendationLevel
        let reasoning: [String]
        let keyStrengths: [String]
        let potentialWeaknesses: [String]
    }
    
    struct SynergyMetrics: Codable {
        let winRateTogether: Double
        let averageScoreTogether: Double
        let expectedScore: Double
        let scoreBoost: Double
        let matchCount: Int
    }
    
    // MARK: - Main Compatibility Calculation
    
    /// Calculates compatibility score for an alliance
    func calculateCompatibility(
        captain: String,
        partner1: String,
        partner2: String,
        eventName: String,
        teamId: UUID
    ) async throws -> CompatibilityScore {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Get team statistics for all three teams
            let captainStats = try await statisticsService.getStatistics(
                teamNumber: captain,
                eventName: eventName
            )
            let partner1Stats = try await statisticsService.getStatistics(
                teamNumber: partner1,
                eventName: eventName
            )
            let partner2Stats = try await statisticsService.getStatistics(
                teamNumber: partner2,
                eventName: eventName
            )
            
            guard let capStats = captainStats,
                  let p1Stats = partner1Stats,
                  let p2Stats = partner2Stats else {
                throw CompatibilityError.insufficientData("Missing statistics for one or more teams")
            }
            
            // Convert to AllianceTeamRanking format (simplified)
            let captainRanking = AllianceTeamRanking(from: capStats)
            let partner1Ranking = AllianceTeamRanking(from: p1Stats)
            let partner2Ranking = AllianceTeamRanking(from: p2Stats)
            
            // Calculate phase coverage (40% weight)
            let phaseCoverage = analyzePhaseCoverage(
                captain: captainRanking,
                partner1: partner1Ranking,
                partner2: partner2Ranking
            )
            
            // Calculate complementary strengths (25% weight)
            let complementaryStrengths = analyzeComplementaryStrengths(
                captain: captainRanking,
                partner1: partner1Ranking,
                partner2: partner2Ranking
            )
            
            // Calculate historical synergy (20% weight)
            let synergy = try await calculateHistoricalSynergy(
                team1: captain,
                team2: partner1,
                team3: partner2,
                eventName: eventName
            )
            
            // Calculate strategic compatibility (10% weight)
            let strategicCompatibility = calculateStrategicCompatibility(
                captain: captainRanking,
                partner1: partner1Ranking,
                partner2: partner2Ranking
            )
            
            // Calculate reliability factor (5% weight)
            let reliability = calculateReliabilityFactor(
                captain: captainRanking,
                partner1: partner1Ranking,
                partner2: partner2Ranking
            )
            
            // Combine weighted scores
            let overall = (phaseCoverage.overall * 0.40) +
                         (complementaryStrengths * 0.25) +
                         (synergy.synergyScore * 0.20) +
                         (strategicCompatibility * 0.10) +
                         (reliability * 0.05)
            
            // Generate recommendations
            let recommendationLevel = RecommendationLevel.fromScore(overall)
            let (keyStrengths, potentialWeaknesses, strategicNotes) = generateRecommendations(
                phaseCoverage: phaseCoverage,
                complementaryStrengths: complementaryStrengths,
                synergy: synergy,
                strategicCompatibility: strategicCompatibility,
                reliability: reliability
            )
            
            let score = CompatibilityScore(
                id: UUID(),
                overall: overall,
                phaseCoverage: phaseCoverage.overall,
                complementaryStrengths: complementaryStrengths,
                historicalSynergy: synergy.synergyScore,
                strategicCompatibility: strategicCompatibility,
                reliability: reliability,
                autoCoverage: phaseCoverage.auto,
                teleopCoverage: phaseCoverage.teleop,
                endgameCoverage: phaseCoverage.endgame,
                recommendationLevel: recommendationLevel,
                keyStrengths: keyStrengths,
                potentialWeaknesses: potentialWeaknesses,
                strategicNotes: strategicNotes,
                captainTeamNumber: captain,
                partner1TeamNumber: partner1,
                partner2TeamNumber: partner2,
                eventName: eventName,
                calculatedAt: Date()
            )
            
            // Save to database
            try await saveCompatibilityScore(score, teamId: teamId)
            
            return score
            
        } catch {
            errorMessage = "Failed to calculate compatibility: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Phase Coverage Analysis
    
    private func analyzePhaseCoverage(
        captain: AllianceTeamRanking,
        partner1: AllianceTeamRanking,
        partner2: AllianceTeamRanking
    ) -> (overall: Double, auto: Double, teleop: Double, endgame: Double, gaps: [String], strengths: [String]) {
        // Calculate average scores for each phase
        let autoAvg = (captain.autoScore + partner1.autoScore + partner2.autoScore) / 3.0
        let teleopAvg = (captain.teleopScore + partner1.teleopScore + partner2.teleopScore) / 3.0
        let endgameAvg = (captain.endgameScore + partner1.endgameScore + partner2.endgameScore) / 3.0
        
        // Overall phase coverage (average of all phases)
        let overall = (autoAvg + teleopAvg + endgameAvg) / 3.0
        
        // Identify gaps
        var gaps: [String] = []
        if autoAvg < 0.5 { gaps.append("Weak autonomous phase") }
        if teleopAvg < 0.5 { gaps.append("Weak teleop phase") }
        if endgameAvg < 0.5 { gaps.append("Weak endgame phase") }
        
        // Identify strengths
        var strengths: [String] = []
        if autoAvg > 0.7 { strengths.append("Strong autonomous") }
        if teleopAvg > 0.7 { strengths.append("Strong teleop") }
        if endgameAvg > 0.7 { strengths.append("Strong endgame") }
        
        return (overall, autoAvg, teleopAvg, endgameAvg, gaps, strengths)
    }
    
    // MARK: - Complementary Strengths Analysis
    
    private func analyzeComplementaryStrengths(
        captain: AllianceTeamRanking,
        partner1: AllianceTeamRanking,
        partner2: AllianceTeamRanking
    ) -> Double {
        var score = 0.0
        
        // Check if partners cover captain's weaknesses
        if captain.autoScore < 0.5 {
            if partner1.autoScore > 0.7 || partner2.autoScore > 0.7 {
                score += 0.3
            }
        }
        
        if captain.teleopScore < 0.5 {
            if partner1.teleopScore > 0.7 || partner2.teleopScore > 0.7 {
                score += 0.3
            }
        }
        
        if captain.endgameScore < 0.5 {
            if partner1.endgameScore > 0.7 || partner2.endgameScore > 0.7 {
                score += 0.2
            }
        }
        
        // Role distribution bonus
        let roles = [captain.role, partner1.role, partner2.role]
        let uniqueRoles = Set(roles).count
        if uniqueRoles == 3 {
            score += 0.2 // Well-distributed roles
        }
        
        return min(1.0, score)
    }
    
    // MARK: - Historical Synergy Calculation
    
    private func calculateHistoricalSynergy(
        team1: String,
        team2: String,
        team3: String,
        eventName: String
    ) async throws -> (synergyScore: Double, metrics: SynergyMetrics) {
        // Query alliance_history for past alliances
        let history: [AllianceHistory] = try await supabase
            .from("alliance_history")
            .select()
            .eq("event_name", value: eventName)
            .execute()
            .value
        
        // Find matches where these teams were allies
        let relevantMatches = history.filter { match in
            let teams = [match.redTeam1, match.redTeam2, match.redTeam3, match.blueTeam1, match.blueTeam2, match.blueTeam3]
            return teams.contains(team1) && teams.contains(team2) && teams.contains(team3)
        }
        
        guard !relevantMatches.isEmpty else {
            // No historical data - return neutral score
            return (0.5, SynergyMetrics(
                winRateTogether: 0.5,
                averageScoreTogether: 0.0,
                expectedScore: 0.0,
                scoreBoost: 0.0,
                matchCount: 0
            ))
        }
        
        // Calculate metrics
        var wins = 0
        var totalScore = 0
        var matchCount = 0
        
        for match in relevantMatches {
            matchCount += 1
            let isRed = [match.redTeam1, match.redTeam2, match.redTeam3].contains(team1)
            let ourScore = isRed ? (match.redScore ?? 0) : (match.blueScore ?? 0)
            let opponentScore = isRed ? (match.blueScore ?? 0) : (match.redScore ?? 0)
            
            totalScore += ourScore
            if ourScore > opponentScore {
                wins += 1
            }
        }
        
        let winRateTogether = matchCount > 0 ? Double(wins) / Double(matchCount) : 0.5
        let averageScoreTogether = matchCount > 0 ? Double(totalScore) / Double(matchCount) : 0.0
        
        // Expected score would be sum of individual OPRs (simplified)
        let expectedScore = averageScoreTogether // Placeholder
        
        // Synergy score based on win rate and performance
        let synergyScore = min(1.0, winRateTogether * 0.7 + (averageScoreTogether > expectedScore ? 0.3 : 0.0))
        
        return (synergyScore, SynergyMetrics(
            winRateTogether: winRateTogether,
            averageScoreTogether: averageScoreTogether,
            expectedScore: expectedScore,
            scoreBoost: averageScoreTogether - expectedScore,
            matchCount: matchCount
        ))
    }
    
    // MARK: - Strategic Compatibility
    
    private func calculateStrategicCompatibility(
        captain: AllianceTeamRanking,
        partner1: AllianceTeamRanking,
        partner2: AllianceTeamRanking
    ) -> Double {
        // Check if strategies align
        let strategies = [captain.primaryStrategy, partner1.primaryStrategy, partner2.primaryStrategy]
        let uniqueStrategies = Set(strategies).count
        
        if uniqueStrategies == 1 {
            return 1.0 // All same strategy
        } else if uniqueStrategies == 2 {
            return 0.7 // Two strategies
        } else {
            return 0.4 // All different
        }
    }
    
    // MARK: - Reliability Factor
    
    private func calculateReliabilityFactor(
        captain: AllianceTeamRanking,
        partner1: AllianceTeamRanking,
        partner2: AllianceTeamRanking
    ) -> Double {
        let avgReliability = (captain.reliabilityScore + partner1.reliabilityScore + partner2.reliabilityScore) / 3.0
        return avgReliability
    }
    
    // MARK: - Recommendation Generation
    
    private func generateRecommendations(
        phaseCoverage: (overall: Double, auto: Double, teleop: Double, endgame: Double, gaps: [String], strengths: [String]),
        complementaryStrengths: Double,
        synergy: (synergyScore: Double, metrics: SynergyMetrics),
        strategicCompatibility: Double,
        reliability: Double
    ) -> (keyStrengths: [String], potentialWeaknesses: [String], strategicNotes: String) {
        var keyStrengths: [String] = []
        var potentialWeaknesses: [String] = []
        var notes: [String] = []
        
        // Add phase coverage strengths
        keyStrengths.append(contentsOf: phaseCoverage.strengths)
        
        // Add complementary strengths
        if complementaryStrengths > 0.7 {
            keyStrengths.append("Strong complementary capabilities")
        }
        
        // Add historical synergy
        if synergy.synergyScore > 0.7 {
            keyStrengths.append("Proven track record together")
            notes.append("Teams have \(synergy.metrics.matchCount) matches together with \(Int(synergy.metrics.winRateTogether * 100))% win rate")
        }
        
        // Add reliability
        if reliability > 0.8 {
            keyStrengths.append("Highly reliable alliance")
        }
        
        // Add weaknesses
        potentialWeaknesses.append(contentsOf: phaseCoverage.gaps)
        
        if complementaryStrengths < 0.3 {
            potentialWeaknesses.append("Limited complementary strengths")
        }
        
        if strategicCompatibility < 0.5 {
            potentialWeaknesses.append("Different strategic approaches")
        }
        
        if reliability < 0.6 {
            potentialWeaknesses.append("Reliability concerns")
        }
        
        // Generate strategic notes
        if phaseCoverage.auto > 0.7 && phaseCoverage.teleop > 0.7 {
            notes.append("Strong across all phases - excellent offensive capability")
        }
        
        if complementaryStrengths > 0.6 {
            notes.append("Partners effectively cover captain's weaknesses")
        }
        
        let strategicNotes = notes.joined(separator: ". ")
        
        return (keyStrengths, potentialWeaknesses, strategicNotes)
    }
    
    // MARK: - Database Operations
    
    private func saveCompatibilityScore(_ score: CompatibilityScore, teamId: UUID) async throws {
        struct CompatibilityScoreRecord: Encodable {
            let id: String
            let teamId: String
            let eventName: String?
            let captainTeamNumber: String
            let partner1TeamNumber: String?
            let partner2TeamNumber: String?
            let overallCompatibility: Double
            let phaseCoverageScore: Double?
            let complementaryStrengthsScore: Double?
            let historicalSynergyScore: Double?
            let strategicCompatibilityScore: Double?
            let reliabilityScore: Double?
            let autoCoverage: Double?
            let teleopCoverage: Double?
            let endgameCoverage: Double?
            let recommendationLevel: String
            let keyStrengths: [String]
            let potentialWeaknesses: [String]
            let strategicNotes: String?
            let calculatedAt: String
        }
        
        let scoreRecord = CompatibilityScoreRecord(
            id: score.id.uuidString,
            teamId: teamId.uuidString,
            eventName: score.eventName,
            captainTeamNumber: score.captainTeamNumber,
            partner1TeamNumber: score.partner1TeamNumber,
            partner2TeamNumber: score.partner2TeamNumber,
            overallCompatibility: score.overall,
            phaseCoverageScore: score.phaseCoverage,
            complementaryStrengthsScore: score.complementaryStrengths,
            historicalSynergyScore: score.historicalSynergy,
            strategicCompatibilityScore: score.strategicCompatibility,
            reliabilityScore: score.reliability,
            autoCoverage: score.autoCoverage,
            teleopCoverage: score.teleopCoverage,
            endgameCoverage: score.endgameCoverage,
            recommendationLevel: score.recommendationLevel.rawValue,
            keyStrengths: score.keyStrengths,
            potentialWeaknesses: score.potentialWeaknesses,
            strategicNotes: score.strategicNotes,
            calculatedAt: ISO8601DateFormatter().string(from: score.calculatedAt)
        )
        
        try await supabase
            .from("alliance_compatibility_scores")
            .upsert(scoreRecord, onConflict: "team_id,captain_team_number,partner1_team_number,partner2_team_number,event_name")
            .execute()
    }
    
    // MARK: - Recommendation Generation
    
    func generateRecommendations(for teamNumber: String, eventName: String, teamId: UUID) async throws -> [CompatibilityRecommendation] {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Get all team statistics for the event
            let rankings = try await statisticsService.getRankings(eventName: eventName, metric: .ccwm)
            
            guard rankings.count >= 3 else {
                throw CompatibilityError.insufficientData("Need at least 3 teams for recommendations")
            }
            
            // Get captain's statistics
            guard let captainStats = rankings.first(where: { $0.teamNumber == teamNumber }) else {
                throw CompatibilityError.insufficientData("Captain team not found in rankings")
            }
            
            let captainRanking = AllianceTeamRanking(from: captainStats)
            
            // Calculate compatibility for all possible partner combinations
            var recommendations: [CompatibilityRecommendation] = []
            
            let otherTeams = rankings.filter { $0.teamNumber != teamNumber }
            
            for i in 0..<otherTeams.count {
                for j in (i+1)..<otherTeams.count {
                    let partner1 = otherTeams[i]
                    let partner2 = otherTeams[j]
                    
                    let partner1Ranking = AllianceTeamRanking(from: partner1)
                    let partner2Ranking = AllianceTeamRanking(from: partner2)
                    
                    // Quick compatibility calculation (simplified)
                    let phaseCoverage = analyzePhaseCoverage(
                        captain: captainRanking,
                        partner1: partner1Ranking,
                        partner2: partner2Ranking
                    )
                    
                    let complementaryStrengths = analyzeComplementaryStrengths(
                        captain: captainRanking,
                        partner1: partner1Ranking,
                        partner2: partner2Ranking
                    )
                    
                    let synergy = try await calculateHistoricalSynergy(
                        team1: teamNumber,
                        team2: partner1.teamNumber,
                        team3: partner2.teamNumber,
                        eventName: eventName
                    )
                    
                    let strategicCompatibility = calculateStrategicCompatibility(
                        captain: captainRanking,
                        partner1: partner1Ranking,
                        partner2: partner2Ranking
                    )
                    
                    let reliability = calculateReliabilityFactor(
                        captain: captainRanking,
                        partner1: partner1Ranking,
                        partner2: partner2Ranking
                    )
                    
                    let overall = (phaseCoverage.overall * 0.40) +
                                 (complementaryStrengths * 0.25) +
                                 (synergy.synergyScore * 0.20) +
                                 (strategicCompatibility * 0.10) +
                                 (reliability * 0.05)
                    
                    let (keyStrengths, potentialWeaknesses, _) = generateRecommendations(
                        phaseCoverage: phaseCoverage,
                        complementaryStrengths: complementaryStrengths,
                        synergy: synergy,
                        strategicCompatibility: strategicCompatibility,
                        reliability: reliability
                    )
                    
                    var reasoning: [String] = []
                    if phaseCoverage.overall > 0.7 {
                        reasoning.append("Strong phase coverage")
                    }
                    if complementaryStrengths > 0.6 {
                        reasoning.append("Complementary strengths")
                    }
                    if synergy.synergyScore > 0.7 {
                        reasoning.append("Proven synergy")
                    }
                    
                    recommendations.append(CompatibilityRecommendation(
                        id: UUID(),
                        captainTeamNumber: teamNumber,
                        partner1TeamNumber: partner1.teamNumber,
                        partner2TeamNumber: partner2.teamNumber,
                        compatibilityScore: overall,
                        recommendationLevel: RecommendationLevel.fromScore(overall),
                        reasoning: reasoning,
                        keyStrengths: keyStrengths,
                        potentialWeaknesses: potentialWeaknesses
                    ))
                }
            }
            
            // Sort by compatibility score
            recommendations.sort { $0.compatibilityScore > $1.compatibilityScore }
            
            self.recommendations = recommendations
            return recommendations
            
        } catch {
            errorMessage = "Failed to generate recommendations: \(error.localizedDescription)"
            throw error
        }
    }
}

// MARK: - Helper Structures

private struct AllianceTeamRanking {
    let teamNumber: String
    let autoScore: Double
    let teleopScore: Double
    let endgameScore: Double
    let reliabilityScore: Double
    let role: AllianceTeamRole
    let primaryStrategy: AllianceRobotStrategy
    
    init(from stats: StatisticsService.TeamStatistics) {
        self.teamNumber = stats.teamNumber
        // Convert OPR/DPR/CCWM to normalized scores (0-1 scale)
        // Simplified - would need actual phase data
        self.autoScore = min(1.0, (stats.opr ?? 0) / 200.0) // Normalize
        self.teleopScore = min(1.0, (stats.opr ?? 0) / 200.0)
        self.endgameScore = min(1.0, (stats.opr ?? 0) / 200.0)
        self.reliabilityScore = stats.winRate ?? 0.5
        self.role = .captain // Simplified
        self.primaryStrategy = .offensive // Simplified
    }
}

private enum AllianceTeamRole {
    case captain
    case specialist
    case defender
    case support
}

private enum AllianceRobotStrategy {
    case offensive
    case defensive
    case mixed
    case artifactCollection
}

// MARK: - Alliance History Model

private struct AllianceHistory: Codable {
    let id: UUID
    let eventName: String
    let matchNumber: String
    let redTeam1: String
    let redTeam2: String
    let redTeam3: String
    let blueTeam1: String
    let blueTeam2: String
    let blueTeam3: String
    let redScore: Int?
    let blueScore: Int?
    let winner: String?
    let matchDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventName = "event_name"
        case matchNumber = "match_number"
        case redTeam1 = "red_team1"
        case redTeam2 = "red_team2"
        case redTeam3 = "red_team3"
        case blueTeam1 = "blue_team1"
        case blueTeam2 = "blue_team2"
        case blueTeam3 = "blue_team3"
        case redScore = "red_score"
        case blueScore = "blue_score"
        case winner
        case matchDate = "match_date"
    }
}

// MARK: - Error Types

enum CompatibilityError: LocalizedError {
    case insufficientData(String)
    case calculationFailed(String)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .insufficientData(let message):
            return "Insufficient data: \(message)"
        case .calculationFailed(let message):
            return "Calculation failed: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}

// MARK: - Color Extension

import SwiftUI
extension Color {
    // Already exists in SwiftUI, but adding for clarity
}
