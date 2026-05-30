//
//  AdvancementTrackingService.swift
//  FTCHUB
//
//  Phase 2: Advancement Points Tracking
//  Tracks qualification progress, award points, and playoff points
//

import Foundation
import Combine
import Supabase

@MainActor
class AdvancementTrackingService: ObservableObject {
    static let shared = AdvancementTrackingService()
    
    @Published var eventPoints: [EventPoints] = []
    @Published var seasonSummary: SeasonAdvancementSummary?
    @Published var advancementStatus: AdvancementStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Data Models
    
    struct EventPoints: Codable, Identifiable {
        let id: UUID
        let teamId: UUID
        let teamNumber: String
        let eventName: String
        let eventType: EventType?
        let eventDate: Date?
        let seasonYear: Int
        let winPoints: Int
        let tiePoints: Int
        let rankingPoints: Int
        let awardPoints: Int
        let totalQualificationPoints: Int
        let allianceSelectionPoints: Int
        let playoffMatchPoints: Int
        let championshipPoints: Int
        let totalPlayoffPoints: Int
        let finalRanking: Int?
        let totalTeams: Int?
        let awards: [String]
        let advancedToNextLevel: Bool
        let nextLevelEvent: String?
        let verified: Bool
        let source: String
        let notes: String?
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamId = "team_id"
            case teamNumber = "team_number"
            case eventName = "event_name"
            case eventType = "event_type"
            case eventDate = "event_date"
            case seasonYear = "season_year"
            case winPoints = "win_points"
            case tiePoints = "tie_points"
            case rankingPoints = "ranking_points"
            case awardPoints = "award_points"
            case totalQualificationPoints = "total_qualification_points"
            case allianceSelectionPoints = "alliance_selection_points"
            case playoffMatchPoints = "playoff_match_points"
            case championshipPoints = "championship_points"
            case totalPlayoffPoints = "total_playoff_points"
            case finalRanking = "final_ranking"
            case totalTeams = "total_teams"
            case awards = "awards_won"
            case advancedToNextLevel = "advanced_to_next_level"
            case nextLevelEvent = "next_level_event"
            case verified
            case source
            case notes
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    enum EventType: String, Codable, CaseIterable {
        case qualifier = "qualifier"
        case state = "state"
        case championship = "championship"
        case worlds = "worlds"
        
        var displayName: String {
            switch self {
            case .qualifier: return "Qualifier"
            case .state: return "State"
            case .championship: return "Championship"
            case .worlds: return "Worlds"
            }
        }
    }
    
    struct SeasonAdvancementSummary: Codable, Identifiable {
        let id: UUID
        let teamId: UUID
        let teamNumber: String
        let seasonYear: Int
        let totalQualificationPoints: Int
        let totalPlayoffPoints: Int
        let totalPoints: Int
        let eventsAttended: Int
        let eventsWon: Int
        let eventsAdvanced: Int
        let currentLevel: String?
        let advancementStatus: String?
        let nextMilestone: String?
        let pointsToNextMilestone: Int?
        let seasonRanking: Int?
        let totalTeamsInSeason: Int?
        let lastUpdatedAt: Date
        let createdAt: Date
        let updatedAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamId = "team_id"
            case teamNumber = "team_number"
            case seasonYear = "season_year"
            case totalQualificationPoints = "total_qualification_points"
            case totalPlayoffPoints = "total_playoff_points"
            case totalPoints = "total_points"
            case eventsAttended = "events_attended"
            case eventsWon = "events_won"
            case eventsAdvanced = "events_advanced"
            case currentLevel = "current_level"
            case advancementStatus = "advancement_status"
            case nextMilestone = "next_milestone"
            case pointsToNextMilestone = "points_to_next_milestone"
            case seasonRanking = "season_ranking"
            case totalTeamsInSeason = "total_teams_in_season"
            case lastUpdatedAt = "last_updated_at"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    struct AdvancementStatus: Codable {
        let currentLevel: AdvancementLevel
        let totalPoints: Int
        let pointsToNext: Int
        let advancementProbability: Double
        let nextMilestone: String
        let status: QualificationStatus
    }
    
    enum AdvancementLevel: String, Codable, CaseIterable {
        case qualifier = "qualifier"
        case state = "state"
        case championship = "championship"
        case worlds = "worlds"
        
        var displayName: String {
            switch self {
            case .qualifier: return "Qualifier"
            case .state: return "State"
            case .championship: return "Championship"
            case .worlds: return "Worlds"
            }
        }
    }
    
    enum QualificationStatus: String, Codable {
        case qualified = "qualified"
        case pending = "pending"
        case notQualified = "not_qualified"
        
        var displayName: String {
            switch self {
            case .qualified: return "Qualified"
            case .pending: return "Pending"
            case .notQualified: return "Not Qualified"
            }
        }
    }
    
    // MARK: - Point Calculation
    
    /// Calculates event points from match data
    func calculateEventPoints(eventName: String, teamId: UUID, seasonYear: Int) async throws -> EventPoints {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Load matches for the event
            let matches: [Match] = try await supabase
                .from("matches")
                .select()
                .eq("event_name", value: eventName)
                .eq("team_id", value: teamId)
                .eq("season_year", value: seasonYear)
                .execute()
                .value
            
            let completedMatches = matches.filter { $0.status == .completed }
            
            // Calculate win points (2 points per win)
            var wins = 0
            var ties = 0
            var losses = 0
            
            for match in completedMatches {
                let isRed = getRedAllianceTeams(from: match).contains { team in
                    // Need to get team number from team_id - simplified for now
                    true // This would need actual team number lookup
                }
                
                let redScore = match.redAllianceScore ?? (match.allianceColor == .red ? match.ourScore : match.opponentScore) ?? 0
                let blueScore = match.blueAllianceScore ?? (match.allianceColor == .blue ? match.ourScore : match.opponentScore) ?? 0
                
                if isRed {
                    if redScore > blueScore { wins += 1 }
                    else if redScore < blueScore { losses += 1 }
                    else { ties += 1 }
                } else {
                    if blueScore > redScore { wins += 1 }
                    else if blueScore < redScore { losses += 1 }
                    else { ties += 1 }
                }
            }
            
            let winPoints = wins * 2
            let tiePoints = ties * 1
            
            // Ranking points would need to be calculated from final ranking
            // For now, set to 0 - will be updated manually or from official sources
            let rankingPoints = 0
            
            // Award points would come from manual entry
            let awardPoints = 0
            
            let totalQualificationPoints = winPoints + tiePoints + rankingPoints + awardPoints
            
            // Get team number (simplified - would need actual lookup)
            let teamNumber = "0000" // Placeholder - needs actual team number
            
            return EventPoints(
                id: UUID(),
                teamId: teamId,
                teamNumber: teamNumber,
                eventName: eventName,
                eventType: nil,
                eventDate: nil,
                seasonYear: seasonYear,
                winPoints: winPoints,
                tiePoints: tiePoints,
                rankingPoints: rankingPoints,
                awardPoints: awardPoints,
                totalQualificationPoints: totalQualificationPoints,
                allianceSelectionPoints: 0,
                playoffMatchPoints: 0,
                championshipPoints: 0,
                totalPlayoffPoints: 0,
                finalRanking: nil,
                totalTeams: nil,
                awards: [],
                advancedToNextLevel: false,
                nextLevelEvent: nil,
                verified: false,
                source: "calculated",
                notes: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        } catch {
            errorMessage = "Failed to calculate event points: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func getRedAllianceTeams(from match: Match) -> [String] {
        var teams: [String] = []
        if let team1 = match.redTeam1 { teams.append(team1) }
        if let team2 = match.redTeam2 { teams.append(team2) }
        if let team3 = match.redTeam3 { teams.append(team3) }
        return teams
    }
    
    private func getBlueAllianceTeams(from match: Match) -> [String] {
        var teams: [String] = []
        if let team1 = match.blueTeam1 { teams.append(team1) }
        if let team2 = match.blueTeam2 { teams.append(team2) }
        if let team3 = match.blueTeam3 { teams.append(team3) }
        return teams
    }
    
    // MARK: - Database Operations
    
    /// Adds or updates event points
    func addEventPoints(_ points: EventPoints) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            struct PointsRecord: Encodable {
                let id: String
                let teamId: String
                let teamNumber: String
                let eventName: String
                let eventType: String?
                let eventDate: String?
                let seasonYear: Int
                let winPoints: Int
                let tiePoints: Int
                let rankingPoints: Int
                let awardPoints: Int
                let totalQualificationPoints: Int
                let allianceSelectionPoints: Int
                let playoffMatchPoints: Int
                let championshipPoints: Int
                let totalPlayoffPoints: Int
                let finalRanking: Int?
                let totalTeams: Int?
                let awardsWon: [String]
                let advancedToNextLevel: Bool
                let nextLevelEvent: String?
                let verified: Bool
                let source: String
                let notes: String?
            }
            
            let pointsRecord = PointsRecord(
                id: points.id.uuidString,
                teamId: points.teamId.uuidString,
                teamNumber: points.teamNumber,
                eventName: points.eventName,
                eventType: points.eventType?.rawValue,
                eventDate: points.eventDate != nil ? ISO8601DateFormatter().string(from: points.eventDate!) : nil,
                seasonYear: points.seasonYear,
                winPoints: points.winPoints,
                tiePoints: points.tiePoints,
                rankingPoints: points.rankingPoints,
                awardPoints: points.awardPoints,
                totalQualificationPoints: points.totalQualificationPoints,
                allianceSelectionPoints: points.allianceSelectionPoints,
                playoffMatchPoints: points.playoffMatchPoints,
                championshipPoints: points.championshipPoints,
                totalPlayoffPoints: points.totalPlayoffPoints,
                finalRanking: points.finalRanking,
                totalTeams: points.totalTeams,
                awardsWon: points.awards,
                advancedToNextLevel: points.advancedToNextLevel,
                nextLevelEvent: points.nextLevelEvent,
                verified: points.verified,
                source: points.source,
                notes: points.notes
            )
            
            try await supabase
                .from("advancement_points")
                .upsert(pointsRecord, onConflict: "team_id,event_name,season_year")
                .execute()
            
            // Update season summary
            try await updateSeasonSummary(teamId: points.teamId, seasonYear: points.seasonYear)
            
        } catch {
            errorMessage = "Failed to save event points: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Updates season summary for a team
    func updateSeasonSummary(teamId: UUID, seasonYear: Int) async throws {
        do {
            // Get all event points for the season
            let points: [EventPoints] = try await supabase
                .from("advancement_points")
                .select()
                .eq("team_id", value: teamId)
                .eq("season_year", value: seasonYear)
                .execute()
                .value
            
            let totalQualificationPoints = points.reduce(0) { $0 + $1.totalQualificationPoints }
            let totalPlayoffPoints = points.reduce(0) { $0 + $1.totalPlayoffPoints }
            let totalPoints = totalQualificationPoints + totalPlayoffPoints
            let eventsAttended = points.count
            let eventsWon = points.filter { $0.finalRanking == 1 }.count
            let eventsAdvanced = points.filter { $0.advancedToNextLevel }.count
            
            // Determine current level and advancement status
            let currentLevel = determineCurrentLevel(from: points)
            let advancementStatus = determineAdvancementStatus(totalPoints: totalPoints, currentLevel: currentLevel)
            let (nextMilestone, pointsToNext) = calculateNextMilestone(totalPoints: totalPoints, currentLevel: currentLevel)
            
            // Get team number (simplified)
            let teamNumber = points.first?.teamNumber ?? "0000"
            
            struct SummaryRecord: Encodable {
                let teamId: String
                let teamNumber: String
                let seasonYear: Int
                let totalQualificationPoints: Int
                let totalPlayoffPoints: Int
                let totalPoints: Int
                let eventsAttended: Int
                let eventsWon: Int
                let eventsAdvanced: Int
                let currentLevel: String
                let advancementStatus: String
                let nextMilestone: String?
                let pointsToNextMilestone: Int?
            }
            
            let summaryRecord = SummaryRecord(
                teamId: teamId.uuidString,
                teamNumber: teamNumber,
                seasonYear: seasonYear,
                totalQualificationPoints: totalQualificationPoints,
                totalPlayoffPoints: totalPlayoffPoints,
                totalPoints: totalPoints,
                eventsAttended: eventsAttended,
                eventsWon: eventsWon,
                eventsAdvanced: eventsAdvanced,
                currentLevel: currentLevel,
                advancementStatus: advancementStatus.rawValue,
                nextMilestone: nextMilestone,
                pointsToNextMilestone: pointsToNext
            )
            
            try await supabase
                .from("season_advancement_summary")
                .upsert(summaryRecord, onConflict: "team_id,season_year")
                .execute()
            
            // Reload season summary
            try await loadSeasonSummary(teamId: teamId, seasonYear: seasonYear)
            
        } catch {
            errorMessage = "Failed to update season summary: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Loads season summary
    func loadSeasonSummary(teamId: UUID, seasonYear: Int) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let summaries: [SeasonAdvancementSummary] = try await supabase
                .from("season_advancement_summary")
                .select()
                .eq("team_id", value: teamId)
                .eq("season_year", value: seasonYear)
                .execute()
                .value
            
            seasonSummary = summaries.first
            
        } catch {
            errorMessage = "Failed to load season summary: \(error.localizedDescription)"
            throw error
        }
    }
    
    /// Gets advancement status
    func getAdvancementStatus(teamId: UUID, seasonYear: Int) async throws -> AdvancementStatus {
        if seasonSummary == nil {
            try await loadSeasonSummary(teamId: teamId, seasonYear: seasonYear)
        }
        
        guard let summary = seasonSummary else {
            throw AdvancementError.noData("No season summary found")
        }
        
        let currentLevel = AdvancementLevel(rawValue: summary.currentLevel ?? "qualifier") ?? .qualifier
        let totalPoints = summary.totalPoints
        let pointsToNext = summary.pointsToNextMilestone ?? 0
        let nextMilestone = summary.nextMilestone ?? "Continue competing"
        
        // Calculate advancement probability (simplified - would use historical data)
        let advancementProbability = calculateAdvancementProbability(totalPoints: totalPoints, currentLevel: currentLevel)
        
        let status: QualificationStatus = {
            if summary.advancementStatus == "qualified" {
                return .qualified
            } else if summary.advancementStatus == "pending" {
                return .pending
            } else {
                return .notQualified
            }
        }()
        
        return AdvancementStatus(
            currentLevel: currentLevel,
            totalPoints: totalPoints,
            pointsToNext: pointsToNext,
            advancementProbability: advancementProbability,
            nextMilestone: nextMilestone,
            status: status
        )
    }
    
    /// Loads all event points for a team
    func loadEventPoints(teamId: UUID, seasonYear: Int?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            var query = supabase
                .from("advancement_points")
                .select()
                .eq("team_id", value: teamId)
            
            if let seasonYear = seasonYear {
                query = query.eq("season_year", value: seasonYear)
            }
            
            let points: [EventPoints] = try await query
                .order("event_date", ascending: false)
                .execute()
                .value
            
            eventPoints = points
        } catch {
            errorMessage = "Failed to load event points: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Calculations
    
    private func determineCurrentLevel(from points: [EventPoints]) -> String {
        // Determine based on event types attended
        if points.contains(where: { $0.eventType == .worlds }) {
            return "worlds"
        } else if points.contains(where: { $0.eventType == .championship }) {
            return "championship"
        } else if points.contains(where: { $0.eventType == .state }) {
            return "state"
        } else {
            return "qualifier"
        }
    }
    
    private func determineAdvancementStatus(totalPoints: Int, currentLevel: String) -> QualificationStatus {
        // Simplified logic - would use actual FTC advancement thresholds
        let thresholds: [String: Int] = [
            "qualifier": 20,
            "state": 40,
            "championship": 60
        ]
        
        if let threshold = thresholds[currentLevel] {
            if totalPoints >= threshold {
                return .qualified
            } else if totalPoints >= Int(Double(threshold) * 0.7) {
                return .pending
            }
        }
        
        return .notQualified
    }
    
    private func calculateNextMilestone(totalPoints: Int, currentLevel: String) -> (String, Int?) {
        let thresholds: [String: Int] = [
            "qualifier": 20,
            "state": 40,
            "championship": 60
        ]
        
        if let threshold = thresholds[currentLevel] {
            let pointsNeeded = max(0, threshold - totalPoints)
            return ("Advance to \(currentLevel.capitalized)", pointsNeeded > 0 ? pointsNeeded : nil)
        }
        
        return ("Continue competing", nil)
    }
    
    private func calculateAdvancementProbability(totalPoints: Int, currentLevel: AdvancementLevel) -> Double {
        // Simplified probability calculation
        // In reality, this would use historical data and statistical models
        let thresholds: [AdvancementLevel: Int] = [
            .qualifier: 20,
            .state: 40,
            .championship: 60
        ]
        
        guard let threshold = thresholds[currentLevel] else {
            return 0.0
        }
        
        if totalPoints >= threshold {
            return 1.0
        } else {
            return Double(totalPoints) / Double(threshold)
        }
    }
}

// MARK: - Error Types

enum AdvancementError: LocalizedError {
    case noData(String)
    case calculationFailed(String)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .noData(let message):
            return "No data available: \(message)"
        case .calculationFailed(let message):
            return "Calculation failed: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
