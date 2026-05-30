//
//  TeamExplorerService.swift
//  FTCHUB
//
//  Phase 2: Team Explorer Service
//  Service to handle searching, browsing, and fetching public team data
//  Updated: Removed dependency on non-existent views, using direct table queries
//

import Foundation
import Combine
import Supabase

@MainActor
class TeamExplorerService: ObservableObject {
    @Published var searchResults: [PublicTeamProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTeam: PublicTeamProfile?
    
    private let supabase = SupabaseService.shared.client
    private let ftcScoutAPI = FTCScoutAPIService.shared
    private let externalData = ExternalDataRepository.shared
    
    // Search teams by number, name, location - using FTC Scout API
    func searchTeams(query: String, filters: TeamSearchFilters? = nil) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Try FTC Scout API first
        if !query.isEmpty {
            do {
                let scoutTeams = try await ftcScoutAPI.searchTeams(query: query, limit: 50)
                
                var profiles: [PublicTeamProfile] = []
                for scoutTeam in scoutTeams {
                    let profile = PublicTeamProfile(
                        teamNumber: scoutTeam.teamNumberString,
                        teamName: scoutTeam.displayName,
                        city: scoutTeam.location.city,
                        state: scoutTeam.location.state,
                        country: scoutTeam.location.country,
                        robotName: nil,
                        websiteUrl: scoutTeam.website,
                        bio: nil,
                        currentStatistics: nil,
                        recentMatches: [],
                        pitScoutingProfiles: [],
                        seasons: [],
                        allStatistics: [],
                        eventParticipations: [],
                        awards: [],
                        statsSource: .ftcScout,
                        lastFetchedAt: nil,
                        quickStatsBySeason: [:]
                    )
                    profiles.append(profile)
                }
                
                searchResults = profiles
                
                // Prefetch quick stats for top results
                let season = filters?.seasonYear ?? FTCSeasonHelper.currentSeasonYear
                let prefetch = await externalData.prefetchQuickStats(
                    teamNumbers: profiles.prefix(10).map(\.teamNumber),
                    season: season
                )
                if !prefetch.isEmpty {
                    searchResults = profiles.map { profile in
                        guard let stats = prefetch[profile.teamNumber] else { return profile }
                        let teamStats = StatisticsService.TeamStatistics(
                            id: UUID(),
                            teamNumber: profile.teamNumber,
                            eventName: nil,
                            seasonYear: season,
                            opr: stats.tot.value,
                            dpr: nil,
                            ccwm: nil,
                            matchesPlayed: 0,
                            wins: 0,
                            losses: 0,
                            ties: 0,
                            averageScore: stats.tot.value,
                            averageAllianceScore: nil,
                            averageOpponentScore: nil,
                            highestScore: nil,
                            lowestScore: nil,
                            averageAutoScore: stats.auto.value,
                            averageTeleopScore: stats.dc.value,
                            averageEndgameScore: stats.eg.value,
                            winRate: nil,
                            consistencyScore: nil,
                            oprRank: stats.tot.rank,
                            ccwmRank: nil,
                            winRateRank: nil,
                            lastCalculatedAt: Date(),
                            calculationMethod: "ftc_scout_api",
                            matchesUsed: nil
                        )
                        return PublicTeamProfile(
                            teamNumber: profile.teamNumber,
                            teamName: profile.teamName,
                            city: profile.city,
                            state: profile.state,
                            country: profile.country,
                            robotName: profile.robotName,
                            websiteUrl: profile.websiteUrl,
                            bio: profile.bio,
                            currentStatistics: teamStats,
                            recentMatches: profile.recentMatches,
                            pitScoutingProfiles: profile.pitScoutingProfiles,
                            seasons: [season],
                            allStatistics: [teamStats],
                            eventParticipations: profile.eventParticipations,
                            awards: profile.awards,
                            statsSource: .ftcScout,
                            lastFetchedAt: Date(),
                            quickStatsBySeason: [season: stats]
                        )
                    }
                }
                return
            } catch let error as FTCScoutError {
                // Ignore cancellation errors (expected with debounced search)
                if case .cancelled = error {
                    return
                }
                // For other errors, show error message (don't fall back to local database)
                errorMessage = "Failed to search teams: \(error.localizedDescription)"
                searchResults = []
            } catch {
                // Show error message (don't fall back to local database to avoid fake data)
                errorMessage = "Failed to search teams: \(error.localizedDescription)"
                searchResults = []
            }
        } else {
            // Empty query - clear results
            searchResults = []
        }
    }
    
    // Get team profile with full details via ExternalDataRepository
    func getTeamProfile(teamNumber: String) async throws -> PublicTeamProfile {
        return try await externalData.loadTeamProfile(teamNumber: teamNumber)
    }
    
    // Get team match history - using matches table directly
    func getTeamMatchHistory(teamNumber: String, seasonYear: Int?, eventName: String?, limit: Int = 50) async throws -> [PublicMatch] {
        // First get team_id from team number
        let teamResponse: [TeamRecord] = try await supabase
            .from("teams")
            .select("id")
            .eq("number", value: teamNumber)
            .limit(1)
            .execute()
            .value
        
        guard let teamId = teamResponse.first?.id else {
            return []
        }
        
        // Query matches table - note: matches table stores per-team perspective
        let queryBuilder = supabase
            .from("matches")
            .select("*")
            .eq("team_id", value: teamId.uuidString)
        
        // Note: season_year and event_name might not be in matches table directly
        // We'll need to join or filter by scheduled_time if needed
        
        let response: [MatchRecord] = try await queryBuilder
            .order("scheduled_time", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        // Convert to PublicMatch format
        return response.map { record in
            // Build alliance teams (this is approximate since matches table structure is per-team)
            let redTeams = [teamNumber] // Simplified - actual structure would need joins
            let blueTeams: [String] = [] // Would need to fetch from alliance_partner fields
            
            return PublicMatch(
                id: record.id,
                matchNumber: record.matchNumber,
                scheduledTime: record.scheduledTime,
                eventName: record.location, // Using location as event name fallback
                seasonYear: seasonYear ?? Calendar.current.component(.year, from: record.scheduledTime),
                allianceColor: AllianceColor(rawValue: record.allianceColor.lowercased()) ?? .red,
                redAllianceScore: record.allianceColor.lowercased() == "red" ? record.ourScore : record.opponentScore,
                blueAllianceScore: record.allianceColor.lowercased() == "blue" ? record.ourScore : record.opponentScore,
                redTeams: redTeams,
                blueTeams: blueTeams,
                status: MatchStatus(rawValue: record.status) ?? .scheduled
            )
        }
    }
    
    // Get team statistics for specific event/season
    func getTeamStatistics(teamNumber: String, seasonYear: Int?, eventName: String?) async throws -> StatisticsService.TeamStatistics? {
        var queryBuilder = supabase
            .from("team_statistics")
            .select("*")
            .eq("team_number", value: teamNumber)
        
        if let seasonYear = seasonYear {
            queryBuilder = queryBuilder.eq("season_year", value: seasonYear)
        }
        if let eventName = eventName, !eventName.isEmpty {
            queryBuilder = queryBuilder.eq("event_name", value: eventName)
        }
        
        let response: [TeamStatisticsRecord] = try await queryBuilder
            .order("season_year", ascending: false)
            .order("last_calculated_at", ascending: false)
            .limit(1)
            .execute()
            .value
        
        return response.first.flatMap { StatisticsService.TeamStatistics(from: $0) }
    }
    
    // Get leaderboards (OPR, CCWM, Win Rate) - using team_statistics joined with teams
    func getLeaderboard(metric: LeaderboardMetric, seasonYear: Int?, eventName: String?, limit: Int = 10) async throws -> [LeaderboardEntry] {
        // Query team_statistics table
        var queryBuilder = supabase
            .from("team_statistics")
            .select("team_number, opr, dpr, ccwm, matches_played, wins, losses, ties, win_rate, average_score, season_year, event_name")
            .neq("matches_played", value: 0)
        
        if let seasonYear = seasonYear {
            queryBuilder = queryBuilder.eq("season_year", value: seasonYear)
        }
        if let eventName = eventName, !eventName.isEmpty {
            queryBuilder = queryBuilder.eq("event_name", value: eventName)
        }
        
        // Order by metric
        let orderColumn: String
        switch metric {
        case .opr:
            orderColumn = "opr"
        case .ccwm:
            orderColumn = "ccwm"
        case .winRate:
            orderColumn = "win_rate"
        case .averageScore:
            orderColumn = "average_score"
        }
        
        let statsResponse: [TeamStatisticsRecord] = try await queryBuilder
            .order(orderColumn, ascending: false)
            .limit(limit * 2) // Get more to filter for public teams
            .execute()
            .value
        
        // Fetch team names for public teams only
        var entries: [LeaderboardEntry] = []
        var processed = 0
        
        for stats in statsResponse {
            guard processed < limit else { break }
            
            // Check if team is public
            let teamResponse: [TeamRecord] = try await supabase
                .from("teams")
                .select("number, name, is_public")
                .eq("number", value: stats.teamNumber)
                .eq("is_public", value: true)
                .limit(1)
                .execute()
                .value
            
            guard let teamRecord = teamResponse.first else {
                continue // Skip non-public teams
            }
            
            guard let value = getMetricValue(from: stats, metric: metric) else {
                continue
            }
            
            entries.append(LeaderboardEntry(
                rank: processed + 1,
                teamNumber: stats.teamNumber,
                teamName: teamRecord.name,
                value: value,
                matchesPlayed: stats.matchesPlayed
            ))
            
            processed += 1
        }
        
        return entries
    }
    
    // Get pit scouting profiles (public)
    func getPitScoutingProfiles(teamNumber: String) async throws -> [PitScoutingService.RobotProfile] {
        // Find team_id from team number
        let teamResponse: [TeamRecord] = try await supabase
            .from("teams")
            .select("id")
            .eq("number", value: teamNumber)
            .limit(1)
            .execute()
            .value
        
        guard let teamId = teamResponse.first?.id else {
            return []
        }
        
        // Fetch public pit scouting reports
        _ = try await supabase
            .from("scouting_reports")
            .select("*")
            .eq("team_id", value: teamId.uuidString)
            .eq("is_pit_scouting", value: true)
            .eq("is_current_profile", value: true)
            .limit(5)
            .execute()
            .value
        
        // Convert to RobotProfile (using PitScoutingService logic)
        // For now, return empty array - will be enhanced in Phase 3
        // TODO: Parse pit_scouting_data JSONB and convert to RobotProfile
        return []
    }
    
    // Helper function to get metric value from TeamStatisticsRecord
    private func getMetricValue(from record: TeamStatisticsRecord, metric: LeaderboardMetric) -> Double? {
        switch metric {
        case .opr:
            return record.opr
        case .ccwm:
            return record.ccwm
        case .winRate:
            return record.winRate
        case .averageScore:
            return record.averageScore
        }
    }
    
    // MARK: - Orange Alliance API Conversion Helpers
    
    /// Convert TOA stats to StatisticsService.TeamStatistics
    private func convertTOAStatsToTeamStatistics(_ toaStats: TOATeamStats, teamNumber: String) -> StatisticsService.TeamStatistics {
        // Create a TeamStatisticsRecord first, then convert using the extension
        let statsRecord = TeamStatisticsRecord(
            id: UUID(),
            teamNumber: teamNumber,
            eventName: toaStats.eventKey,
            seasonYear: toaStats.seasonKey.flatMap { extractYearFromSeasonKey($0) },
            opr: toaStats.opr ?? 0.0, // Provide default if nil
            dpr: toaStats.dpr ?? 0.0, // Provide default if nil
            ccwm: toaStats.ccwm ?? 0.0, // Provide default if nil
            matchesPlayed: toaStats.matchesPlayed ?? 0,
            wins: toaStats.wins ?? 0,
            losses: toaStats.losses ?? 0,
            ties: toaStats.ties ?? 0,
            averageScore: toaStats.averageScore,
            averageAllianceScore: nil,
            averageOpponentScore: nil,
            highestScore: toaStats.highestScore,
            lowestScore: toaStats.lowestScore,
            averageAutoScore: toaStats.averageAutoScore,
            averageTeleopScore: toaStats.averageTeleopScore,
            averageEndgameScore: toaStats.averageEndgameScore,
            winRate: toaStats.winRate,
            consistencyScore: nil,
            oprRank: nil,
            ccwmRank: nil,
            winRateRank: nil,
            lastCalculatedAt: Date(),
            calculationMethod: "orange_alliance_api",
            matchesUsed: toaStats.matchesPlayed
        )
        
        // Use the extension to convert - it should always succeed since we provide defaults
        guard let stats = StatisticsService.TeamStatistics(from: statsRecord) else {
            // This should never happen since we provide defaults, but handle it gracefully
            fatalError("Failed to create TeamStatistics from TOA stats")
        }
        return stats
    }
    
    /// Convert TOA match to PublicMatch
    private func convertTOAMatchToPublicMatch(_ toaMatch: TOAMatch, teamNumber: String) -> PublicMatch {
        // Determine alliance color by checking which alliance contains the team
        let teamNumberString = teamNumber
        
        var allianceColor: AllianceColor = .red // Default
        if let redTeams = toaMatch.redTeams, redTeams.contains(teamNumberString) || redTeams.contains(where: { $0.contains(teamNumberString) }) {
            allianceColor = .red
        } else if let blueTeams = toaMatch.blueTeams, blueTeams.contains(teamNumberString) || blueTeams.contains(where: { $0.contains(teamNumberString) }) {
            allianceColor = .blue
        }
        
        // Generate UUID from matchKey (create a deterministic UUID)
        let matchKeyHash = toaMatch.matchKey.hash
        let uuidString = String(format: "%08x-0000-0000-0000-%012x", matchKeyHash, abs(matchKeyHash))
        let matchId = UUID(uuidString: uuidString) ?? UUID()
        
        return PublicMatch(
            id: matchId,
            matchNumber: toaMatch.matchNumber,
            scheduledTime: toaMatch.scheduledDate ?? Date(),
            eventName: toaMatch.eventKey,
            seasonYear: nil, // Would need to extract from eventKey
            allianceColor: allianceColor,
            redAllianceScore: toaMatch.redScore,
            blueAllianceScore: toaMatch.blueScore,
            redTeams: toaMatch.redTeams ?? [],
            blueTeams: toaMatch.blueTeams ?? [],
            status: .completed // TOA matches are completed
        )
    }
    
    /// Extract year from season key (e.g., "2324" -> 2024)
    private func extractYearFromSeasonKey(_ seasonKey: String) -> Int? {
        guard seasonKey.count >= 4,
              let firstTwo = Int(seasonKey.prefix(2)) else {
            return nil
        }
        return 2000 + firstTwo
    }
    
    // MARK: - FTC Scout API Conversion Helpers
    
    /// Convert FTC Scout match detail to PublicMatch (with full alliance info)
    private func convertFTCScoutMatchDetailToPublicMatch(_ scoutMatch: FTCScoutMatchDetail, teamNumber: String, season: Int) -> PublicMatch {
        // Parse event start date (preferred) or match scheduled time
        // Use event start date as it's more accurate than match scheduled times
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try event start date first (most accurate)
        var scheduledTime: Date? = nil
        if let eventStart = scoutMatch.eventStartDate {
            // Event dates are in YYYY-MM-DD format
            let eventDateFormatter = DateFormatter()
            eventDateFormatter.dateFormat = "yyyy-MM-dd"
            eventDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            scheduledTime = eventDateFormatter.date(from: eventStart)
        }
        
        // Fallback to match scheduled time if event date not available
        if scheduledTime == nil, let matchTime = scoutMatch.scheduledStartTime {
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            scheduledTime = dateFormatter.date(from: matchTime)
        }
        
        // Only use current date as last resort if we have NO date information
        // This prevents showing incorrect dates for matches
        let finalScheduledTime = scheduledTime ?? Date.distantPast // Use distantPast instead of Date() to avoid showing today's date incorrectly
        
        // Determine alliance color
        let allianceColor: AllianceColor = scoutMatch.alliance.uppercased() == "RED" ? .red : .blue
        
        // Generate deterministic UUID from match info
        let matchKey = "\(scoutMatch.eventCode)-\(scoutMatch.matchNum)"
        let matchKeyHash = matchKey.hash
        let uuidString = String(format: "%08x-0000-0000-0000-%012x", matchKeyHash, abs(matchKeyHash))
        let matchId = UUID(uuidString: uuidString) ?? UUID()
        
        // Convert team numbers to strings
        let redTeamsStrings = scoutMatch.redTeams.map { String($0) }
        let blueTeamsStrings = scoutMatch.blueTeams.map { String($0) }
        
        // Format match number based on tournament level
        let matchNumberPrefix: String
        if let level = scoutMatch.tournamentLevel {
            if level.uppercased().contains("PLAYOFF") || level.uppercased().contains("ELIM") {
                matchNumberPrefix = "M"
            } else {
                matchNumberPrefix = "Q"
            }
        } else {
            matchNumberPrefix = "Q" // Default to qualification
        }
        let formattedMatchNumber = "\(matchNumberPrefix)-\(scoutMatch.matchNum)"
        
        return PublicMatch(
            id: matchId,
            matchNumber: formattedMatchNumber,
            scheduledTime: finalScheduledTime,
            eventName: scoutMatch.eventName ?? scoutMatch.eventCode, // Use event name if available, fallback to code
            seasonYear: season, // Use the season parameter passed from the API call
            allianceColor: allianceColor,
            redAllianceScore: scoutMatch.redScore,
            blueAllianceScore: scoutMatch.blueScore,
            redTeams: redTeamsStrings,
            blueTeams: blueTeamsStrings,
            status: scoutMatch.hasBeenPlayed ? .completed : .scheduled
        )
    }
    
    /// Convert FTC Scout match to PublicMatch (simplified version for backward compatibility)
    private func convertFTCScoutMatchToPublicMatch(_ scoutMatch: FTCScoutMatch, teamNumber: String) -> PublicMatch {
        // Parse scheduled time
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let scheduledTime = scoutMatch.scheduledStartTime.flatMap { dateFormatter.date(from: $0) } ?? Date()
        
        // Determine alliance color
        let allianceColor: AllianceColor = scoutMatch.alliance.uppercased() == "RED" ? .red : .blue
        
        // Generate deterministic UUID from match info
        let matchKey = "\(scoutMatch.eventCode)-\(scoutMatch.matchNum)"
        let matchKeyHash = matchKey.hash
        let uuidString = String(format: "%08x-0000-0000-0000-%012x", matchKeyHash, abs(matchKeyHash))
        let matchId = UUID(uuidString: uuidString) ?? UUID()
        
        return PublicMatch(
            id: matchId,
            matchNumber: String(scoutMatch.matchNum),
            scheduledTime: scheduledTime,
            eventName: scoutMatch.eventCode,
            seasonYear: nil,
            allianceColor: allianceColor,
            redAllianceScore: nil,
            blueAllianceScore: nil,
            redTeams: [],
            blueTeams: [],
            status: scoutMatch.hasBeenPlayed ? .completed : .scheduled
        )
    }
    
    /// Convert FTC Scout stats to StatisticsService.TeamStatistics
    /// Note: FTC Scout QuickStats has different structure - uses value/rank instead of mean/max/min/stdev
    /// IMPORTANT: scoutStats.count is the TOTAL number of matches in the database, NOT the team's match count
    /// We need to fetch the actual match count separately
    private func convertFTCScoutStatsToTeamStatistics(_ scoutStats: FTCScoutQuickStats, teamNumber: String, actualMatchCount: Int? = nil) -> StatisticsService.TeamStatistics {
        // Use actual match count if provided, otherwise we can't determine it from quickStats
        // The count field in quickStats is misleading - it's the total database count, not team-specific
        let matchCount = actualMatchCount ?? 0 // Will be updated when we fetch matches
        
        // FTC Scout provides: tot.value (total score average), auto.value, dc.value, eg.value
        // We'll map these to our structure, setting OPR/DPR/CCWM to nil since FTC Scout doesn't provide them directly
        return StatisticsService.TeamStatistics(
            id: UUID(),
            teamNumber: teamNumber,
            eventName: nil,
            seasonYear: scoutStats.season,
            opr: nil, // FTC Scout doesn't provide OPR directly
            dpr: nil, // FTC Scout doesn't provide DPR directly
            ccwm: nil, // FTC Scout doesn't provide CCWM directly
            matchesPlayed: matchCount, // Use actual match count, not scoutStats.count
            wins: 0, // Not available in QuickStats
            losses: 0, // Not available in QuickStats
            ties: 0, // Not available in QuickStats
            averageScore: scoutStats.tot.value, // tot.value is the average total score
            averageAllianceScore: nil,
            averageOpponentScore: nil,
            highestScore: nil, // Not available in QuickStats (only value, not max)
            lowestScore: nil, // Not available in QuickStats (only value, not min)
            averageAutoScore: scoutStats.auto.value, // auto.value is the average auto score
            averageTeleopScore: scoutStats.dc.value, // dc.value is the average driver controlled (teleop) score
            averageEndgameScore: scoutStats.eg.value, // eg.value is the average endgame score
            winRate: nil, // Not available in QuickStats
            consistencyScore: nil, // Not available (no stdev)
            oprRank: nil,
            ccwmRank: nil,
            winRateRank: nil,
            lastCalculatedAt: Date(),
            calculationMethod: "ftc_scout_api",
            matchesUsed: matchCount
        )
    }
}

// MARK: - Data Models

struct PublicTeamProfile: Identifiable, Codable {
    let id: String // team_number
    let teamNumber: String
    let teamName: String
    let city: String?
    let state: String?
    let country: String
    let robotName: String?
    let websiteUrl: String?
    let bio: String?
    let currentStatistics: StatisticsService.TeamStatistics?
    let recentMatches: [PublicMatch]
    let pitScoutingProfiles: [PitScoutingService.RobotProfile]
    let seasons: [Int]
    let allStatistics: [StatisticsService.TeamStatistics]
    let eventParticipations: [ExternalEventParticipation]
    let awards: [ExternalAward]
    let statsSource: ExternalDataSource
    let lastFetchedAt: Date?
    let quickStatsBySeason: [Int: FTCScoutQuickStats]
    
    init(
        teamNumber: String,
        teamName: String,
        city: String?,
        state: String?,
        country: String,
        robotName: String?,
        websiteUrl: String?,
        bio: String?,
        currentStatistics: StatisticsService.TeamStatistics?,
        recentMatches: [PublicMatch],
        pitScoutingProfiles: [PitScoutingService.RobotProfile],
        seasons: [Int],
        allStatistics: [StatisticsService.TeamStatistics],
        eventParticipations: [ExternalEventParticipation] = [],
        awards: [ExternalAward] = [],
        statsSource: ExternalDataSource = .ftcScout,
        lastFetchedAt: Date? = nil,
        quickStatsBySeason: [Int: FTCScoutQuickStats] = [:]
    ) {
        self.id = teamNumber
        self.teamNumber = teamNumber
        self.teamName = teamName
        self.city = city
        self.state = state
        self.country = country
        self.robotName = robotName
        self.websiteUrl = websiteUrl
        self.bio = bio
        self.currentStatistics = currentStatistics
        self.recentMatches = recentMatches
        self.pitScoutingProfiles = pitScoutingProfiles
        self.seasons = seasons
        self.allStatistics = allStatistics
        self.eventParticipations = eventParticipations
        self.awards = awards
        self.statsSource = statsSource
        self.lastFetchedAt = lastFetchedAt
        self.quickStatsBySeason = quickStatsBySeason
    }
    
    func quickStats(for season: Int) -> FTCScoutQuickStats? {
        quickStatsBySeason[season]
    }
}

struct PublicMatch: Identifiable, Codable {
    let id: UUID
    let matchNumber: String
    let scheduledTime: Date
    let eventName: String?
    let seasonYear: Int?
    let allianceColor: AllianceColor
    let redAllianceScore: Int?
    let blueAllianceScore: Int?
    let redTeams: [String]
    let blueTeams: [String]
    let status: MatchStatus
    
    var winningTeam: String? {
        guard let redScore = redAllianceScore, let blueScore = blueAllianceScore else { return nil }
        return redScore > blueScore ? "red" : (blueScore > redScore ? "blue" : nil)
    }
    
    var didWin: Bool? {
        guard let winningTeam = winningTeam else { return nil }
        return winningTeam == allianceColor.rawValue
    }
}

struct LeaderboardEntry: Identifiable, Codable {
    let id: String // "rank-teamNumber"
    let rank: Int
    let teamNumber: String
    let teamName: String
    let value: Double // OPR, CCWM, or Win Rate
    let matchesPlayed: Int
    
    init(rank: Int, teamNumber: String, teamName: String, value: Double, matchesPlayed: Int) {
        self.id = "\(rank)-\(teamNumber)"
        self.rank = rank
        self.teamNumber = teamNumber
        self.teamName = teamName
        self.value = value
        self.matchesPlayed = matchesPlayed
    }
}

enum LeaderboardMetric: String, CaseIterable {
    case opr = "OPR"
    case ccwm = "CCWM"
    case winRate = "Win Rate"
    case averageScore = "Average Score"
}

struct TeamSearchFilters {
    let seasonYear: Int?
    let eventName: String?
    let state: String?
    let country: String?
    let region: String?
    let minMatchesPlayed: Int?
    
    init(seasonYear: Int? = nil, eventName: String? = nil, state: String? = nil, country: String? = nil, region: String? = nil, minMatchesPlayed: Int? = nil) {
        self.seasonYear = seasonYear
        self.eventName = eventName
        self.state = state
        self.country = country
        self.region = region
        self.minMatchesPlayed = minMatchesPlayed
    }
}

// MARK: - Database Record Types

private struct TeamRecord: Codable {
    let id: UUID
    let name: String
    let number: String
    let city: String?
    let state: String?
    let country: String?
    let robotName: String?
    let websiteUrl: String?
    let bio: String?
    let isPublic: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, number, city, state, country
        case robotName = "robot_name"
        case websiteUrl = "website_url"
        case bio
        case isPublic = "is_public"
    }
}

private struct TeamStatisticsRecord: Codable {
    let id: UUID
    let teamNumber: String
    let eventName: String?
    let seasonYear: Int?
    let opr: Double?
    let dpr: Double?
    let ccwm: Double?
    let matchesPlayed: Int
    let wins: Int
    let losses: Int
    let ties: Int
    let averageScore: Double?
    let averageAllianceScore: Double?
    let averageOpponentScore: Double?
    let highestScore: Int?
    let lowestScore: Int?
    let averageAutoScore: Double?
    let averageTeleopScore: Double?
    let averageEndgameScore: Double?
    let winRate: Double?
    let consistencyScore: Double?
    let oprRank: Int?
    let ccwmRank: Int?
    let winRateRank: Int?
    let lastCalculatedAt: Date
    let calculationMethod: String
    let matchesUsed: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamNumber = "team_number"
        case eventName = "event_name"
        case seasonYear = "season_year"
        case opr, dpr, ccwm
        case matchesPlayed = "matches_played"
        case wins, losses, ties
        case averageScore = "average_score"
        case averageAllianceScore = "average_alliance_score"
        case averageOpponentScore = "average_opponent_score"
        case highestScore = "highest_score"
        case lowestScore = "lowest_score"
        case averageAutoScore = "average_auto_score"
        case averageTeleopScore = "average_teleop_score"
        case averageEndgameScore = "average_endgame_score"
        case winRate = "win_rate"
        case consistencyScore = "consistency_score"
        case oprRank = "opr_rank"
        case ccwmRank = "ccwm_rank"
        case winRateRank = "win_rate_rank"
        case lastCalculatedAt = "last_calculated_at"
        case calculationMethod = "calculation_method"
        case matchesUsed = "matches_used"
    }
}

private struct MatchRecord: Codable {
    let id: UUID
    let matchNumber: String
    let scheduledTime: Date
    let allianceColor: String
    let alliancePartner1: Int?
    let alliancePartner2: Int?
    let opponent1: Int?
    let opponent2: Int?
    let opponent3: Int?
    let status: String
    let ourScore: Int?
    let opponentScore: Int?
    let location: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchNumber = "match_number"
        case scheduledTime = "scheduled_time"
        case allianceColor = "alliance_color"
        case alliancePartner1 = "alliance_partner_1"
        case alliancePartner2 = "alliance_partner_2"
        case opponent1 = "opponent_1"
        case opponent2 = "opponent_2"
        case opponent3 = "opponent_3"
        case status
        case ourScore = "our_score"
        case opponentScore = "opponent_score"
        case location
    }
}

private struct ScoutingReportRecord: Codable {
    let id: UUID
    let teamId: UUID
    let pitScoutingData: String? // JSONB stored as JSON string
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case pitScoutingData = "pit_scouting_data"
    }
}

// MARK: - Team Statistics Extension

extension StatisticsService.TeamStatistics {
    fileprivate init?(from record: TeamStatisticsRecord) {
        guard let opr = record.opr, let dpr = record.dpr, let ccwm = record.ccwm else {
            return nil
        }
        
        self.init(
            id: record.id,
            teamNumber: record.teamNumber,
            eventName: record.eventName,
            seasonYear: record.seasonYear,
            opr: opr,
            dpr: dpr,
            ccwm: ccwm,
            matchesPlayed: record.matchesPlayed,
            wins: record.wins,
            losses: record.losses,
            ties: record.ties,
            averageScore: record.averageScore,
            averageAllianceScore: record.averageAllianceScore,
            averageOpponentScore: record.averageOpponentScore,
            highestScore: record.highestScore,
            lowestScore: record.lowestScore,
            averageAutoScore: record.averageAutoScore,
            averageTeleopScore: record.averageTeleopScore,
            averageEndgameScore: record.averageEndgameScore,
            winRate: record.winRate,
            consistencyScore: record.consistencyScore,
            oprRank: record.oprRank,
            ccwmRank: record.ccwmRank,
            winRateRank: record.winRateRank,
            lastCalculatedAt: record.lastCalculatedAt,
            calculationMethod: record.calculationMethod,
            matchesUsed: record.matchesUsed
        )
    }
}

// MARK: - Errors

enum TeamExplorerError: LocalizedError {
    case teamNotFound
    case invalidQuery
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .teamNotFound:
            return "Team not found or not publicly visible"
        case .invalidQuery:
            return "Invalid search query"
        case .networkError:
            return "Network error occurred"
        }
    }
}
