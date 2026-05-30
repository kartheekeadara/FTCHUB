//
//  ExternalDataRepository.swift
//  FTCHUB
//
//  Orchestrates FTC Scout (primary) and Orange Alliance (OPR fallback) data.
//

import Foundation

@MainActor
final class ExternalDataRepository {
    static let shared = ExternalDataRepository()

    private let scoutAPI = FTCScoutAPIService.shared
    private let toaAPI = OrangeAllianceAPIService.shared
    private let cache = ExternalDataCache.shared

    private init() {}

    // MARK: - Team profile

    func loadTeamProfile(teamNumber: String) async throws -> PublicTeamProfile {
        let cacheKey = "team-profile-v3-\(teamNumber)"
        if let cached: PublicTeamProfile = cache.load(PublicTeamProfile.self, key: cacheKey) {
            return cached
        }

        guard let teamNumberInt = Int(teamNumber) else {
            throw TeamExplorerError.teamNotFound
        }

        let scoutTeamDetail = try await scoutAPI.getTeam(teamNumber: teamNumberInt)
        let seasonsToFetch = FTCSeasonHelper.recentSeasons(count: 4)

        var allStats: [StatisticsService.TeamStatistics] = []
        var allSeasons: [Int] = []
        var allMatches: [PublicMatch] = []
        var allEvents: [ExternalEventParticipation] = []
        var allAwards: [ExternalAward] = []
        var quickStatsBySeason: [Int: FTCScoutQuickStats] = [:]

        for season in seasonsToFetch {
            try await Task.sleep(nanoseconds: 80_000_000)

            async let quickStatsTask = scoutAPI.getTeamQuickStatsREST(teamNumber: teamNumberInt, season: season)
            async let eventsTask = scoutAPI.getTeamEventsREST(teamNumber: teamNumberInt, season: season)
            async let matchesTask = scoutAPI.getTeamMatchesEnriched(teamNumber: teamNumberInt, season: season)
            async let awardsTask = scoutAPI.getTeamAwardsREST(teamNumber: teamNumberInt, season: season)

            let quickStats = try? await quickStatsTask
            let events = (try? await eventsTask) ?? []
            let matches = (try? await matchesTask) ?? []
            let awards = (try? await awardsTask) ?? []

            let hasSeasonData = quickStats != nil || !events.isEmpty || !matches.isEmpty
            guard hasSeasonData else { continue }

            if let quickStats {
                quickStatsBySeason[season] = quickStats
            }

            let eventParticipations = events.map { mapEventParticipation($0, season: season) }
            var enrichedEvents = eventParticipations
            for index in enrichedEvents.indices {
                if enrichedEvents[index].eventName == nil,
                   let detail = try? await scoutAPI.getEventREST(season: season, code: enrichedEvents[index].eventCode) {
                    enrichedEvents[index] = ExternalEventParticipation(
                        season: enrichedEvents[index].season,
                        eventCode: enrichedEvents[index].eventCode,
                        eventName: detail.name,
                        rank: enrichedEvents[index].rank,
                        rankingPoints: enrichedEvents[index].rankingPoints,
                        wins: enrichedEvents[index].wins,
                        losses: enrichedEvents[index].losses,
                        ties: enrichedEvents[index].ties,
                        qualMatchesPlayed: enrichedEvents[index].qualMatchesPlayed,
                        totalPointsOPR: enrichedEvents[index].totalPointsOPR,
                        autoPointsOPR: enrichedEvents[index].autoPointsOPR,
                        dcPointsOPR: enrichedEvents[index].dcPointsOPR,
                        totalPointsAvg: enrichedEvents[index].totalPointsAvg,
                        autoPointsAvg: enrichedEvents[index].autoPointsAvg,
                        dcPointsAvg: enrichedEvents[index].dcPointsAvg
                    )
                }
            }
            allEvents.append(contentsOf: enrichedEvents)

            let seasonMatches = matches.map { convertScoutMatchToPublicMatch($0, teamNumber: teamNumber, season: season) }
            allMatches.append(contentsOf: seasonMatches)

            allAwards.append(contentsOf: awards.map { mapAward($0) })

            var stats = buildSeasonStatistics(
                teamNumber: teamNumber,
                season: season,
                quickStats: quickStats,
                events: eventParticipations,
                matchCount: matches.count
            )

            if needsClassicStatsFallback(stats) {
                if let toaStats = try? await toaAPI.getTeamStats(teamNumber: teamNumber, season: season) {
                    stats = mergeTOAStats(stats, toaStats: toaStats, teamNumber: teamNumber, season: season)
                }
            }

            allStats.append(stats)
            allSeasons.append(season)
        }

        allStats.sort { ($0.seasonYear ?? 0) > ($1.seasonYear ?? 0) }
        allSeasons.sort(by: >)
        allEvents.sort { ($0.season, $0.eventCode) > ($1.season, $1.eventCode) }

        let currentSeason = FTCSeasonHelper.currentSeasonYear
        let profile = PublicTeamProfile(
            teamNumber: teamNumber,
            teamName: scoutTeamDetail.displayName,
            city: scoutTeamDetail.location.city,
            state: scoutTeamDetail.location.state,
            country: scoutTeamDetail.location.country,
            robotName: nil,
            websiteUrl: scoutTeamDetail.website,
            bio: nil,
            currentStatistics: allStats.first,
            recentMatches: allMatches.sorted { $0.scheduledTime > $1.scheduledTime },
            pitScoutingProfiles: [],
            seasons: allSeasons,
            allStatistics: allStats,
            eventParticipations: allEvents,
            awards: dedupeAwards(allAwards),
            statsSource: .ftcScout,
            lastFetchedAt: Date(),
            quickStatsBySeason: quickStatsBySeason
        )

        cache.save(profile, key: cacheKey)
        return profile
    }

    func prefetchQuickStats(teamNumbers: [String], season: Int) async -> [String: FTCScoutQuickStats] {
        var result: [String: FTCScoutQuickStats] = [:]
        for teamNumber in teamNumbers.prefix(10) {
            guard let num = Int(teamNumber) else { continue }
            if let stats = try? await scoutAPI.getTeamQuickStatsREST(teamNumber: num, season: season) {
                result[teamNumber] = stats
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return result
    }

    // MARK: - Mapping helpers

    private func mapEventParticipation(_ event: FTCScoutTeamEventParticipation, season: Int) -> ExternalEventParticipation {
        ExternalEventParticipation(
            season: season,
            eventCode: event.eventCode,
            eventName: nil,
            rank: event.stats?.rank,
            rankingPoints: event.stats?.rp,
            wins: event.stats?.wins ?? 0,
            losses: event.stats?.losses ?? 0,
            ties: event.stats?.ties ?? 0,
            qualMatchesPlayed: event.stats?.qualMatchesPlayed ?? 0,
            totalPointsOPR: event.stats?.opr?.totalPointsNp ?? event.stats?.opr?.totalPoints,
            autoPointsOPR: event.stats?.opr?.autoPoints,
            dcPointsOPR: event.stats?.opr?.dcPoints,
            totalPointsAvg: event.stats?.avg?.totalPointsNp ?? event.stats?.avg?.totalPoints,
            autoPointsAvg: event.stats?.avg?.autoPoints,
            dcPointsAvg: event.stats?.avg?.dcPoints
        )
    }

    private func mapAward(_ award: FTCScoutAward) -> ExternalAward {
        ExternalAward(
            name: award.displayName,
            eventCode: award.eventCode,
            eventName: nil,
            season: award.season,
            teamNumber: award.teamNumber
        )
    }

    private func dedupeAwards(_ awards: [ExternalAward]) -> [ExternalAward] {
        var seen = Set<String>()
        return awards.filter { award in
            guard !seen.contains(award.id) else { return false }
            seen.insert(award.id)
            return true
        }
    }

    private func buildSeasonStatistics(
        teamNumber: String,
        season: Int,
        quickStats: FTCScoutQuickStats?,
        events: [ExternalEventParticipation],
        matchCount: Int
    ) -> StatisticsService.TeamStatistics {
        let totalWins = events.reduce(0) { $0 + $1.wins }
        let totalLosses = events.reduce(0) { $0 + $1.losses }
        let totalTies = events.reduce(0) { $0 + $1.ties }
        let totalPlayed = max(matchCount, events.reduce(0) { $0 + $1.qualMatchesPlayed })
        let winRate: Double? = totalPlayed > 0 ? Double(totalWins) / Double(totalWins + totalLosses + totalTies) : nil

        return StatisticsService.TeamStatistics(
            id: UUID(),
            teamNumber: teamNumber,
            eventName: nil,
            seasonYear: season,
            opr: quickStats?.tot.value,
            dpr: nil,
            ccwm: nil,
            matchesPlayed: totalPlayed,
            wins: totalWins,
            losses: totalLosses,
            ties: totalTies,
            averageScore: quickStats?.tot.value,
            averageAllianceScore: nil,
            averageOpponentScore: nil,
            highestScore: nil,
            lowestScore: nil,
            averageAutoScore: quickStats?.auto.value,
            averageTeleopScore: quickStats?.dc.value,
            averageEndgameScore: quickStats?.eg.value,
            winRate: winRate,
            consistencyScore: nil,
            oprRank: quickStats?.tot.rank,
            ccwmRank: nil,
            winRateRank: nil,
            lastCalculatedAt: Date(),
            calculationMethod: "ftc_scout_api",
            matchesUsed: totalPlayed
        )
    }

    private func needsClassicStatsFallback(_ stats: StatisticsService.TeamStatistics) -> Bool {
        stats.opr == nil && stats.dpr == nil && stats.ccwm == nil
    }

    private func mergeTOAStats(
        _ base: StatisticsService.TeamStatistics,
        toaStats: TOATeamStats,
        teamNumber: String,
        season: Int
    ) -> StatisticsService.TeamStatistics {
        StatisticsService.TeamStatistics(
            id: base.id,
            teamNumber: teamNumber,
            eventName: base.eventName,
            seasonYear: season,
            opr: toaStats.opr ?? base.opr,
            dpr: toaStats.dpr ?? base.dpr,
            ccwm: toaStats.ccwm ?? base.ccwm,
            matchesPlayed: toaStats.matchesPlayed ?? base.matchesPlayed,
            wins: toaStats.wins ?? base.wins,
            losses: toaStats.losses ?? base.losses,
            ties: toaStats.ties ?? base.ties,
            averageScore: toaStats.averageScore ?? base.averageScore,
            averageAllianceScore: base.averageAllianceScore,
            averageOpponentScore: base.averageOpponentScore,
            highestScore: toaStats.highestScore ?? base.highestScore,
            lowestScore: toaStats.lowestScore ?? base.lowestScore,
            averageAutoScore: toaStats.averageAutoScore ?? base.averageAutoScore,
            averageTeleopScore: toaStats.averageTeleopScore ?? base.averageTeleopScore,
            averageEndgameScore: toaStats.averageEndgameScore ?? base.averageEndgameScore,
            winRate: toaStats.winRate ?? base.winRate,
            consistencyScore: base.consistencyScore,
            oprRank: base.oprRank,
            ccwmRank: base.ccwmRank,
            winRateRank: base.winRateRank,
            lastCalculatedAt: Date(),
            calculationMethod: toaStats.opr != nil ? "orange_alliance_api" : base.calculationMethod,
            matchesUsed: toaStats.matchesPlayed ?? base.matchesUsed
        )
    }

    func convertScoutMatchToPublicMatch(_ scoutMatch: FTCScoutMatchDetail, teamNumber: String, season: Int) -> PublicMatch {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var scheduledTime: Date?
        if let eventStart = scoutMatch.eventStartDate {
            let eventDateFormatter = DateFormatter()
            eventDateFormatter.dateFormat = "yyyy-MM-dd"
            eventDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            scheduledTime = eventDateFormatter.date(from: eventStart)
        }
        if scheduledTime == nil, let matchTime = scoutMatch.scheduledStartTime {
            scheduledTime = dateFormatter.date(from: matchTime)
        }
        let finalScheduledTime = scheduledTime ?? Date.distantPast

        let allianceColor: AllianceColor = scoutMatch.alliance.uppercased() == "RED" ? .red : .blue
        let matchKey = "\(scoutMatch.eventCode)-\(scoutMatch.matchNum)"
        let matchKeyHash = matchKey.hash
        let uuidString = String(format: "%08x-0000-0000-0000-%012x", matchKeyHash, abs(matchKeyHash))
        let matchId = UUID(uuidString: uuidString) ?? UUID()

        let formattedNumber = MatchDisplayFormatter.label(
            matchId: scoutMatch.matchNum,
            tournamentLevel: scoutMatch.tournamentLevel,
            series: scoutMatch.series
        )

        return PublicMatch(
            id: matchId,
            matchNumber: formattedNumber,
            scheduledTime: finalScheduledTime,
            eventName: scoutMatch.eventName ?? scoutMatch.eventCode,
            seasonYear: season,
            allianceColor: allianceColor,
            redAllianceScore: scoutMatch.redScore,
            blueAllianceScore: scoutMatch.blueScore,
            redTeams: scoutMatch.redTeams.map(String.init),
            blueTeams: scoutMatch.blueTeams.map(String.init),
            status: scoutMatch.hasBeenPlayed ? .completed : .scheduled
        )
    }
}
