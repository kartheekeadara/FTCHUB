//
//  ExternalDataModels.swift
//  FTCHUB
//
//  Shared models for FTC Scout and Orange Alliance external data.
//

import Foundation

enum ExternalDataSource: String, Codable {
    case ftcScout = "ftc_scout"
    case orangeAlliance = "orange_alliance"
    case merged = "merged"
}

struct ExternalAward: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let eventCode: String?
    let eventName: String?
    let season: Int?
    let teamNumber: Int?

    init(name: String, eventCode: String? = nil, eventName: String? = nil, season: Int? = nil, teamNumber: Int? = nil) {
        self.name = name
        self.eventCode = eventCode
        self.eventName = eventName
        self.season = season
        self.teamNumber = teamNumber
        self.id = "\(season ?? 0)-\(eventCode ?? "global")-\(name)-\(teamNumber ?? 0)"
    }
}

struct ExternalEventParticipation: Identifiable, Codable, Hashable {
    let id: String
    let season: Int
    let eventCode: String
    let eventName: String?
    let rank: Int?
    let rankingPoints: Double?
    let wins: Int
    let losses: Int
    let ties: Int
    let qualMatchesPlayed: Int
    let totalPointsOPR: Double?
    let autoPointsOPR: Double?
    let dcPointsOPR: Double?
    let totalPointsAvg: Double?
    let autoPointsAvg: Double?
    let dcPointsAvg: Double?

    var winRate: Double? {
        let total = wins + losses + ties
        guard total > 0 else { return nil }
        return Double(wins) / Double(total)
    }

    init(
        season: Int,
        eventCode: String,
        eventName: String? = nil,
        rank: Int? = nil,
        rankingPoints: Double? = nil,
        wins: Int = 0,
        losses: Int = 0,
        ties: Int = 0,
        qualMatchesPlayed: Int = 0,
        totalPointsOPR: Double? = nil,
        autoPointsOPR: Double? = nil,
        dcPointsOPR: Double? = nil,
        totalPointsAvg: Double? = nil,
        autoPointsAvg: Double? = nil,
        dcPointsAvg: Double? = nil
    ) {
        self.season = season
        self.eventCode = eventCode
        self.eventName = eventName
        self.rank = rank
        self.rankingPoints = rankingPoints
        self.wins = wins
        self.losses = losses
        self.ties = ties
        self.qualMatchesPlayed = qualMatchesPlayed
        self.totalPointsOPR = totalPointsOPR
        self.autoPointsOPR = autoPointsOPR
        self.dcPointsOPR = dcPointsOPR
        self.totalPointsAvg = totalPointsAvg
        self.autoPointsAvg = autoPointsAvg
        self.dcPointsAvg = dcPointsAvg
        self.id = "\(season)-\(eventCode)"
    }
}

struct ExternalEventSummary: Identifiable, Codable, Hashable {
    let id: String
    let season: Int
    let code: String
    let name: String
    let eventType: String?
    let city: String?
    let state: String?
    let country: String?
    let startDate: String?
    let endDate: String?
    let venue: String?
    let liveStreamURL: String?
    let hasMatches: Bool

    init(
        season: Int,
        code: String,
        name: String,
        eventType: String? = nil,
        city: String? = nil,
        state: String? = nil,
        country: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        venue: String? = nil,
        liveStreamURL: String? = nil,
        hasMatches: Bool = false
    ) {
        self.season = season
        self.code = code
        self.name = name
        self.eventType = eventType
        self.city = city
        self.state = state
        self.country = country
        self.startDate = startDate
        self.endDate = endDate
        self.venue = venue
        self.liveStreamURL = liveStreamURL
        self.hasMatches = hasMatches
        self.id = "\(season)-\(code)"
    }

    var locationDisplay: String {
        [city, state, country == "USA" ? nil : country].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: ", ")
    }
}

struct ExternalEventTeamRanking: Identifiable, Codable, Hashable {
    let id: String
    let teamNumber: Int
    let teamName: String?
    let rank: Int?
    let rankingPoints: Double?
    let wins: Int
    let losses: Int
    let ties: Int
    let qualMatchesPlayed: Int
    let totalPointsOPR: Double?
    let autoPointsOPR: Double?
    let dcPointsOPR: Double?
    let totalPointsAvg: Double?
    let autoPointsAvg: Double?
    let dcPointsAvg: Double?

    init(
        teamNumber: Int,
        teamName: String? = nil,
        rank: Int? = nil,
        rankingPoints: Double? = nil,
        wins: Int = 0,
        losses: Int = 0,
        ties: Int = 0,
        qualMatchesPlayed: Int = 0,
        totalPointsOPR: Double? = nil,
        autoPointsOPR: Double? = nil,
        dcPointsOPR: Double? = nil,
        totalPointsAvg: Double? = nil,
        autoPointsAvg: Double? = nil,
        dcPointsAvg: Double? = nil
    ) {
        self.teamNumber = teamNumber
        self.teamName = teamName
        self.rank = rank
        self.rankingPoints = rankingPoints
        self.wins = wins
        self.losses = losses
        self.ties = ties
        self.qualMatchesPlayed = qualMatchesPlayed
        self.totalPointsOPR = totalPointsOPR
        self.autoPointsOPR = autoPointsOPR
        self.dcPointsOPR = dcPointsOPR
        self.totalPointsAvg = totalPointsAvg
        self.autoPointsAvg = autoPointsAvg
        self.dcPointsAvg = dcPointsAvg
        self.id = String(teamNumber)
    }
}

struct ExternalEventMatch: Identifiable, Codable, Hashable {
    let id: String
    let season: Int
    let eventCode: String
    let matchId: Int
    let matchNumber: String
    let tournamentLevel: String?
    let scheduledStartTime: String?
    let hasBeenPlayed: Bool
    let redScore: Int?
    let blueScore: Int?
    let redTeams: [Int]
    let blueTeams: [Int]

    init(
        season: Int,
        eventCode: String,
        matchId: Int,
        matchNumber: String,
        tournamentLevel: String? = nil,
        scheduledStartTime: String? = nil,
        hasBeenPlayed: Bool = false,
        redScore: Int? = nil,
        blueScore: Int? = nil,
        redTeams: [Int] = [],
        blueTeams: [Int] = []
    ) {
        self.season = season
        self.eventCode = eventCode
        self.matchId = matchId
        self.matchNumber = matchNumber
        self.tournamentLevel = tournamentLevel
        self.scheduledStartTime = scheduledStartTime
        self.hasBeenPlayed = hasBeenPlayed
        self.redScore = redScore
        self.blueScore = blueScore
        self.redTeams = redTeams
        self.blueTeams = blueTeams
        self.id = "\(season)-\(eventCode)-\(matchId)"
    }
}

enum ExternalEventRankingSort: String, CaseIterable {
    case rank = "Rank"
    case totalNP = "Total NP"
    case auto = "Auto"
    case dc = "TeleOp"
    case rp = "RP"
}
