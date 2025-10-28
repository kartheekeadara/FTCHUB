//
//  AnalyticsService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class AnalyticsService: ObservableObject {
    @Published var teamPerformance: TeamPerformanceAnalytics?
    @Published var scoutingAnalytics: ScoutingAnalytics?
    @Published var inventoryAnalytics: InventoryAnalytics?
    @Published var eventAnalytics: EventAnalytics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    private let scoutingService: ScoutingService
    
    init(scoutingService: ScoutingService) {
        self.scoutingService = scoutingService
    }
    
    // MARK: - Analytics Loading
    func loadAllAnalytics() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            async let teamPerf = loadTeamPerformanceAnalytics()
            async let scouting = loadScoutingAnalytics()
            async let inventory = loadInventoryAnalytics()
            async let events = loadEventAnalytics()
            
            teamPerformance = await teamPerf
            scoutingAnalytics = await scouting
            inventoryAnalytics = await inventory
            eventAnalytics = await events
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Team Performance Analytics
    private func loadTeamPerformanceAnalytics() async -> TeamPerformanceAnalytics? {
        // This would typically load from Supabase
        // For now, return sample data
        return TeamPerformanceAnalytics.sample
    }
    
    // MARK: - Scouting Analytics
    private func loadScoutingAnalytics() async -> ScoutingAnalytics? {
        let reports = scoutingService.scoutingReports
        
        guard !reports.isEmpty else { 
            // Return empty analytics instead of nil to prevent crashes
            return ScoutingAnalytics(
                teamRankings: [],
                performanceTrends: [],
                strategyEffectiveness: [],
                allianceRecommendations: [],
                totalReports: 0,
                teamsScouted: 0
            )
        }
        
        // Calculate team rankings
        let teamRankings = calculateTeamRankings(from: reports)
        
        // Calculate performance trends
        let performanceTrends = calculatePerformanceTrends(from: reports)
        
        // Calculate strategy effectiveness
        let strategyEffectiveness = calculateStrategyEffectiveness(from: reports)
        
        // Calculate alliance recommendations
        let allianceRecommendations = generateAllianceRecommendations(from: reports)
        
        return ScoutingAnalytics(
            teamRankings: teamRankings,
            performanceTrends: performanceTrends,
            strategyEffectiveness: strategyEffectiveness,
            allianceRecommendations: allianceRecommendations,
            totalReports: reports.count,
            teamsScouted: Set(reports.map { $0.scoutedTeamNumber }).count
        )
    }
    
    private func calculateTeamRankings(from reports: [ScoutingReport]) -> [TeamRankingData] {
        let teamGroups = Dictionary(grouping: reports) { $0.scoutedTeamNumber }
        
        return teamGroups.map { (teamNumber, teamReports) in
            let avgAutoScore = calculateAverageScore(for: teamReports, field: "Autonomous Reliability")
            let avgTeleopScore = calculateAverageScore(for: teamReports, field: "Driving Quality")
            let avgEndgameScore = calculateAverageScore(for: teamReports, field: "Endgame Execution")
            let avgOverallScore = calculateAverageScore(for: teamReports, field: "Overall Quality")
            let avgAllianceRating = calculateAverageScore(for: teamReports, field: "Alliance Selection Rating")
            
            let reliability = calculateReliabilityScore(for: teamReports)
            let defenseCapability = calculateDefenseCapability(for: teamReports)
            let coordinationScore = calculateCoordinationScore(for: teamReports)
            
            return TeamRankingData(
                teamNumber: teamNumber,
                autoScore: avgAutoScore,
                teleopScore: avgTeleopScore,
                endgameScore: avgEndgameScore,
                overallScore: avgOverallScore,
                allianceRating: avgAllianceRating,
                reliability: reliability,
                defenseCapability: defenseCapability,
                coordinationScore: coordinationScore,
                reportCount: teamReports.count
            )
        }.sorted { $0.overallScore > $1.overallScore }
    }
    
    private func calculateAverageScore(for reports: [ScoutingReport], field: String) -> Double {
        let scores = reports.compactMap { report in
            Double(report.reportData[field] ?? "0")
        }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    private func calculateReliabilityScore(for reports: [ScoutingReport]) -> Double {
        let reliabilityCounts = reports.reduce(into: [String: Int]()) { counts, report in
            if let reliability = report.reportData["Reliability"] {
                counts[reliability, default: 0] += 1
            }
        }
        
        let total = reliabilityCounts.values.reduce(0, +)
        guard total > 0 else { return 0 }
        
        let veryReliable = reliabilityCounts["Very Reliable"] ?? 0
        let mostlyReliable = reliabilityCounts["Mostly Reliable"] ?? 0
        
        return Double(veryReliable * 2 + mostlyReliable) / Double(total * 2)
    }
    
    private func calculateDefenseCapability(for reports: [ScoutingReport]) -> Double {
        let defenseCount = reports.filter { report in
            report.reportData["Defends Well"]?.lowercased() == "true"
        }.count
        
        return Double(defenseCount) / Double(reports.count)
    }
    
    private func calculateCoordinationScore(for reports: [ScoutingReport]) -> Double {
        let coordinationCount = reports.filter { report in
            report.reportData["Alliance Coordination"]?.lowercased() == "true"
        }.count
        
        return Double(coordinationCount) / Double(reports.count)
    }
    
    private func calculatePerformanceTrends(from reports: [ScoutingReport]) -> [PerformanceTrendData] {
        let sortedReports = reports.sorted { $0.createdAt < $1.createdAt }
        let teamGroups = Dictionary(grouping: sortedReports) { $0.scoutedTeamNumber }
        
        return teamGroups.compactMap { (teamNumber, teamReports) in
            guard teamReports.count >= 2 else { return nil }
            
            let trendData = teamReports.enumerated().map { index, report in
                PerformanceDataPoint(
                    date: report.createdAt,
                    autoScore: Double(report.reportData["Autonomous Reliability"] ?? "0") ?? 0,
                    teleopScore: Double(report.reportData["Driving Quality"] ?? "0") ?? 0,
                    endgameScore: Double(report.reportData["Endgame Execution"] ?? "0") ?? 0,
                    overallScore: Double(report.reportData["Overall Quality"] ?? "0") ?? 0
                )
            }
            
            return PerformanceTrendData(teamNumber: teamNumber, dataPoints: trendData)
        }
    }
    
    private func calculateStrategyEffectiveness(from reports: [ScoutingReport]) -> [StrategyEffectivenessData] {
        let strategyGroups = Dictionary(grouping: reports) { report in
            report.reportData["Primary Strategy"] ?? "Unknown"
        }
        
        return strategyGroups.map { (strategy, reports) in
            let avgScore = calculateAverageScore(for: reports, field: "Overall Quality")
            let avgAllianceRating = calculateAverageScore(for: reports, field: "Alliance Selection Rating")
            let reportCount = reports.count
            
            return StrategyEffectivenessData(
                strategy: strategy,
                averageScore: avgScore,
                averageAllianceRating: avgAllianceRating,
                reportCount: reportCount,
                effectiveness: (avgScore + avgAllianceRating) / 2
            )
        }.sorted { $0.effectiveness > $1.effectiveness }
    }
    
    private func generateAllianceRecommendations(from reports: [ScoutingReport]) -> [AllianceRecommendationData] {
        let teamRankings = calculateTeamRankings(from: reports)
        let topTeams = Array(teamRankings.prefix(8))
        
        return topTeams.map { captain in
            let potentialPartners = teamRankings.filter { $0.teamNumber != captain.teamNumber }
            let sortedPartners = potentialPartners.sorted { partner1, partner2 in
                calculateCompatibilityScore(captain: captain, partner: partner1) >
                calculateCompatibilityScore(captain: captain, partner: partner2)
            }
            
            let bestPartners = Array(sortedPartners.prefix(2))
            let expectedScore = calculateExpectedAllianceScore(
                captain: captain,
                partners: bestPartners
            )
            
            return AllianceRecommendationData(
                captain: captain,
                recommendedPartners: bestPartners,
                expectedScore: expectedScore,
                reasoning: generateAllianceReasoning(captain: captain, partners: bestPartners)
            )
        }
    }
    
    private func calculateCompatibilityScore(captain: TeamRankingData, partner: TeamRankingData) -> Double {
        var score = 0.0
        
        // Complementary strengths
        if captain.autoScore < partner.autoScore {
            score += 0.3
        }
        if captain.teleopScore < partner.teleopScore {
            score += 0.3
        }
        if captain.endgameScore < partner.endgameScore {
            score += 0.2
        }
        
        // Reliability bonus
        if partner.reliability > 0.8 {
            score += 0.2
        }
        
        return min(1.0, score)
    }
    
    private func calculateExpectedAllianceScore(captain: TeamRankingData, partners: [TeamRankingData]) -> Double {
        let baseScore = (captain.overallScore + partners.map { $0.overallScore }.reduce(0, +) / Double(partners.count)) / 2
        
        let avgReliability = (captain.reliability + partners.map { $0.reliability }.reduce(0, +) / Double(partners.count)) / 2
        let synergyBonus = avgReliability * 10
        
        return baseScore + synergyBonus
    }
    
    private func generateAllianceReasoning(captain: TeamRankingData, partners: [TeamRankingData]) -> [String] {
        var reasoning: [String] = []
        
        if captain.autoScore > 0.7 {
            reasoning.append("Strong autonomous performance")
        }
        if captain.teleopScore > 0.7 {
            reasoning.append("Excellent teleop scoring")
        }
        if captain.reliability > 0.8 {
            reasoning.append("Highly reliable robot")
        }
        
        if let partner1 = partners.first {
            if partner1.autoScore > captain.autoScore {
                reasoning.append("Partner 1 compensates for auto weakness")
            }
            if partner1.defenseCapability > 0.7 {
                reasoning.append("Partner 1 provides strong defense")
            }
        }
        
        return reasoning
    }
    
    // MARK: - Inventory Analytics
    private func loadInventoryAnalytics() async -> InventoryAnalytics? {
        // This would typically load from Supabase
        return InventoryAnalytics.sample
    }
    
    // MARK: - Event Analytics
    private func loadEventAnalytics() async -> EventAnalytics? {
        // This would typically load from Supabase
        return EventAnalytics.sample
    }
}

// MARK: - Analytics Data Models
struct TeamPerformanceAnalytics: Codable {
    let totalMatches: Int
    let winRate: Double
    let averageScore: Double
    let bestScore: Int
    let worstScore: Int
    let performanceByPhase: [String: Double]
    let recentTrend: PerformanceTrend
    
    static let sample = TeamPerformanceAnalytics(
        totalMatches: 12,
        winRate: 0.75,
        averageScore: 85.5,
        bestScore: 120,
        worstScore: 45,
        performanceByPhase: [
            "Autonomous": 0.8,
            "Teleop": 0.7,
            "Endgame": 0.9
        ],
        recentTrend: .improving
    )
}

struct ScoutingAnalytics: Codable {
    let teamRankings: [TeamRankingData]
    let performanceTrends: [PerformanceTrendData]
    let strategyEffectiveness: [StrategyEffectivenessData]
    let allianceRecommendations: [AllianceRecommendationData]
    let totalReports: Int
    let teamsScouted: Int
}

struct TeamRankingData: Codable, Identifiable {
    let id = UUID()
    let teamNumber: String
    let autoScore: Double
    let teleopScore: Double
    let endgameScore: Double
    let overallScore: Double
    let allianceRating: Double
    let reliability: Double
    let defenseCapability: Double
    let coordinationScore: Double
    let reportCount: Int
}

struct PerformanceTrendData: Codable, Identifiable {
    let id = UUID()
    let teamNumber: String
    let dataPoints: [PerformanceDataPoint]
}

struct PerformanceDataPoint: Codable {
    let date: Date
    let autoScore: Double
    let teleopScore: Double
    let endgameScore: Double
    let overallScore: Double
}

struct StrategyEffectivenessData: Codable, Identifiable {
    let id = UUID()
    let strategy: String
    let averageScore: Double
    let averageAllianceRating: Double
    let reportCount: Int
    let effectiveness: Double
}

struct AllianceRecommendationData: Codable, Identifiable {
    let id = UUID()
    let captain: TeamRankingData
    let recommendedPartners: [TeamRankingData]
    let expectedScore: Double
    let reasoning: [String]
}

struct InventoryAnalytics: Codable {
    let totalItems: Int
    let totalValue: Double
    let lowStockItems: Int
    let outOfStockItems: Int
    let categoryBreakdown: [String: Int]
    let valueByCategory: [String: Double]
    let recentActivity: [InventoryActivity]
    
    static let sample = InventoryAnalytics(
        totalItems: 45,
        totalValue: 2500.0,
        lowStockItems: 3,
        outOfStockItems: 1,
        categoryBreakdown: [
            "Electronics": 15,
            "Mechanical": 20,
            "Sensors": 10
        ],
        valueByCategory: [
            "Electronics": 1500.0,
            "Mechanical": 800.0,
            "Sensors": 200.0
        ],
        recentActivity: []
    )
}

struct InventoryActivity: Codable, Identifiable {
    let id = UUID()
    let itemName: String
    let action: String
    let quantity: Int
    let date: Date
}

struct EventAnalytics: Codable {
    let totalEvents: Int
    let upcomingEvents: Int
    let attendanceRate: Double
    let eventTypes: [String: Int]
    let averageAttendance: Double
    
    static let sample = EventAnalytics(
        totalEvents: 25,
        upcomingEvents: 3,
        attendanceRate: 0.85,
        eventTypes: [
            "Practice": 15,
            "Competition": 5,
            "Meeting": 5
        ],
        averageAttendance: 12.5
    )
}

enum PerformanceTrend: String, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
}
