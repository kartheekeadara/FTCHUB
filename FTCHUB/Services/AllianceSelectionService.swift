//
//  AllianceSelectionService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class AllianceSelectionService: ObservableObject {
    @Published var rankedTeams: [TeamRanking] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectionCriteria: SelectionCriteria = SelectionCriteria()
    
    private let supabase = SupabaseService.shared.client
    private let scoutingService: ScoutingService
    
    init(scoutingService: ScoutingService) {
        self.scoutingService = scoutingService
    }
    
    // MARK: - Team Ranking
    func calculateTeamRankings() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let scoutingReports = scoutingService.scoutingReports
            let teamNumbers = Set(scoutingReports.map { $0.scoutedTeamNumber })
            
            var rankings: [TeamRanking] = []
            
            for teamNumber in teamNumbers {
                let teamReports = scoutingReports.filter { $0.scoutedTeamNumber == teamNumber }
                let ranking = calculateTeamRanking(teamNumber: teamNumber, reports: teamReports)
                rankings.append(ranking)
            }
            
            // Sort by overall score (descending)
            rankedTeams = rankings.sorted { $0.overallScore > $1.overallScore }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func calculateTeamRanking(teamNumber: String, reports: [ScoutingReport]) -> TeamRanking {
        var metrics = TeamMetrics()
        
        for report in reports {
            let reportData = report.reportData
            
            // Autonomous metrics
            if let autoGreen = Int(reportData["Auto Green Artifacts"] ?? "0") {
                metrics.autoGreenArtifacts.append(autoGreen)
            }
            if let autoPurple = Int(reportData["Auto Purple Artifacts"] ?? "0") {
                metrics.autoPurpleArtifacts.append(autoPurple)
            }
            if let autoReliability = Double(reportData["Autonomous Reliability"] ?? "0") {
                metrics.autoReliability.append(autoReliability)
            }
            
            // Teleop metrics
            if let teleopGreen = Int(reportData["Teleop Green Artifacts"] ?? "0") {
                metrics.teleopGreenArtifacts.append(teleopGreen)
            }
            if let teleopPurple = Int(reportData["Teleop Purple Artifacts"] ?? "0") {
                metrics.teleopPurpleArtifacts.append(teleopPurple)
            }
            if let drivingQuality = Double(reportData["Driving Quality"] ?? "0") {
                metrics.drivingQuality.append(drivingQuality)
            }
            if let robotSpeed = Double(reportData["Robot Speed"] ?? "0") {
                metrics.robotSpeed.append(robotSpeed)
            }
            
            // Endgame metrics
            if let endgameGreen = Int(reportData["Endgame Green Artifacts"] ?? "0") {
                metrics.endgameGreenArtifacts.append(endgameGreen)
            }
            if let endgamePurple = Int(reportData["Endgame Purple Artifacts"] ?? "0") {
                metrics.endgamePurpleArtifacts.append(endgamePurple)
            }
            if let endgameExecution = Double(reportData["Endgame Execution"] ?? "0") {
                metrics.endgameExecution.append(endgameExecution)
            }
            
            // Overall metrics
            if let overallQuality = Double(reportData["Overall Quality"] ?? "0") {
                metrics.overallQuality.append(overallQuality)
            }
            if let allianceRating = Double(reportData["Alliance Selection Rating"] ?? "0") {
                metrics.allianceRating.append(allianceRating)
            }
            
            // Reliability
            if let reliability = reportData["Reliability"] {
                metrics.reliabilityCounts[reliability, default: 0] += 1
            }
            
            // Penalties
            if let penalties = Int(reportData["Penalties"] ?? "0") {
                metrics.penalties.append(penalties)
            }
            
            // Strategy
            if let strategy = reportData["Primary Strategy"] {
                metrics.strategyCounts[strategy, default: 0] += 1
            }
            
            // Defense capability
            if let defends = reportData["Defends Well"] {
                if defends.lowercased() == "true" {
                    metrics.defenseCount += 1
                }
            }
            
            // Alliance coordination
            if let coordination = reportData["Alliance Coordination"] {
                if coordination.lowercased() == "true" {
                    metrics.coordinationCount += 1
                }
            }
        }
        
        return TeamRanking(
            teamNumber: teamNumber,
            metrics: metrics,
            criteria: selectionCriteria
        )
    }
    
    // MARK: - Alliance Strategy
    func generateAllianceRecommendations() -> [AllianceRecommendation] {
        var recommendations: [AllianceRecommendation] = []
        
        // Find top teams for different roles
        let captains = rankedTeams.prefix(8) // Top 8 teams as potential captains
        let specialists = rankedTeams.filter { $0.role == .specialist }
        let defenders = rankedTeams.filter { $0.defenseCapability > 0.7 }
        let reliable = rankedTeams.filter { $0.reliabilityScore > 0.8 }
        
        for captain in captains {
            var recommendation = AllianceRecommendation(
                captain: captain,
                partner1: nil,
                partner2: nil,
                reasoning: [],
                expectedScore: 0
            )
            
            // Find complementary partners
            let potentialPartners = rankedTeams.filter { $0.teamNumber != captain.teamNumber }
            
            // Sort by compatibility score
            let sortedPartners = potentialPartners.sorted { partner1, partner2 in
                calculateCompatibilityScore(captain: captain, partner: partner1) >
                calculateCompatibilityScore(captain: captain, partner: partner2)
            }
            
            if sortedPartners.count >= 2 {
                recommendation.partner1 = sortedPartners[0]
                recommendation.partner2 = sortedPartners[1]
                recommendation.expectedScore = calculateExpectedAllianceScore(
                    captain: captain,
                    partner1: sortedPartners[0],
                    partner2: sortedPartners[1]
                )
                recommendation.reasoning = generateReasoning(
                    captain: captain,
                    partner1: sortedPartners[0],
                    partner2: sortedPartners[1]
                )
            }
            
            recommendations.append(recommendation)
        }
        
        return recommendations.sorted { $0.expectedScore > $1.expectedScore }
    }
    
    private func calculateCompatibilityScore(captain: TeamRanking, partner: TeamRanking) -> Double {
        var score = 0.0
        
        // Complementary strengths
        if captain.autoScore < partner.autoScore {
            score += 0.3 // Partner compensates for captain's weak auto
        }
        if captain.teleopScore < partner.teleopScore {
            score += 0.3 // Partner compensates for captain's weak teleop
        }
        if captain.endgameScore < partner.endgameScore {
            score += 0.2 // Partner compensates for captain's weak endgame
        }
        
        // Reliability bonus
        if partner.reliabilityScore > 0.8 {
            score += 0.2
        }
        
        // Strategy compatibility
        if captain.primaryStrategy == partner.primaryStrategy {
            score += 0.1 // Same strategy works well together
        } else if (captain.primaryStrategy == .offensive && partner.primaryStrategy == .defensive) ||
                  (captain.primaryStrategy == .defensive && partner.primaryStrategy == .offensive) {
            score += 0.15 // Complementary strategies
        }
        
        // Defense capability
        if captain.defenseCapability < 0.5 && partner.defenseCapability > 0.7 {
            score += 0.1 // Partner provides defense
        }
        
        return min(1.0, score)
    }
    
    private func calculateExpectedAllianceScore(captain: TeamRanking, partner1: TeamRanking, partner2: TeamRanking) -> Double {
        let baseScore = (captain.overallScore + partner1.overallScore + partner2.overallScore) / 3
        
        // Synergy bonuses
        var synergyBonus = 0.0
        
        // Reliability bonus
        let avgReliability = (captain.reliabilityScore + partner1.reliabilityScore + partner2.reliabilityScore) / 3
        synergyBonus += avgReliability * 10
        
        // Strategy coordination bonus
        let strategies = [captain.primaryStrategy, partner1.primaryStrategy, partner2.primaryStrategy]
        let uniqueStrategies = Set(strategies).count
        if uniqueStrategies == 1 {
            synergyBonus += 15 // All same strategy
        } else if uniqueStrategies == 2 {
            synergyBonus += 10 // Two strategies
        }
        
        // Defense coverage
        let defenseCoverage = max(captain.defenseCapability, partner1.defenseCapability, partner2.defenseCapability)
        synergyBonus += defenseCoverage * 5
        
        return baseScore + synergyBonus
    }
    
    private func generateReasoning(captain: TeamRanking, partner1: TeamRanking, partner2: TeamRanking) -> [String] {
        var reasoning: [String] = []
        
        // Captain strengths
        if captain.autoScore > 0.7 {
            reasoning.append("Strong autonomous performance")
        }
        if captain.teleopScore > 0.7 {
            reasoning.append("Excellent teleop scoring")
        }
        if captain.reliabilityScore > 0.8 {
            reasoning.append("Highly reliable robot")
        }
        
        // Partner 1 strengths
        if partner1.autoScore > captain.autoScore {
            reasoning.append("Partner 1 compensates for auto weakness")
        }
        if partner1.defenseCapability > 0.7 {
            reasoning.append("Partner 1 provides strong defense")
        }
        
        // Partner 2 strengths
        if partner2.teleopScore > captain.teleopScore {
            reasoning.append("Partner 2 compensates for teleop weakness")
        }
        if partner2.reliabilityScore > 0.8 {
            reasoning.append("Partner 2 is highly reliable")
        }
        
        // Strategy synergy
        if captain.primaryStrategy == partner1.primaryStrategy && partner1.primaryStrategy == partner2.primaryStrategy {
            reasoning.append("All teams use same effective strategy")
        }
        
        return reasoning
    }
}

// MARK: - Data Models
struct TeamRanking: Identifiable {
    let id = UUID()
    let teamNumber: String
    let metrics: TeamMetrics
    let criteria: SelectionCriteria
    
    // Calculated scores (0-1 scale)
    var autoScore: Double {
        let avgGreen = metrics.autoGreenArtifacts.isEmpty ? 0 : Double(metrics.autoGreenArtifacts.reduce(0, +)) / Double(metrics.autoGreenArtifacts.count)
        let avgPurple = metrics.autoPurpleArtifacts.isEmpty ? 0 : Double(metrics.autoPurpleArtifacts.reduce(0, +)) / Double(metrics.autoPurpleArtifacts.count)
        let avgReliability = metrics.autoReliability.isEmpty ? 0 : metrics.autoReliability.reduce(0, +) / Double(metrics.autoReliability.count)
        
        return (avgGreen * 0.4 + avgPurple * 0.4 + avgReliability * 0.2) / 5.0 // Normalize to 0-1
    }
    
    var teleopScore: Double {
        let avgGreen = metrics.teleopGreenArtifacts.isEmpty ? 0 : Double(metrics.teleopGreenArtifacts.reduce(0, +)) / Double(metrics.teleopGreenArtifacts.count)
        let avgPurple = metrics.teleopPurpleArtifacts.isEmpty ? 0 : Double(metrics.teleopPurpleArtifacts.reduce(0, +)) / Double(metrics.teleopPurpleArtifacts.count)
        let avgDriving = metrics.drivingQuality.isEmpty ? 0 : metrics.drivingQuality.reduce(0, +) / Double(metrics.drivingQuality.count)
        let avgSpeed = metrics.robotSpeed.isEmpty ? 0 : metrics.robotSpeed.reduce(0, +) / Double(metrics.robotSpeed.count)
        
        return (avgGreen * 0.3 + avgPurple * 0.3 + avgDriving * 0.2 + avgSpeed * 0.2) / 5.0
    }
    
    var endgameScore: Double {
        let avgGreen = metrics.endgameGreenArtifacts.isEmpty ? 0 : Double(metrics.endgameGreenArtifacts.reduce(0, +)) / Double(metrics.endgameGreenArtifacts.count)
        let avgPurple = metrics.endgamePurpleArtifacts.isEmpty ? 0 : Double(metrics.endgamePurpleArtifacts.reduce(0, +)) / Double(metrics.endgamePurpleArtifacts.count)
        let avgExecution = metrics.endgameExecution.isEmpty ? 0 : metrics.endgameExecution.reduce(0, +) / Double(metrics.endgameExecution.count)
        
        return (avgGreen * 0.4 + avgPurple * 0.4 + avgExecution * 0.2) / 5.0
    }
    
    var reliabilityScore: Double {
        let totalReports = metrics.autoReliability.count
        guard totalReports > 0 else { return 0 }
        
        let veryReliable = metrics.reliabilityCounts["Very Reliable"] ?? 0
        let mostlyReliable = metrics.reliabilityCounts["Mostly Reliable"] ?? 0
        
        return Double(veryReliable * 2 + mostlyReliable) / Double(totalReports * 2)
    }
    
    var defenseCapability: Double {
        let totalReports = metrics.autoReliability.count
        guard totalReports > 0 else { return 0 }
        
        return Double(metrics.defenseCount) / Double(totalReports)
    }
    
    var coordinationScore: Double {
        let totalReports = metrics.autoReliability.count
        guard totalReports > 0 else { return 0 }
        
        return Double(metrics.coordinationCount) / Double(totalReports)
    }
    
    var primaryStrategy: RobotStrategy {
        let strategyCounts = metrics.strategyCounts
        let mostCommonStrategy = strategyCounts.max(by: { $0.value < $1.value })?.key ?? "mixed"
        return RobotStrategy(rawValue: mostCommonStrategy) ?? .mixed
    }
    
    var role: TeamRole {
        if autoScore > 0.8 && teleopScore > 0.8 {
            return .captain
        } else if autoScore > 0.7 || teleopScore > 0.7 {
            return .specialist
        } else if defenseCapability > 0.7 {
            return .defender
        } else {
            return .support
        }
    }
    
    var overallScore: Double {
        return (autoScore * criteria.autoWeight +
                teleopScore * criteria.teleopWeight +
                endgameScore * criteria.endgameWeight +
                reliabilityScore * criteria.reliabilityWeight +
                defenseCapability * criteria.defenseWeight +
                coordinationScore * criteria.coordinationWeight)
    }
}

struct TeamMetrics {
    var autoGreenArtifacts: [Int] = []
    var autoPurpleArtifacts: [Int] = []
    var autoReliability: [Double] = []
    
    var teleopGreenArtifacts: [Int] = []
    var teleopPurpleArtifacts: [Int] = []
    var drivingQuality: [Double] = []
    var robotSpeed: [Double] = []
    
    var endgameGreenArtifacts: [Int] = []
    var endgamePurpleArtifacts: [Int] = []
    var endgameExecution: [Double] = []
    
    var overallQuality: [Double] = []
    var allianceRating: [Double] = []
    
    var reliabilityCounts: [String: Int] = [:]
    var strategyCounts: [String: Int] = [:]
    
    var penalties: [Int] = []
    var defenseCount: Int = 0
    var coordinationCount: Int = 0
}

struct SelectionCriteria {
    var autoWeight: Double = 0.25
    var teleopWeight: Double = 0.35
    var endgameWeight: Double = 0.15
    var reliabilityWeight: Double = 0.15
    var defenseWeight: Double = 0.05
    var coordinationWeight: Double = 0.05
    
    var minReliability: Double = 0.6
    var minAutoScore: Double = 0.3
    var minTeleopScore: Double = 0.3
}

struct AllianceRecommendation: Identifiable {
    let id = UUID()
    let captain: TeamRanking
    var partner1: TeamRanking?
    var partner2: TeamRanking?
    var reasoning: [String]
    var expectedScore: Double
}

enum TeamRole: String, CaseIterable {
    case captain = "Captain"
    case specialist = "Specialist"
    case defender = "Defender"
    case support = "Support"
}

enum RobotStrategy: String, CaseIterable {
    case offensive = "Offensive Scoring"
    case defensive = "Defensive"
    case mixed = "Mixed"
    case artifactCollection = "Artifact Collection"
}
