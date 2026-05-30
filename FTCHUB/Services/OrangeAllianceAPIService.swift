//
//  OrangeAllianceAPIService.swift
//  FTCHUB
//
//  Orange Alliance API Service
//  Fetches team data from The Orange Alliance (theorangealliance.org) API
//

import Foundation

@MainActor
class OrangeAllianceAPIService {
    static let shared = OrangeAllianceAPIService()
    
    private let baseURL = "https://theorangealliance.org/api"
    private let session = URLSession.shared
    private let decoder: JSONDecoder
    
    // Cache for API responses
    private var teamCache: [String: CachedTeamData] = [:]
    private var searchCache: [String: TOASearchCacheEntry] = [:]
    private let cacheExpiration: TimeInterval = 3600 // 1 hour
    
    // Rate limiting
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 0.1 // 100ms between requests
    
    private init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Team Search
    
    /// Search for teams by number, name, or location
    func searchTeams(query: String, limit: Int = 50) async throws -> [TOATeam] {
        let cacheKey = query.lowercased()
        if let entry = searchCache[cacheKey],
           Date().timeIntervalSince(entry.cachedAt) < cacheExpiration {
            return entry.teams
        }
        
        await rateLimit()
        
        guard let url = URL(string: "\(baseURL)/teams") else {
            throw TOAError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "team_key", value: query),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let finalURL = components?.url else {
            throw TOAError.invalidURL
        }
        
        var request = configuredRequest(url: finalURL)
        
        do {
            let data = try await fetchData(for: request, emptyArrayOn404: true)
            let teams = try decoder.decode([TOATeam].self, from: data)
            
            // Cache results
            searchCache[cacheKey] = TOASearchCacheEntry(teams: teams, cachedAt: Date())
            
            return teams
        } catch let error as DecodingError {
            DebugLog.log("Orange Alliance API decoding error: \(error)")
            throw TOAError.decodingError(error.localizedDescription)
        } catch {
            throw TOAError.networkError(error.localizedDescription)
        }
    }
    
    /// Get team details by team number
    func getTeam(teamNumber: String) async throws -> TOATeamDetail {
        // Check cache first
        if let cached = teamCache[teamNumber], 
           Date().timeIntervalSince(cached.cachedAt) < cacheExpiration {
            return cached.teamDetail
        }
        
        await rateLimit()
        
        guard let url = URL(string: "\(baseURL)/team/\(teamNumber)") else {
            throw TOAError.invalidURL
        }
        
        var request = configuredRequest(url: url)
        
        do {
            let data = try await fetchData(for: request)
            let teamDetail = try decoder.decode(TOATeamDetail.self, from: data)
            
            // Cache result
            teamCache[teamNumber] = CachedTeamData(teamDetail: teamDetail, cachedAt: Date())
            
            return teamDetail
        } catch let error as DecodingError {
            DebugLog.log("Orange Alliance API decoding error: \(error)")
            throw TOAError.decodingError(error.localizedDescription)
        } catch let toaError as TOAError {
            throw toaError
        } catch {
            throw TOAError.networkError(error.localizedDescription)
        }
    }
    
    /// Get team events
    func getTeamEvents(teamNumber: String, season: Int? = nil) async throws -> [TOAEvent] {
        await rateLimit()
        
        var urlString = "\(baseURL)/team/\(teamNumber)/events"
        if let season = season {
            urlString += "/\(season)"
        }
        
        guard let url = URL(string: urlString) else {
            throw TOAError.invalidURL
        }
        
        var request = configuredRequest(url: url)
        
        do {
            let data = try await fetchData(for: request, emptyArrayOn404: true)
            let events = try decoder.decode([TOAEvent].self, from: data)
            return events
        } catch let error as DecodingError {
            DebugLog.log("Orange Alliance API decoding error: \(error)")
            throw TOAError.decodingError(error.localizedDescription)
        } catch {
            throw TOAError.networkError(error.localizedDescription)
        }
    }
    
    /// Get team matches
    func getTeamMatches(teamNumber: String, eventKey: String? = nil, season: Int? = nil) async throws -> [TOAMatch] {
        await rateLimit()
        
        var urlString = "\(baseURL)/team/\(teamNumber)/matches"
        if let eventKey = eventKey {
            urlString += "/\(eventKey)"
        } else if let season = season {
            urlString += "/\(season)"
        }
        
        guard let url = URL(string: urlString) else {
            throw TOAError.invalidURL
        }
        
        var request = configuredRequest(url: url)
        
        do {
            let data = try await fetchData(for: request, emptyArrayOn404: true)
            let matches = try decoder.decode([TOAMatch].self, from: data)
            return matches
        } catch let error as DecodingError {
            DebugLog.log("Orange Alliance API decoding error: \(error)")
            throw TOAError.decodingError(error.localizedDescription)
        } catch {
            throw TOAError.networkError(error.localizedDescription)
        }
    }
    
    /// Get team statistics
    func getTeamStats(teamNumber: String, eventKey: String? = nil, season: Int? = nil) async throws -> TOATeamStats? {
        await rateLimit()
        
        var urlString = "\(baseURL)/team/\(teamNumber)/stats"
        if let eventKey = eventKey {
            urlString += "/\(eventKey)"
        } else if let season = season {
            urlString += "/\(season)"
        }
        
        guard let url = URL(string: urlString) else {
            throw TOAError.invalidURL
        }
        
        var request = configuredRequest(url: url)
        
        do {
            let data = try await fetchData(for: request)
            let stats = try decoder.decode(TOATeamStats.self, from: data)
            return stats
        } catch TOAError.teamNotFound {
            return nil
        } catch let error as DecodingError {
            DebugLog.log("Orange Alliance API decoding error: \(error)")
            throw TOAError.decodingError(error.localizedDescription)
        } catch {
            throw TOAError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    private func configuredRequest(url: URL, timeout: TimeInterval = 10.0) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let apiKey = Secrets.optionalValue(.orangeAllianceAPIKey), !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-TOA-KEY")
        }
        request.timeoutInterval = timeout
        return request
    }
    
    /// HTTP fetch with graceful 429 handling (one retry using Retry-After).
    private func fetchData(
        for request: URLRequest,
        emptyArrayOn404: Bool = false
    ) async throws -> Data {
        var retryAfter = 60
        for attempt in 0..<2 {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TOAError.invalidResponse
            }
            if HTTPRateLimitHelper.isRateLimited(httpResponse.statusCode) {
                retryAfter = HTTPRateLimitHelper.retryAfterSeconds(from: httpResponse)
                if attempt == 0 {
                    try await Task.sleep(nanoseconds: UInt64(retryAfter) * 1_000_000_000)
                    continue
                }
                throw TOAError.rateLimited(retryAfterSeconds: retryAfter)
            }
            if httpResponse.statusCode == 404 {
                if emptyArrayOn404 {
                    return Data("[]".utf8)
                }
                throw TOAError.teamNotFound
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw TOAError.httpError(statusCode: httpResponse.statusCode)
            }
            return data
        }
        throw TOAError.rateLimited(retryAfterSeconds: retryAfter)
    }
    
    private func rateLimit() async {
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
    }
}

// MARK: - Data Models

struct TOATeam: Codable, Identifiable {
    let teamKey: String
    let teamNumber: Int
    let teamNameShort: String?
    let teamNameLong: String?
    let city: String?
    let stateProv: String?
    let country: String?
    let website: String?
    let rookieYear: Int?
    
    var id: String { teamKey }
    
    var teamNumberString: String {
        String(teamNumber)
    }
    
    var displayName: String {
        teamNameShort ?? teamNameLong ?? "Team \(teamNumber)"
    }
}

struct TOATeamDetail: Codable {
    let teamKey: String
    let teamNumber: Int
    let teamNameShort: String?
    let teamNameLong: String?
    let city: String?
    let stateProv: String?
    let country: String?
    let website: String?
    let rookieYear: Int?
    let robotName: String?
    let districtCode: String?
    let venue: String?
    
    var teamNumberString: String {
        String(teamNumber)
    }
    
    var displayName: String {
        teamNameShort ?? teamNameLong ?? "Team \(teamNumber)"
    }
}

struct TOAEvent: Codable, Identifiable {
    let eventKey: String
    let seasonKey: String
    let regionKey: String?
    let leagueKey: String?
    let eventCode: String
    let eventName: String
    let eventType: String?
    let city: String?
    let stateProv: String?
    let country: String?
    let startDate: String?
    let endDate: String?
    let weekNumber: Int?
    
    var id: String { eventKey }
    
    var seasonYear: Int? {
        // Extract year from seasonKey (e.g., "2324" -> 2024)
        guard let key = Int(seasonKey.prefix(2)) else { return nil }
        return 2000 + key
    }
}

struct TOAMatch: Codable, Identifiable {
    let matchKey: String
    let eventKey: String
    let matchName: String
    let matchType: String?
    let redScore: Int?
    let blueScore: Int?
    let redAutoScore: Int?
    let blueAutoScore: Int?
    let redTeleopScore: Int?
    let blueTeleopScore: Int?
    let redEndgameScore: Int?
    let blueEndgameScore: Int?
    let scheduledTime: String?
    let playedTime: String?
    let redTeams: [String]?
    let blueTeams: [String]?
    
    var id: String { matchKey }
    
    var matchNumber: String {
        matchName
    }
    
    var scheduledDate: Date? {
        guard let timeString = scheduledTime else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timeString)
    }
}

struct TOATeamStats: Codable {
    let teamKey: String
    let seasonKey: String?
    let eventKey: String?
    let opr: Double?
    let dpr: Double?
    let ccwm: Double?
    let wins: Int?
    let losses: Int?
    let ties: Int?
    let matchesPlayed: Int?
    let averageScore: Double?
    let averageAutoScore: Double?
    let averageTeleopScore: Double?
    let averageEndgameScore: Double?
    let highestScore: Int?
    let lowestScore: Int?
    
    var winRate: Double? {
        guard let wins = wins, let matches = matchesPlayed, matches > 0 else { return nil }
        return Double(wins) / Double(matches)
    }
}

// MARK: - Cache Structure

private struct TOASearchCacheEntry {
    let teams: [TOATeam]
    let cachedAt: Date
}

private struct CachedTeamData {
    let teamDetail: TOATeamDetail
    let cachedAt: Date
}

// MARK: - Errors

enum TOAError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case rateLimited(retryAfterSeconds: Int)
    case decodingError(String)
    case networkError(String)
    case teamNotFound
    
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
        case .decodingError(let message):
            return "Failed to decode response: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .teamNotFound:
            return "Team not found"
        }
    }
}
