//
//  FTCScoutAPIService.swift
//  FTCHUB
//
//  FTC Scout GraphQL API Service
//  Fetches team data from FTC Scout (ftcscout.org) GraphQL API
//

import Foundation

@MainActor
class FTCScoutAPIService {
    static let shared = FTCScoutAPIService()
    
    private let baseURL = "https://api.ftcscout.org/graphql"
    let restBaseURL = "https://api.ftcscout.org/rest/v1"
    let session = URLSession.shared
    private let decoder: JSONDecoder
    let restDecoder: JSONDecoder
    
    // Cache for API responses
    private var teamCache: [Int: CachedTeamData] = [:]
    private var searchCache: [String: [FTCScoutTeam]] = [:]
    private var searchCacheTimestamps: [String: Date] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    
    // Rate limiting
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 0.2 // 200ms between requests
    
    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        restDecoder = JSONDecoder()
        restDecoder.dateDecodingStrategy = .iso8601
        restDecoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Team Search
    
    /// Search for teams by number, name, or location
    func searchTeams(query: String, limit: Int = 50) async throws -> [FTCScoutTeam] {
        // Check cache first
        let cacheKey = query.lowercased()
        if let cached = searchCache[cacheKey],
           let cacheTime = searchCacheTimestamps[cacheKey],
           Date().timeIntervalSince(cacheTime) < cacheExpiration {
            return cached
        }
        
        await rateLimit()
        
        let sanitizedQuery = Self.escapeGraphQLString(query)
        let safeLimit = max(1, min(limit, 100))
        
        // GraphQL query for team search
        let graphQLQuery = """
        {
            teamsSearch(searchText: "\(sanitizedQuery)", limit: \(safeLimit)) {
                number
                name
                schoolName
                location {
                    city
                    state
                    country
                }
                website
                rookieYear
            }
        }
        """
        
        let response = try await performGraphQLQuery(query: graphQLQuery, responseType: TeamsSearchResponse.self)
        let teams = response.data.teamsSearch
        
        // Cache results
        searchCache[cacheKey] = teams
        searchCacheTimestamps[cacheKey] = Date()
        
        return teams
    }
    
    /// Get team details by team number
    func getTeam(teamNumber: Int) async throws -> FTCScoutTeamDetail {
        // Check cache first
        if let cached = teamCache[teamNumber],
           Date().timeIntervalSince(cached.cachedAt) < cacheExpiration {
            return cached.teamDetail
        }
        
        await rateLimit()
        
        // GraphQL query for team details
        let graphQLQuery = """
        {
            teamByNumber(number: \(teamNumber)) {
                number
                name
                schoolName
                location {
                    city
                    state
                    country
                    venue
                }
                website
                rookieYear
            }
        }
        """
        
        let response = try await performGraphQLQuery(query: graphQLQuery, responseType: TeamByNumberResponse.self)
        
        guard let team = response.data.teamByNumber else {
            throw FTCScoutError.teamNotFound
        }
        
        // Cache result
        teamCache[teamNumber] = CachedTeamData(teamDetail: team, cachedAt: Date())
        
        return team
    }
    
    /// Get team matches for a specific season with full details (scores, all teams)
    func getTeamMatches(teamNumber: Int, season: Int) async throws -> [FTCScoutMatchDetail] {
        await rateLimit()
        
        // GraphQL query for team matches with full details including event names
        // Note: scores structure varies by season, so we'll decode manually
        let graphQLQuery = """
        {
            teamByNumber(number: \(teamNumber)) {
                matches(season: \(season)) {
                    match {
                        matchNum
                        eventCode
                        tournamentLevel
                        scheduledStartTime
                        hasBeenPlayed
                        scores {
                            ... on MatchScores2024 {
                                red { totalPoints }
                                blue { totalPoints }
                            }
                            ... on MatchScores2025 {
                                red { totalPoints }
                                blue { totalPoints }
                            }
                        }
                        event {
                            name
                            code
                            location {
                                city
                                state
                                country
                            }
                        }
                        teams {
                            teamNumber
                            alliance
                        }
                    }
                    alliance
                    eventCode
                }
            }
        }
        """
        
        // Use raw JSON decoding to handle the union type for scores
        guard let url = URL(string: baseURL) else {
            throw FTCScoutError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0
        
        let requestBody: [String: Any] = ["query": graphQLQuery]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FTCScoutError.invalidResponse
        }
        if HTTPRateLimitHelper.isRateLimited(httpResponse.statusCode) {
            throw FTCScoutError.rateLimited(
                retryAfterSeconds: HTTPRateLimitHelper.retryAfterSeconds(from: httpResponse)
            )
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw FTCScoutError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Decode manually to handle union types
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let dataDict = json?["data"] as? [String: Any],
              let teamDict = dataDict["teamByNumber"] as? [String: Any],
              let matchesArray = teamDict["matches"] as? [[String: Any]] else {
            return []
        }
        
        var result: [FTCScoutMatchDetail] = []
        for matchParticipation in matchesArray {
            guard let matchDict = matchParticipation["match"] as? [String: Any],
                  let matchNum = matchDict["matchNum"] as? Int,
                  let eventCode = (matchDict["eventCode"] as? String) ?? (matchParticipation["eventCode"] as? String),
                  let alliance = matchParticipation["alliance"] as? String else {
                continue
            }
            
            // Extract scores
            var redScore: Int? = nil
            var blueScore: Int? = nil
            if let scores = matchDict["scores"] as? [String: Any] {
                if let redData = scores["red"] as? [String: Any],
                   let redTotal = redData["totalPoints"] as? Int {
                    redScore = redTotal
                }
                if let blueData = scores["blue"] as? [String: Any],
                   let blueTotal = blueData["totalPoints"] as? Int {
                    blueScore = blueTotal
                }
            }
            
            // Extract teams by alliance
            var redTeams: [Int] = []
            var blueTeams: [Int] = []
            if let teams = matchDict["teams"] as? [[String: Any]] {
                for team in teams {
                    if let teamNum = team["teamNumber"] as? Int,
                       let teamAlliance = team["alliance"] as? String {
                        if teamAlliance.uppercased() == "RED" {
                            redTeams.append(teamNum)
                        } else if teamAlliance.uppercased() == "BLUE" {
                            blueTeams.append(teamNum)
                        }
                    }
                }
            }
            
            // Extract event name and start date
            var eventName: String? = nil
            var eventStartDate: String? = nil
            if let event = matchDict["event"] as? [String: Any] {
                if let name = event["name"] as? String {
                    eventName = name
                }
                if let start = event["start"] as? String {
                    eventStartDate = start
                }
            }
            
            result.append(FTCScoutMatchDetail(
                matchNum: matchNum,
                eventCode: eventCode,
                eventName: eventName,
                eventStartDate: eventStartDate,
                tournamentLevel: matchDict["tournamentLevel"] as? String,
                scheduledStartTime: matchDict["scheduledStartTime"] as? String,
                hasBeenPlayed: matchDict["hasBeenPlayed"] as? Bool ?? false,
                alliance: alliance,
                redScore: redScore,
                blueScore: blueScore,
                redTeams: redTeams,
                blueTeams: blueTeams
            ))
        }
        
        return result
    }
    
    /// Get team quick stats for a specific season
    func getTeamStats(teamNumber: Int, season: Int) async throws -> FTCScoutQuickStats? {
        await rateLimit()
        
        // GraphQL query for team stats
        let graphQLQuery = """
        {
            teamByNumber(number: \(teamNumber)) {
                number
                quickStats(season: \(season)) {
                    season
                    number
                    tot {
                        value
                        rank
                    }
                    auto {
                        value
                        rank
                    }
                    dc {
                        value
                        rank
                    }
                    eg {
                        value
                        rank
                    }
                    count
                }
            }
        }
        """
        
        let response = try await performGraphQLQuery(query: graphQLQuery, responseType: TeamStatsResponse.self)
        
        return response.data.teamByNumber?.quickStats
    }
    
    // MARK: - Helper Methods
    
    private static func escapeGraphQLString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
    
    private func performGraphQLQuery<T: Decodable>(query: String, responseType: T.Type) async throws -> T {
        guard let url = URL(string: baseURL) else {
            throw FTCScoutError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0
        
        // Create GraphQL request body
        let requestBody: [String: Any] = [
            "query": query
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            var lastRateLimitRetry = 60
            var data: Data!
            var httpResponse: HTTPURLResponse!
            
            for attempt in 0..<2 {
                let (responseData, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw FTCScoutError.invalidResponse
                }
                if HTTPRateLimitHelper.isRateLimited(http.statusCode), attempt == 0 {
                    lastRateLimitRetry = HTTPRateLimitHelper.retryAfterSeconds(from: http)
                    try await Task.sleep(nanoseconds: UInt64(lastRateLimitRetry) * 1_000_000_000)
                    continue
                }
                data = responseData
                httpResponse = http
                break
            }
            
            if HTTPRateLimitHelper.isRateLimited(httpResponse.statusCode) {
                throw FTCScoutError.rateLimited(retryAfterSeconds: lastRateLimitRetry)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw FTCScoutError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // Check for GraphQL errors
            if let errorResponse = try? decoder.decode(GraphQLErrorResponse.self, from: data),
               let errors = errorResponse.errors, !errors.isEmpty {
                let errorMessage = errors.first?.message ?? "Unknown GraphQL error"
                DebugLog.log("FTC Scout API GraphQL error: \(errorMessage)")
                // Check if it's a "not found" error - but don't throw for null quickStats
                if errors.contains(where: { $0.message.contains("not found") && !$0.message.contains("quickStats") }) {
                    throw FTCScoutError.teamNotFound
                }
                // For quickStats errors, we'll return nil instead of throwing
                if errorMessage.contains("quickStats") || errorMessage.contains("Cannot query field") {
                    // This is a query structure error, not a data error
                    DebugLog.log("FTC Scout API: QuickStats query structure error - returning nil")
                    // Return a dummy response that will decode to nil quickStats
                    // We'll handle this at the call site
                }
                throw FTCScoutError.graphQLError(errorMessage)
            }
            
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch let error as DecodingError {
            DebugLog.log("FTC Scout API decoding error: \(error)")
            throw FTCScoutError.decodingError(error.localizedDescription)
        } catch let ftcError as FTCScoutError {
            throw ftcError
        } catch {
            // Check if it's a cancellation error
            if let urlError = error as? URLError, urlError.code == .cancelled {
                throw FTCScoutError.cancelled
            }
            throw FTCScoutError.networkError(error.localizedDescription)
        }
    }
    
    func rateLimit() async {
        if let lastTime = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastTime)
            if timeSinceLastRequest < minRequestInterval {
                let delay = minRequestInterval - timeSinceLastRequest
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
    
    func clearCache() {
        teamCache.removeAll()
        searchCache.removeAll()
        searchCacheTimestamps.removeAll()
    }
}

// MARK: - Data Models

struct FTCScoutTeam: Codable, Identifiable {
    let number: Int
    let name: String
    let schoolName: String?
    let location: FTCScoutLocation
    let website: String?
    let rookieYear: Int?
    
    var id: String { String(number) }
    
    var teamNumberString: String {
        String(number)
    }
    
    var displayName: String {
        name
    }
}

struct FTCScoutTeamDetail: Codable {
    let number: Int
    let name: String
    let schoolName: String?
    let location: FTCScoutLocation
    let website: String?
    let rookieYear: Int?
    
    var teamNumberString: String {
        String(number)
    }
    
    var displayName: String {
        name
    }
}

struct FTCScoutLocation: Codable {
    let city: String
    let state: String
    let country: String
    let venue: String?
}

struct FTCScoutQuickStats: Codable {
    let season: Int
    let number: Int
    let tot: FTCScoutStatValue
    let auto: FTCScoutStatValue
    let dc: FTCScoutStatValue
    let eg: FTCScoutStatValue
    let count: Int
}

struct FTCScoutStatValue: Codable {
    let value: Double?
    let rank: Int?
}

struct FTCScoutMatch: Codable, Identifiable {
    let matchNum: Int
    let eventCode: String
    let tournamentLevel: String?
    let scheduledStartTime: String?
    let hasBeenPlayed: Bool
    let alliance: String // "RED" or "BLUE"
    
    var id: String {
        "\(eventCode)-\(matchNum)"
    }
}

struct FTCScoutMatchDetail: Codable, Identifiable {
    let matchNum: Int
    let eventCode: String
    let eventName: String?
    let eventStartDate: String? // Event start date (more accurate than match scheduled time)
    let tournamentLevel: String?
    let scheduledStartTime: String?
    let hasBeenPlayed: Bool
    let alliance: String // "RED" or "BLUE"
    let redScore: Int?
    let blueScore: Int?
    let redTeams: [Int]
    let blueTeams: [Int]
    let formattedMatchNumber: String?
    let series: Int?
    
    var id: String {
        "\(eventCode)-\(matchNum)"
    }
    
    init(
        matchNum: Int,
        eventCode: String,
        eventName: String?,
        eventStartDate: String?,
        tournamentLevel: String?,
        scheduledStartTime: String?,
        hasBeenPlayed: Bool,
        alliance: String,
        redScore: Int?,
        blueScore: Int?,
        redTeams: [Int],
        blueTeams: [Int],
        formattedMatchNumber: String? = nil,
        series: Int? = nil
    ) {
        self.matchNum = matchNum
        self.eventCode = eventCode
        self.eventName = eventName
        self.eventStartDate = eventStartDate
        self.tournamentLevel = tournamentLevel
        self.scheduledStartTime = scheduledStartTime
        self.hasBeenPlayed = hasBeenPlayed
        self.alliance = alliance
        self.redScore = redScore
        self.blueScore = blueScore
        self.redTeams = redTeams
        self.blueTeams = blueTeams
        self.formattedMatchNumber = formattedMatchNumber
        self.series = series
    }
}

struct FTCScoutMatchParticipation: Codable {
    let match: FTCScoutMatchData?
    let alliance: String
    let eventCode: String
}

struct FTCScoutMatchData: Codable {
    let matchNum: Int
    let eventCode: String?
    let tournamentLevel: String?
    let scheduledStartTime: String?
    let hasBeenPlayed: Bool
}

// MARK: - GraphQL Response Models

private struct TeamsSearchResponse: Codable {
    let data: TeamsSearchData
}

private struct TeamsSearchData: Codable {
    let teamsSearch: [FTCScoutTeam]
}

private struct TeamByNumberResponse: Codable {
    let data: TeamByNumberData
}

private struct TeamByNumberData: Codable {
    let teamByNumber: FTCScoutTeamDetail?
}

private struct TeamStatsResponse: Codable {
    let data: TeamStatsData
}

private struct TeamStatsData: Codable {
    let teamByNumber: TeamWithStats?
}

private struct TeamWithStats: Codable {
    let number: Int
    let quickStats: FTCScoutQuickStats?
}

private struct TeamMatchesResponse: Codable {
    let data: TeamMatchesData
}

private struct TeamMatchesData: Codable {
    let teamByNumber: TeamWithMatches?
}

private struct TeamWithMatches: Codable {
    let matches: [FTCScoutMatchParticipation]
}

private struct GraphQLErrorResponse: Codable {
    let errors: [GraphQLError]?
}

private struct GraphQLError: Codable {
    let message: String
    let locations: [GraphQLErrorLocation]?
}

private struct GraphQLErrorLocation: Codable {
    let line: Int
    let column: Int
}

// MARK: - Cache Structure

private struct CachedTeamData {
    let teamDetail: FTCScoutTeamDetail
    let cachedAt: Date
}

// MARK: - Errors

enum FTCScoutError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case rateLimited(retryAfterSeconds: Int)
    case graphQLError(String)
    case decodingError(String)
    case networkError(String)
    case teamNotFound
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid API response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .rateLimited(let seconds):
            return "Too many requests. Please try again in \(seconds) seconds."
        case .graphQLError(let message):
            return "GraphQL error: \(message)"
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .teamNotFound:
            return "Team not found"
        case .cancelled:
            return "Request cancelled"
        }
    }
}
