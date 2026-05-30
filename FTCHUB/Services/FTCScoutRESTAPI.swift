//
//  FTCScoutRESTAPI.swift
//  FTCHUB
//
//  FTC Scout REST API client (api.ftcscout.org/rest/v1)
//

import Foundation

extension FTCScoutAPIService {
    // MARK: - REST: Team endpoints

    func getTeamQuickStatsREST(teamNumber: Int, season: Int, region: String? = nil) async throws -> FTCScoutQuickStats? {
        var path = "/teams/\(teamNumber)/quick-stats?season=\(season)"
        if let region, !region.isEmpty {
            path += "&region=\(region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? region)"
        }
        do {
            return try await performRESTRequest(path: path, responseType: FTCScoutQuickStats.self)
        } catch FTCScoutError.teamNotFound {
            return nil
        }
    }

    func getTeamEventsREST(teamNumber: Int, season: Int) async throws -> [FTCScoutTeamEventParticipation] {
        let path = "/teams/\(teamNumber)/events/\(season)"
        return try await performRESTRequest(path: path, responseType: [FTCScoutTeamEventParticipation].self, emptyArrayOn404: true)
    }

    func getTeamAwardsREST(teamNumber: Int, season: Int? = nil, eventCode: String? = nil) async throws -> [FTCScoutAward] {
        var path = "/teams/\(teamNumber)/awards"
        var query: [String] = []
        if let season { query.append("season=\(season)") }
        if let eventCode { query.append("eventCode=\(eventCode)") }
        if !query.isEmpty { path += "?" + query.joined(separator: "&") }
        return try await performRESTRequest(path: path, responseType: [FTCScoutAward].self, emptyArrayOn404: true)
    }

    func getTeamMatchParticipationsREST(teamNumber: Int, season: Int) async throws -> [FTCScoutTeamMatchParticipationREST] {
        let path = "/teams/\(teamNumber)/matches?season=\(season)"
        return try await performRESTRequest(path: path, responseType: [FTCScoutTeamMatchParticipationREST].self, emptyArrayOn404: true)
    }

    /// Builds full match details by joining team participations with event-level match data (scores + alliances).
    func getTeamMatchesEnriched(teamNumber: Int, season: Int) async throws -> [FTCScoutMatchDetail] {
        let participations = try await getTeamMatchParticipationsREST(teamNumber: teamNumber, season: season)
        guard !participations.isEmpty else { return [] }

        let eventCodes = Set(participations.map(\.eventCode))
        var eventMatchesByKey: [String: FTCScoutEventMatchREST] = [:]
        var eventNames: [String: String] = [:]

        for eventCode in eventCodes {
            let matches = try await getEventMatchesREST(season: season, eventCode: eventCode)
            for match in matches {
                eventMatchesByKey["\(eventCode)-\(match.resolvedMatchId)"] = match
            }
            if let event = try? await getEventREST(season: season, code: eventCode) {
                eventNames[eventCode] = event.name
            }
        }

        var results: [FTCScoutMatchDetail] = []
        for participation in participations {
            let key = "\(participation.eventCode)-\(participation.matchId)"
            guard let eventMatch = eventMatchesByKey[key] else { continue }

            let alliance = participation.alliance.uppercased()
            let redTeams = eventMatch.teams.filter { $0.alliance.uppercased() == "RED" }.map(\.teamNumber)
            let blueTeams = eventMatch.teams.filter { $0.alliance.uppercased() == "BLUE" }.map(\.teamNumber)

            let prefix: String
            if let level = eventMatch.tournamentLevel?.uppercased() {
                prefix = level.contains("PLAYOFF") || level.contains("ELIM") ? "M" : "Q"
            } else {
                prefix = participation.matchId >= 1000 ? "M" : "Q"
            }

            results.append(FTCScoutMatchDetail(
                matchNum: participation.matchId,
                eventCode: participation.eventCode,
                eventName: eventNames[participation.eventCode],
                eventStartDate: nil,
                tournamentLevel: eventMatch.tournamentLevel,
                scheduledStartTime: eventMatch.scheduledStartTime,
                hasBeenPlayed: eventMatch.hasBeenPlayed,
                alliance: alliance,
                redScore: eventMatch.scores?.red?.totalPoints,
                blueScore: eventMatch.scores?.blue?.totalPoints,
                redTeams: redTeams,
                blueTeams: blueTeams,
                formattedMatchNumber: MatchDisplayFormatter.label(
                    matchId: participation.matchId,
                    tournamentLevel: eventMatch.tournamentLevel,
                    series: eventMatch.series
                ),
                series: eventMatch.series
            ))
        }

        return results
    }

    // MARK: - REST: Event endpoints

    func searchEventsREST(season: Int, searchText: String? = nil, region: String? = nil, type: String? = nil, limit: Int = 50) async throws -> [FTCScoutEventREST] {
        var path = "/events/search/\(season)?limit=\(max(1, min(limit, 100)))"
        if let searchText, !searchText.isEmpty {
            let encoded = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchText
            path += "&searchText=\(encoded)"
        }
        if let region, !region.isEmpty {
            path += "&region=\(region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? region)"
        }
        if let type, !type.isEmpty {
            path += "&type=\(type.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? type)"
        }
        return try await performRESTRequest(path: path, responseType: [FTCScoutEventREST].self, emptyArrayOn404: true)
    }

    func getEventREST(season: Int, code: String) async throws -> FTCScoutEventREST {
        let path = "/events/\(season)/\(code)"
        return try await performRESTRequest(path: path, responseType: FTCScoutEventREST.self)
    }

    func getEventTeamsREST(season: Int, eventCode: String) async throws -> [FTCScoutTeamEventParticipation] {
        let path = "/events/\(season)/\(eventCode)/teams"
        return try await performRESTRequest(path: path, responseType: [FTCScoutTeamEventParticipation].self, emptyArrayOn404: true)
    }

    func getEventMatchesREST(season: Int, eventCode: String) async throws -> [FTCScoutEventMatchREST] {
        let path = "/events/\(season)/\(eventCode)/matches"
        return try await performRESTRequest(path: path, responseType: [FTCScoutEventMatchREST].self, emptyArrayOn404: true)
    }

    func getEventAwardsREST(season: Int, eventCode: String) async throws -> [FTCScoutAward] {
        let path = "/events/\(season)/\(eventCode)/awards"
        return try await performRESTRequest(path: path, responseType: [FTCScoutAward].self, emptyArrayOn404: true)
    }

    func searchTeamsREST(searchText: String? = nil, region: String? = nil, limit: Int = 50) async throws -> [FTCScoutTeam] {
        var path = "/teams/search?limit=\(max(1, min(limit, 100)))"
        if let searchText, !searchText.isEmpty {
            let encoded = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchText
            path += "&searchText=\(encoded)"
        }
        if let region, !region.isEmpty {
            path += "&region=\(region.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? region)"
        }
        return try await performRESTRequest(path: path, responseType: [FTCScoutTeam].self, emptyArrayOn404: true)
    }

    // MARK: - REST internals

    func performRESTRequest<T: Decodable>(
        path: String,
        responseType: T.Type,
        emptyArrayOn404: Bool = false
    ) async throws -> T {
        await rateLimit()

        guard let url = URL(string: restBaseURL + path) else {
            throw FTCScoutError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0

        var retryAfter = 60
        for attempt in 0..<2 {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw FTCScoutError.invalidResponse
            }
            if HTTPRateLimitHelper.isRateLimited(http.statusCode) {
                retryAfter = HTTPRateLimitHelper.retryAfterSeconds(from: http)
                if attempt == 0 {
                    try await Task.sleep(nanoseconds: UInt64(retryAfter) * 1_000_000_000)
                    continue
                }
                throw FTCScoutError.rateLimited(retryAfterSeconds: retryAfter)
            }
            if http.statusCode == 404 {
                if emptyArrayOn404, let empty = decodeEmptyJSONArray(as: T.self, data: data) {
                    return empty
                }
                throw FTCScoutError.teamNotFound
            }
            guard (200...299).contains(http.statusCode) else {
                throw FTCScoutError.httpError(statusCode: http.statusCode)
            }
            do {
                return try restDecoder.decode(T.self, from: data)
            } catch let error as DecodingError {
                DebugLog.log("FTC Scout REST decoding error for \(path): \(error)")
                throw FTCScoutError.decodingError(error.localizedDescription)
            }
        }
        throw FTCScoutError.rateLimited(retryAfterSeconds: retryAfter)
    }

    private func decodeEmptyJSONArray<T: Decodable>(as type: T.Type, data: Data) -> T? {
        guard let empty = try? restDecoder.decode(T.self, from: Data("[]".utf8)) else {
            return nil
        }
        return empty
    }
}

// MARK: - REST Models

struct FTCScoutTeamEventParticipation: Codable {
    let season: Int
    let eventCode: String
    let teamNumber: Int
    let isRemote: Bool?
    let stats: FTCScoutEventTeamStats?
}

struct FTCScoutEventTeamStats: Codable {
    let rank: Int?
    let rp: Double?
    let wins: Int?
    let losses: Int?
    let ties: Int?
    let qualMatchesPlayed: Int?
    let tot: FTCScoutScoreBreakdown?
    let avg: FTCScoutScoreBreakdown?
    let opr: FTCScoutScoreBreakdown?

    enum CodingKeys: String, CodingKey {
        case rank, rp, wins, losses, ties, qualMatchesPlayed, tot, avg, opr
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rank = try container.decodeIfPresent(Int.self, forKey: .rank)
        rp = container.decodeFlexibleDouble(forKey: .rp)
        wins = try container.decodeIfPresent(Int.self, forKey: .wins)
        losses = try container.decodeIfPresent(Int.self, forKey: .losses)
        ties = try container.decodeIfPresent(Int.self, forKey: .ties)
        qualMatchesPlayed = try container.decodeIfPresent(Int.self, forKey: .qualMatchesPlayed)
        tot = try container.decodeIfPresent(FTCScoutScoreBreakdown.self, forKey: .tot)
        avg = try container.decodeIfPresent(FTCScoutScoreBreakdown.self, forKey: .avg)
        opr = try container.decodeIfPresent(FTCScoutScoreBreakdown.self, forKey: .opr)
    }
}

struct FTCScoutScoreBreakdown: Codable {
    let autoPoints: Double?
    let dcPoints: Double?
    let totalPoints: Double?
    let totalPointsNp: Double?

    enum CodingKeys: String, CodingKey {
        case autoPoints, dcPoints, totalPoints, totalPointsNp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        autoPoints = container.decodeFlexibleDouble(forKey: .autoPoints)
        dcPoints = container.decodeFlexibleDouble(forKey: .dcPoints)
        totalPoints = container.decodeFlexibleDouble(forKey: .totalPoints)
        totalPointsNp = container.decodeFlexibleDouble(forKey: .totalPointsNp)
    }
}

struct FTCScoutAward: Codable, Identifiable {
    let season: Int?
    let eventCode: String?
    let teamNumber: Int?
    let type: String?
    let placement: Int?
    let divisionName: String?

    var displayName: String {
        if let type {
            if let placement {
                return "\(type) (#\(placement))"
            }
            return type
        }
        return "Award"
    }

    var id: String {
        "\(season ?? 0)-\(eventCode ?? "")-\(teamNumber ?? 0)-\(displayName)"
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) -> Double? {
        if let value = try? decode(Double.self, forKey: key) { return value }
        if let value = try? decode(Int.self, forKey: key) { return Double(value) }
        return nil
    }
}

struct FTCScoutTeamMatchParticipationREST: Codable {
    let season: Int
    let eventCode: String
    let matchId: Int
    let alliance: String
    let teamNumber: Int
}

struct FTCScoutEventREST: Codable {
    let season: Int
    let code: String
    let name: String
    let type: String?
    let city: String?
    let state: String?
    let country: String?
    let start: String?
    let end: String?
    let venue: String?
    let liveStreamURL: String?
    let hasMatches: Bool?
    let regionCode: String?
}

struct FTCScoutEventMatchREST: Codable {
    let eventSeason: Int?
    let eventCode: String?
    let id: Int?
    let matchId: Int?
    let hasBeenPlayed: Bool
    let scheduledStartTime: String?
    let tournamentLevel: String?
    let series: Int?
    let scores: FTCScoutEventMatchScores?
    let teams: [FTCScoutEventMatchTeam]

    var resolvedMatchId: Int {
        matchId ?? id ?? 0
    }
}

struct FTCScoutEventMatchScores: Codable {
    let red: FTCScoutAllianceScore?
    let blue: FTCScoutAllianceScore?
}

struct FTCScoutAllianceScore: Codable {
    let totalPoints: Int?
}

struct FTCScoutEventMatchTeam: Codable {
    let teamNumber: Int
    let alliance: String
    let allianceRole: String?
}
