//
//  Match.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

struct Match: Codable, Identifiable {
    let id: UUID
    var teamId: UUID
    var matchNumber: String
    var scheduledTime: Date
    var allianceColor: AllianceColor
    var alliancePartner1: Int?
    var alliancePartner2: Int?
    var opponent1: Int?
    var opponent2: Int?
    var opponent3: Int?
    var status: MatchStatus
    var ourScore: Int?
    var opponentScore: Int?
    var location: String?
    
    // Phase 1: Statistics calculation fields
    var redAllianceScore: Int?
    var blueAllianceScore: Int?
    var eventName: String?
    var seasonYear: Int?
    var redTeam1: String?
    var redTeam2: String?
    var redTeam3: String?
    var blueTeam1: String?
    var blueTeam2: String?
    var blueTeam3: String?
    
    // DEPRECATED (Phase 1): OCR fields - Scoreboard OCR feature removed
    // These fields are kept for backward compatibility but are no longer used
    var scoreSource: String?
    var ocrConfidence: Double?
    var ocrRawData: [String: String]? // JSONB stored as dictionary
    var penaltiesRed: Int?
    var penaltiesBlue: Int?
    var scoreboardImageUrl: String?
    var ocrProcessingTimeMs: Int?
    var ocrVersion: String?
    
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, location
        case teamId = "team_id"
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
        case redAllianceScore = "red_alliance_score"
        case blueAllianceScore = "blue_alliance_score"
        case eventName = "event_name"
        case seasonYear = "season_year"
        case redTeam1 = "red_team1"
        case redTeam2 = "red_team2"
        case redTeam3 = "red_team3"
        case blueTeam1 = "blue_team1"
        case blueTeam2 = "blue_team2"
        case blueTeam3 = "blue_team3"
        case scoreSource = "score_source"
        case ocrConfidence = "ocr_confidence"
        case ocrRawData = "ocr_raw_data"
        case penaltiesRed = "penalties_red"
        case penaltiesBlue = "penalties_blue"
        case scoreboardImageUrl = "scoreboard_image_url"
        case ocrProcessingTimeMs = "ocr_processing_time_ms"
        case ocrVersion = "ocr_version"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum AllianceColor: String, Codable, CaseIterable {
    case red = "red"
    case blue = "blue"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

enum MatchStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case inProgress = "in_progress"
    case completed = "completed"
    case forfeited = "forfeited"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .forfeited: return "Forfeited"
        }
    }
}

// MARK: - Match Timer Phase
enum MatchTimerPhase: String, Codable, CaseIterable {
    case autonomous = "autonomous"
    case teleop = "teleop"
    case endgame = "endgame"
    case timeout = "timeout"
    
    var displayName: String {
        switch self {
        case .autonomous: return "Autonomous"
        case .teleop: return "Teleop"
        case .endgame: return "Endgame"
        case .timeout: return "Timeout"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .autonomous: return 30 // 30 seconds for autonomous
        case .teleop: return 120 // 2 minutes for teleop
        case .endgame: return 30 // 30 seconds for endgame
        case .timeout: return 120 // 2 minutes for timeout
        }
    }
}
