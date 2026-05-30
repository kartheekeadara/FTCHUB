//
//  TeamScoutingSummary.swift
//  FTCHUB
//
//  Created on 11/16/25.
//

import Foundation

struct TeamScoutingSummary: Identifiable, Codable {
    let id: UUID
    var teamId: UUID
    var scoutedTeamNumber: String
    var eventName: String?
    
    // Header
    var matchesSampled: Int
    var scoutName: String?
    var lastUpdated: Date
    
    // Quick Stats (calculated from reports)
    var avgAutoArtifacts: Double
    var autoSuccessRate: Double // percentage (0-100)
    var avgTeleopArtifacts: Double
    var avgEndgameSuccess: Double // percentage (0-100)
    var reliability: Double // percentage (0-100)
    var avgPenalties: Double
    var penaltyTypes: [String] // e.g., ["boundary", "possession"]
    var consistency: Double // standard deviation
    
    // Analysis (user-editable)
    var strengths: [String] // 3-4 bullets max
    var weaknesses: [String] // 3-4 bullets max
    var primaryRole: String // scorer/transporter/defender/anchor
    var secondaryRole: String
    var matchTactics: MatchTactics
    var allianceFit: AllianceFit
    var exploitationNotes: String
    var countermeasures: String
    var pitNotes: PitNotes
    var quickActionItems: [String] // max 3 items
    
    // Metadata
    var rawDataLinks: String // where to find full reports
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case scoutedTeamNumber = "scouted_team_number"
        case eventName = "event_name"
        case matchesSampled = "matches_sampled"
        case scoutName = "scout_name"
        case lastUpdated = "last_updated"
        case avgAutoArtifacts = "avg_auto_artifacts"
        case autoSuccessRate = "auto_success_rate"
        case avgTeleopArtifacts = "avg_teleop_artifacts"
        case avgEndgameSuccess = "avg_endgame_success"
        case reliability
        case avgPenalties = "avg_penalties"
        case penaltyTypes = "penalty_types"
        case consistency
        case strengths
        case weaknesses
        case primaryRole = "primary_role"
        case secondaryRole = "secondary_role"
        case matchTactics = "match_tactics"
        case allianceFit = "alliance_fit"
        case exploitationNotes = "exploitation_notes"
        case countermeasures
        case pitNotes = "pit_notes"
        case quickActionItems = "quick_action_items"
        case rawDataLinks = "raw_data_links"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static var sample: TeamScoutingSummary {
        TeamScoutingSummary(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            scoutedTeamNumber: "1234",
            eventName: "Regional Qualifier",
            matchesSampled: 8,
            scoutName: "Maya",
            lastUpdated: Date(),
            avgAutoArtifacts: 1.9,
            autoSuccessRate: 87.0,
            avgTeleopArtifacts: 7.2,
            avgEndgameSuccess: 62.0,
            reliability: 81.0,
            avgPenalties: 0.5,
            penaltyTypes: ["boundary"],
            consistency: 6.0,
            strengths: [
                "Reliable autonomous preload (scores ~2 artifacts consistently)",
                "High teleop cycle speed when unbothered (7+ artifacts/match)",
                "Good shooter alignment — quick reacquire after movement"
            ],
            weaknesses: [
                "Endgame not consistent — misses park on ~38% of attempts",
                "Intake jams under contact — observed 3 times, takes ~30s to clear",
                "Loses efficiency when defended; cycle rate drops ~45%"
            ],
            primaryRole: "Teleop scorer / cycle partner",
            secondaryRole: "Occasional defender (short bursts only)",
            matchTactics: MatchTactics(
                autonomous: "Let them run preload — don't block starting zone",
                teleop: "Pair them with a partner that finishes endgame RP. Keep them on outside lanes for longer cycles",
                defense: "Use short harassment to cause intake jams; avoid continuous contact",
                endgame: "Don't depend on them for RP unless they show two consecutive successful endgames in scouting"
            ),
            allianceFit: AllianceFit(
                idealPartners: "Strong endgame specialist (park/climb ~95%), and a consistent loader to minimize travel time",
                pickPriority: 2,
                priorityReason: "Good scorer but needs endgame partner"
            ),
            exploitationNotes: "Apply light contact in teleop to force jams (risk: may draw boundary warnings)",
            countermeasures: "Force cross-field cycles to increase their transit time and reduce total cycles",
            pitNotes: PitNotes(
                batteryHealth: "Good",
                knownFailureModes: ["Intake shaft loosens after heavy contact (tighten in pit)"],
                humanFactors: "2 experienced drivers, calm under pressure"
            ),
            quickActionItems: [
                "If selecting them, confirm endgame reliability in the next 2 matches",
                "Instruct drive team to avoid relying on their endgame RP unless 2/2 success",
                "Prep a partner with fast park to guarantee alliance RP"
            ],
            rawDataLinks: "Full reports in FTC HUB → Reports → Team 1234 → last 8 matches; Trend: Analytics → Endgame success",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Supporting Structures

struct MatchTactics: Codable {
    var autonomous: String
    var teleop: String
    var defense: String
    var endgame: String
}

struct AllianceFit: Codable {
    var idealPartners: String
    var pickPriority: Int // 1-5 (1 = must-pick, 5 = avoid)
    var priorityReason: String
}

struct PitNotes: Codable {
    var batteryHealth: String // Good/Marginal/Poor
    var knownFailureModes: [String]
    var humanFactors: String // driver experience, coach communication
}

// MARK: - Role Options

enum ScoutingRole: String, CaseIterable {
    case scorer = "Scorer"
    case transporter = "Transporter"
    case defender = "Defender"
    case anchor = "Anchor"
    case cyclePartner = "Cycle Partner"
    case backupScorer = "Backup Scorer"
    case cycleExtender = "Cycle Extender"
    case cycleDefender = "Cycle Defender"
    
    var displayName: String {
        return rawValue
    }
}

// MARK: - Reliability Flag

enum ReliabilityFlag: String, CaseIterable {
    case ok = "OK"
    case minor = "Minor Issue"
    case major = "Major Issue"
    
    var displayName: String {
        return rawValue
    }
    
    var color: String {
        switch self {
        case .ok: return "green"
        case .minor: return "yellow"
        case .major: return "red"
        }
    }
}

// MARK: - Penalty Types

enum PenaltyType: String, CaseIterable {
    case boundary = "Boundary"
    case possession = "Possession"
    case contact = "Contact"
    case interference = "Interference"
    case other = "Other"
    
    var displayName: String {
        return rawValue
    }
}

