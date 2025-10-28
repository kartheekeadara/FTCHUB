//
//  ScheduleService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class ScheduleService: ObservableObject {
    @Published var matches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var importStatus: ImportStatus = .idle
    
    enum ImportStatus {
        case idle
        case importing
        case success
        case failed(String)
    }
    
    private let supabase = SupabaseService.shared.client
    
    // MARK: - Schedule Import
    func importFTCLiveSchedule(from data: Data, eventName: String) async {
        isLoading = true
        importStatus = .importing
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Try to parse as JSON first (FTC-Live format)
            if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let importedMatches = try parseFTCLiveJSON(jsonData, eventName: eventName)
                try await saveMatches(importedMatches)
                importStatus = .success
            } else {
                // Try to parse as CSV
                let csvString = String(data: data, encoding: .utf8) ?? ""
                let importedMatches = try parseCSV(csvString, eventName: eventName)
                try await saveMatches(importedMatches)
                importStatus = .success
            }
        } catch {
            errorMessage = error.localizedDescription
            importStatus = .failed(error.localizedDescription)
        }
    }
    
    func importScheduleFromURL(_ url: URL, eventName: String) async {
        do {
            let data = try Data(contentsOf: url)
            await importFTCLiveSchedule(from: data, eventName: eventName)
        } catch {
            errorMessage = error.localizedDescription
            importStatus = .failed(error.localizedDescription)
        }
    }
    
    // MARK: - JSON Parsing (FTC-Live format)
    private func parseFTCLiveJSON(_ json: [String: Any], eventName: String) throws -> [Match] {
        guard let matchesData = json["matches"] as? [[String: Any]] else {
            throw ScheduleError.invalidFormat
        }
        
        var matches: [Match] = []
        
        for matchData in matchesData {
            let match = try parseMatchFromJSON(matchData, eventName: eventName)
            matches.append(match)
        }
        
        return matches
    }
    
    private func parseMatchFromJSON(_ data: [String: Any], eventName: String) throws -> Match {
        guard let matchNumber = data["matchNumber"] as? String,
              let scheduledTimeString = data["scheduledTime"] as? String,
              let scheduledTime = parseDate(scheduledTimeString) else {
            throw ScheduleError.invalidMatchData
        }
        
        let allianceColor = (data["allianceColor"] as? String)?.lowercased() == "red" ? AllianceColor.red : .blue
        let status = parseMatchStatus(data["status"] as? String)
        
        let match = Match(
            id: UUID(),
            teamId: UUID(), // This should be set from current team
            matchNumber: matchNumber,
            scheduledTime: scheduledTime,
            allianceColor: allianceColor,
            alliancePartner1: data["alliancePartner1"] as? Int,
            alliancePartner2: data["alliancePartner2"] as? Int,
            opponent1: data["opponent1"] as? Int,
            opponent2: data["opponent2"] as? Int,
            opponent3: data["opponent3"] as? Int,
            status: status,
            ourScore: data["ourScore"] as? Int,
            opponentScore: data["opponentScore"] as? Int,
            location: data["location"] as? String,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return match
    }
    
    // MARK: - CSV Parsing
    private func parseCSV(_ csvString: String, eventName: String) throws -> [Match] {
        let lines = csvString.components(separatedBy: .newlines)
        guard lines.count > 1 else { throw ScheduleError.invalidFormat }
        
        let headers = lines[0].components(separatedBy: ",")
        var matches: [Match] = []
        
        for i in 1..<lines.count {
            let values = lines[i].components(separatedBy: ",")
            guard values.count == headers.count else { continue }
            
            let match = try parseMatchFromCSV(headers: headers, values: values, eventName: eventName)
            matches.append(match)
        }
        
        return matches
    }
    
    private func parseMatchFromCSV(headers: [String], values: [String], eventName: String) throws -> Match {
        var matchData: [String: String] = [:]
        
        for (index, header) in headers.enumerated() {
            if index < values.count {
                matchData[header.lowercased()] = values[index].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        guard let matchNumber = matchData["matchnumber"] ?? matchData["match_number"],
              let scheduledTimeString = matchData["scheduledtime"] ?? matchData["scheduled_time"],
              let scheduledTime = parseDate(scheduledTimeString) else {
            throw ScheduleError.invalidMatchData
        }
        
        let allianceColor = (matchData["alliancecolor"] ?? matchData["alliance_color"])?.lowercased() == "red" ? AllianceColor.red : .blue
        let status = parseMatchStatus(matchData["status"])
        
        let match = Match(
            id: UUID(),
            teamId: UUID(), // This should be set from current team
            matchNumber: matchNumber,
            scheduledTime: scheduledTime,
            allianceColor: allianceColor,
            alliancePartner1: Int(matchData["alliancepartner1"] ?? matchData["alliance_partner_1"] ?? ""),
            alliancePartner2: Int(matchData["alliancepartner2"] ?? matchData["alliance_partner_2"] ?? ""),
            opponent1: Int(matchData["opponent1"] ?? matchData["opponent_1"] ?? ""),
            opponent2: Int(matchData["opponent2"] ?? matchData["opponent_2"] ?? ""),
            opponent3: Int(matchData["opponent3"] ?? matchData["opponent_3"] ?? ""),
            status: status,
            ourScore: Int(matchData["ourscore"] ?? matchData["our_score"] ?? ""),
            opponentScore: Int(matchData["opponentscore"] ?? matchData["opponent_score"] ?? ""),
            location: matchData["location"],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return match
    }
    
    // MARK: - Helper Methods
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "MM/dd/yyyy HH:mm",
            "yyyy-MM-dd"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func parseMatchStatus(_ statusString: String?) -> MatchStatus {
        guard let status = statusString?.lowercased() else { return .scheduled }
        
        switch status {
        case "completed", "finished":
            return .completed
        case "in_progress", "running":
            return .inProgress
        case "forfeited", "forfeit":
            return .forfeited
        default:
            return .scheduled
        }
    }
    
    private func saveMatches(_ matches: [Match]) async throws {
        for match in matches {
            try await supabase
                .from("matches")
                .insert(match)
                .execute() as! [Match]
        }
        
        await loadMatches()
    }
    
    // MARK: - Data Loading
    func loadMatches() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // TODO: Replace with actual team_id from AuthService.currentUser.teamId
            guard let teamId = UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else {
                errorMessage = "Team ID not available."
                return
            }
            
            let loadedMatches: [Match] = try await supabase
                .from("matches")
                .select()
                .eq("team_id", value: teamId)
                .order("scheduled_time", ascending: true)
                .execute() as! [Match]
            
            matches = loadedMatches
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Match Management
    func updateMatch(_ match: Match) async throws {
        try await supabase
            .from("matches")
            .update(match)
            .eq("id", value: match.id)
            .execute() as! [Match]
        
        await loadMatches()
    }
    
    func deleteMatch(_ match: Match) async throws {
        try await supabase
            .from("matches")
            .delete()
            .eq("id", value: match.id)
            .execute() as! [Match]
        
        await loadMatches()
    }
    
    // MARK: - Export
    func exportScheduleToCSV() -> String {
        var csvString = "Match Number,Scheduled Time,Alliance Color,Alliance Partner 1,Alliance Partner 2,Opponent 1,Opponent 2,Opponent 3,Our Score,Opponent Score,Status,Location\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for match in matches {
            let row = [
                match.matchNumber,
                formatter.string(from: match.scheduledTime),
                match.allianceColor.rawValue.capitalized,
                match.alliancePartner1?.description ?? "",
                match.alliancePartner2?.description ?? "",
                match.opponent1?.description ?? "",
                match.opponent2?.description ?? "",
                match.opponent3?.description ?? "",
                match.ourScore?.description ?? "",
                match.opponentScore?.description ?? "",
                match.status.rawValue.capitalized,
                match.location ?? ""
            ].joined(separator: ",")
            
            csvString += row + "\n"
        }
        
        return csvString
    }
}

// MARK: - Schedule Errors
enum ScheduleError: LocalizedError {
    case invalidFormat
    case invalidMatchData
    case importFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid schedule format"
        case .invalidMatchData:
            return "Invalid match data"
        case .importFailed:
            return "Failed to import schedule"
        }
    }
}
