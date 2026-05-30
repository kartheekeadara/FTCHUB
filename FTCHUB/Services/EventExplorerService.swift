//
//  EventExplorerService.swift
//  FTCHUB
//
//  Event search and intelligence via FTC Scout REST API.
//

import Foundation
import Combine

@MainActor
final class EventExplorerService: ObservableObject {
    static let shared = EventExplorerService()

    @Published var searchResults: [ExternalEventSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let scoutAPI = FTCScoutAPIService.shared
    private let cache = ExternalDataCache.shared

    private init() {}

    func searchEvents(query: String, season: Int? = nil, region: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let seasonYear = season ?? FTCSeasonHelper.currentSeasonYear
        do {
            let events = try await scoutAPI.searchEventsREST(
                season: seasonYear,
                searchText: query.isEmpty ? nil : query,
                region: region,
                limit: 50
            )
            searchResults = events.map { mapEventSummary($0) }
        } catch {
            errorMessage = "Failed to search events: \(error.localizedDescription)"
            searchResults = []
        }
    }

    func loadEventDetail(season: Int, code: String) async throws -> ExternalEventSummary {
        let cacheKey = "event-detail-v2-\(season)-\(code)"
        if let cached: ExternalEventSummary = cache.load(ExternalEventSummary.self, key: cacheKey) {
            return cached
        }
        let event = try await scoutAPI.getEventREST(season: season, code: code)
        let summary = mapEventSummary(event)
        cache.save(summary, key: cacheKey)
        return summary
    }

    func loadEventRankings(season: Int, eventCode: String) async throws -> [ExternalEventTeamRanking] {
        let cacheKey = "event-rankings-v2-\(season)-\(eventCode)"
        if let cached: [ExternalEventTeamRanking] = cache.load([ExternalEventTeamRanking].self, key: cacheKey) {
            return cached
        }

        let teams = try await scoutAPI.getEventTeamsREST(season: season, eventCode: eventCode)
        var rankings: [ExternalEventTeamRanking] = teams.map { participation in
            ExternalEventTeamRanking(
                teamNumber: participation.teamNumber,
                teamName: nil,
                rank: participation.stats?.rank,
                rankingPoints: participation.stats?.rp,
                wins: participation.stats?.wins ?? 0,
                losses: participation.stats?.losses ?? 0,
                ties: participation.stats?.ties ?? 0,
                qualMatchesPlayed: participation.stats?.qualMatchesPlayed ?? 0,
                totalPointsOPR: participation.stats?.opr?.totalPointsNp ?? participation.stats?.opr?.totalPoints,
                autoPointsOPR: participation.stats?.opr?.autoPoints,
                dcPointsOPR: participation.stats?.opr?.dcPoints,
                totalPointsAvg: participation.stats?.avg?.totalPointsNp ?? participation.stats?.avg?.totalPoints,
                autoPointsAvg: participation.stats?.avg?.autoPoints,
                dcPointsAvg: participation.stats?.avg?.dcPoints
            )
        }

        rankings.sort { ($0.rank ?? Int.max) < ($1.rank ?? Int.max) }
        cache.save(rankings, key: cacheKey)
        return rankings
    }

    func loadEventMatches(season: Int, eventCode: String) async throws -> [ExternalEventMatch] {
        let cacheKey = "event-matches-v3-\(season)-\(eventCode)"
        if let cached: [ExternalEventMatch] = cache.load([ExternalEventMatch].self, key: cacheKey) {
            return cached
        }

        let matches = try await scoutAPI.getEventMatchesREST(season: season, eventCode: eventCode)
        let mapped = matches.map { match -> ExternalEventMatch in
            let matchId = match.resolvedMatchId
            let redTeams = match.teams.filter { $0.alliance.uppercased() == "RED" }.map(\.teamNumber)
            let blueTeams = match.teams.filter { $0.alliance.uppercased() == "BLUE" }.map(\.teamNumber)
            return ExternalEventMatch(
                season: season,
                eventCode: eventCode,
                matchId: matchId,
                matchNumber: MatchDisplayFormatter.label(
                    matchId: matchId,
                    tournamentLevel: match.tournamentLevel,
                    series: match.series
                ),
                tournamentLevel: match.tournamentLevel,
                scheduledStartTime: match.scheduledStartTime,
                hasBeenPlayed: match.hasBeenPlayed,
                redScore: match.scores?.red?.totalPoints,
                blueScore: match.scores?.blue?.totalPoints,
                redTeams: redTeams,
                blueTeams: blueTeams
            )
        }.sorted { $0.matchId < $1.matchId }

        cache.save(mapped, key: cacheKey)
        return mapped
    }

    func loadEventAwards(season: Int, eventCode: String) async throws -> [ExternalAward] {
        let awards = try await scoutAPI.getEventAwardsREST(season: season, eventCode: eventCode)
        return awards.map {
            ExternalAward(
                name: $0.displayName,
                eventCode: eventCode,
                eventName: nil,
                season: season,
                teamNumber: $0.teamNumber
            )
        }
    }

    private func mapEventSummary(_ event: FTCScoutEventREST) -> ExternalEventSummary {
        ExternalEventSummary(
            season: event.season,
            code: event.code,
            name: event.name,
            eventType: event.type,
            city: event.city,
            state: event.state,
            country: event.country,
            startDate: event.start,
            endDate: event.end,
            venue: event.venue,
            liveStreamURL: event.liveStreamURL,
            hasMatches: event.hasMatches ?? false
        )
    }
}
