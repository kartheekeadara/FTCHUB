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
