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
                "Starting Position": "Gate 2",
                "Preload Artifact": "Green Artifact",
                "Drive Base": "Mecanum",
                "Match Phase": MatchPhase.teleop.rawValue,
                "Observed Randomization": "Motif 2",
                "Auto Classified Artifacts": "6",
                "Auto Overflow Artifacts": "2",
                "Robot 1 Auto Leave": "true",
                "Robot 2 Auto Leave": "true",
                "Auto Pattern Success": "true",
                "Autonomous Reliability": "4",
                "Teleop Classified Artifacts": "18",
                "Teleop Overflow Artifacts": "12",
                "Teleop Depot Cycles": "6",
                "Alliance Coordination": "true",
                "Driving Quality": "4",
                "Robot Speed": "4",
                "Strategy Focus": "Classified Stacking",
                "Defends Well": "false",
                "Penalties Observed": "0",
                "Robot 1 Base Result": "Full",
                "Robot 2 Base Result": "Partial",
                "Parked In Base Zone": "true",
                "Endgame Execution": "4",
                "Movement RP": "true",
                "Goal RP": "true",
                "Pattern RP": "false",
                "Overall Quality": "4",
                "Alliance Selection Rating": "4",
                "Reliability Level": "Mostly Reliable",
                "Artifact Strategy Notes": "Fast intake, prefers green gate stacking. Runs overflow cycles with partner.",
                "General Notes": "Strong autonomous, consistent cycle times under 12s.",
                "Alliance Selection Notes": "Top pick for offense; ensure partner covers defense."
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

// MARK: - Analytics Helpers
extension ScoutingReport {
    func numericValue(for key: String) -> Double? {
        guard let raw = reportData[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        return Double(raw)
    }
    
    func boolValue(for key: String) -> Bool? {
        guard let raw = reportData[key]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !raw.isEmpty else { return nil }
        switch raw {
        case "true", "yes", "1": return true
        case "false", "no", "0": return false
        default: return nil
        }
    }
    
    func stringValue(for key: String) -> String? {
        guard let raw = reportData[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        return raw
    }
}