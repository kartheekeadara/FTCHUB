//
//  ScoutingReport.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

struct ScoutingReport: Identifiable, Codable {
    let id: UUID
    var teamId: UUID
    var templateId: UUID?
    var scoutedTeamNumber: String
    var matchNumber: String?
    var eventName: String?
    var phase: MatchPhase? // Assuming MatchPhase enum exists from SQL schema
    var scoutId: UUID?
    var reportData: [String: String] // Store form responses as JSON
    var notes: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case templateId = "template_id"
        case scoutedTeamNumber = "scouted_team_number"
        case matchNumber = "match_number"
        case eventName = "event_name"
        case phase
        case scoutId = "scout_id"
        case reportData = "report_data"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static var sample: ScoutingReport {
        ScoutingReport(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!,
            templateId: UUID(),
            scoutedTeamNumber: "54321",
            matchNumber: "Q1",
            eventName: "Regional Qualifier",
            phase: .teleop,
            scoutId: UUID(),
            reportData: [
                "Alliance Color": "Red",
                "Auto Green Artifacts": "8",
                "Auto Purple Artifacts": "5",
                "Auto Reliability": "4",
                "Teleop Green Artifacts": "18",
                "Teleop Purple Artifacts": "17",
                "Alliance Coordination": "true",
                "Driving Quality": "4",
                "Robot Speed": "4",
                "Primary Strategy": "Offensive Scoring",
                "Defends Well": "true",
                "Penalties": "0",
                "Endgame Green Artifacts": "3",
                "Endgame Purple Artifacts": "2",
                "Parked in Zone": "true",
                "Endgame Execution": "4",
                "Overall Quality": "4",
                "Alliance Selection Rating": "4",
                "Reliability": "Mostly Reliable",
                "Artifact Strategy Notes": "Fast intake, prefers green zone placement",
                "General Notes": "Strong autonomous, consistent robot",
                "Alliance Selection Notes": "Top choice for alliance partner"
            ],
            notes: "Overall strong performance with excellent artifact scoring.",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - MatchPhase Enum
enum MatchPhase: String, CaseIterable, Codable {
    case auto = "auto"
    case teleop = "teleop"
    case endgame = "endgame"
    
    var displayName: String {
        switch self {
        case .auto: return "Autonomous"
        case .teleop: return "Teleop"
        case .endgame: return "Endgame"
        }
    }
    
    var icon: String {
        switch self {
        case .auto: return "play.circle"
        case .teleop: return "person.circle"
        case .endgame: return "flag.circle"
        }
    }
}