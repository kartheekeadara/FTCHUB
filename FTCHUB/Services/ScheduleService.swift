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
final class ScheduleService: ObservableObject {
    @Published private(set) var matches: [Match] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var importStatus: ImportStatus = .idle
    @Published private(set) var quickNotes: [UUID: [MatchNote]] = [:]
    @Published var pendingCompetitionAttention = false
    /// Last time the user saved an offline copy of the schedule for this team (Phase 2).
    @Published private(set) var offlineEventPackSavedAt: Date?
    
    enum ImportStatus: Equatable {
        case idle
        case importing
        case success(Int)
        case failed(String)
    }
    
    enum MatchImportFormat: String {
        case json = "FTC Live JSON"
        case csv = "CSV"
    }
    
    struct MatchImportPreview {
        let drafts: [MatchDraft]
        let format: MatchImportFormat
        let warnings: [String]
    }
    
    private let supabase = SupabaseService.shared.client
    private let defaults = UserDefaults.standard
    private(set) var activeTeamId: UUID?
    private var attentionResetTask: Task<Void, Never>?
    
    var currentTeamId: UUID? { activeTeamId }
    var hasTeamContext: Bool { activeTeamId != nil }
    
    func updateTeamContext(teamId: UUID?) {
        guard activeTeamId != teamId else { return }
        activeTeamId = teamId
        importStatus = .idle
        matches = []
        quickNotes = [:]
        if let teamId {
            quickNotes = loadQuickNotes(for: teamId)
            refreshOfflinePackTimestamp(for: teamId)
        } else {
            offlineEventPackSavedAt = nil
        }
        
        Task {
            await loadMatches()
        }
    }
    
    func resetImportStatus() {
        importStatus = .idle
        acknowledgeCompetitionAttention()
    }
    
    func loadMatches() async {
        guard let teamId = activeTeamId else {
            matches = []
            errorMessage = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let loadedMatches: [Match] = try await supabase
                .from("matches")
                .select()
                .eq("team_id", value: teamId)
                .order("scheduled_time", ascending: true)
                .execute()
                .value
            
            matches = loadedMatches
        } catch {
            TelemetryService.shared.logError(error, context: ["action": "load_matches"])
            if loadOfflineEventPackIfAvailable() {
                errorMessage = "Showing your saved event pack. Pull to refresh when you are online."
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Offline event pack (Phase 2)
    
    private struct OfflineMatchPack: Codable {
        let matches: [Match]
        let savedAt: Date
    }
    
    private func offlinePackStorageKey(teamId: UUID) -> String {
        "ftchub.offlineMatchPack." + teamId.uuidString
    }
    
    private func offlinePackTimestampKey(teamId: UUID) -> String {
        "ftchub.offlineMatchPack.savedAt." + teamId.uuidString
    }
    
    private func refreshOfflinePackTimestamp(for teamId: UUID) {
        let ts = defaults.object(forKey: offlinePackTimestampKey(teamId: teamId)) as? Date
        offlineEventPackSavedAt = ts
    }
    
    /// Persists the current `matches` array for offline venue use.
    func saveOfflineEventPack() throws {
        guard let teamId = activeTeamId else { return }
        let pack = OfflineMatchPack(matches: matches, savedAt: Date())
        let data = try JSONEncoder().encode(pack)
        defaults.set(data, forKey: offlinePackStorageKey(teamId: teamId))
        defaults.set(pack.savedAt, forKey: offlinePackTimestampKey(teamId: teamId))
        offlineEventPackSavedAt = pack.savedAt
    }
    
    @discardableResult
    private func loadOfflineEventPackIfAvailable() -> Bool {
        guard let teamId = activeTeamId else { return false }
        guard let data = defaults.data(forKey: offlinePackStorageKey(teamId: teamId)),
              let pack = try? JSONDecoder().decode(OfflineMatchPack.self, from: data),
              !pack.matches.isEmpty else { return false }
        matches = pack.matches
        offlineEventPackSavedAt = pack.savedAt
        return true
    }
    
    func upcomingMatch(after date: Date = Date()) -> Match? {
        matches
            .filter { $0.scheduledTime >= date }
            .sorted(by: { $0.scheduledTime < $1.scheduledTime })
            .first
    }
    
    func matches(on date: Date) -> [Match] {
        let calendar = Calendar.current
        return matches.filter { calendar.isDate($0.scheduledTime, inSameDayAs: date) }
    }
    
    // MARK: - Attention
    func acknowledgeCompetitionAttention() {
        attentionResetTask?.cancel()
        attentionResetTask = nil
        pendingCompetitionAttention = false
    }
    
    private func triggerCompetitionAttention(duration: TimeInterval = 6) {
        pendingCompetitionAttention = true
        attentionResetTask?.cancel()
        attentionResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                self?.pendingCompetitionAttention = false
            }
        }
    }
    
    // MARK: - Match CRUD
    func createMatch(from draft: MatchDraft) async throws {
        guard let teamId = activeTeamId else {
            throw ScheduleError.teamUnavailable
        }
        
        let match = draft.makeMatch(teamId: teamId)
        
        try await supabase
            .from("matches")
            .insert(match)
            .execute()
        
        await loadMatches()
        NotificationService.shared.rescheduleMatchReminder(for: match)
    }
    
    func updateMatch(_ match: Match, with draft: MatchDraft) async throws {
        let updated = draft.applying(to: match)
        
        try await supabase
            .from("matches")
            .update(updated)
            .eq("id", value: updated.id)
            .execute()
        
        await loadMatches()
        NotificationService.shared.rescheduleMatchReminder(for: updated)
    }
    
    func setStatus(_ status: MatchStatus, for match: Match) async throws {
        var draft = MatchDraft(from: match)
        draft.status = status
        try await updateMatch(match, with: draft)
    }
    
    func deleteMatch(_ match: Match) async throws {
        NotificationService.shared.cancelMatchReminders(matchId: match.id)
        try await supabase
            .from("matches")
            .delete()
            .eq("id", value: match.id)
            .execute()
        
        await loadMatches()
    }
    
    // MARK: - Import / Export
    func importSchedule(from data: Data, eventName: String, seasonYear: Int? = nil) async {
        guard let teamId = activeTeamId else {
            let message: String
            if let description = ScheduleError.teamUnavailable.errorDescription {
                message = description
            } else {
                message = "Join or create a team to manage the match schedule."
            }
            errorMessage = message
            importStatus = .failed(message)
            return
        }
        
        importStatus = .importing
        errorMessage = nil
        
        do {
            let preview = try previewSchedule(from: data)
            let drafts = preview.drafts
            
            let timestamp = Date()
            let year = seasonYear ?? Calendar.current.component(.year, from: timestamp)
            let prepared = drafts.map { draft in
                var match = draft.makeMatch(teamId: teamId, createdAt: timestamp)
                match.eventName = eventName
                match.seasonYear = year
                // Populate alliance scores from our_score/opponent_score
                if match.allianceColor == .red {
                    match.redAllianceScore = match.ourScore
                    match.blueAllianceScore = match.opponentScore
                } else {
                    match.redAllianceScore = match.opponentScore
                    match.blueAllianceScore = match.ourScore
                }
                // Populate team numbers (convert Int to String)
                if match.allianceColor == .red {
                    if let p1 = match.alliancePartner1 { match.redTeam1 = String(p1) }
                    if let p2 = match.alliancePartner2 { match.redTeam2 = String(p2) }
                    // Our team number would need to come from team lookup
                    if let o1 = match.opponent1 { match.blueTeam1 = String(o1) }
                    if let o2 = match.opponent2 { match.blueTeam2 = String(o2) }
                    if let o3 = match.opponent3 { match.blueTeam3 = String(o3) }
                } else {
                    if let o1 = match.opponent1 { match.redTeam1 = String(o1) }
                    if let o2 = match.opponent2 { match.redTeam2 = String(o2) }
                    if let o3 = match.opponent3 { match.redTeam3 = String(o3) }
                    if let p1 = match.alliancePartner1 { match.blueTeam1 = String(p1) }
                    if let p2 = match.alliancePartner2 { match.blueTeam2 = String(p2) }
                    // Our team number would need to come from team lookup
                }
                return match
            }
            
            try await supabase
                .from("matches")
                .delete()
                .eq("team_id", value: teamId)
                .execute()
            
            if !prepared.isEmpty {
                try await supabase
                    .from("matches")
                    .insert(prepared)
                    .execute()
            }
            
            quickNotes = [:]
            persistQuickNotes()
            
            importStatus = .success(prepared.count)
            triggerCompetitionAttention()
            TelemetryService.shared.logEvent("schedule_import_success", parameters: [
                "count": "\(prepared.count)",
                "format": preview.format.rawValue,
                "warnings": "\(preview.warnings.count)"
            ])
            await loadMatches()
        } catch {
            errorMessage = error.localizedDescription
            importStatus = .failed(error.localizedDescription)
            acknowledgeCompetitionAttention()
            TelemetryService.shared.logError(error, context: ["action": "schedule_import"])
        }
    }
    
    func importSchedule(from url: URL, eventName: String) async {
        do {
            let data = try Data(contentsOf: url)
            await importSchedule(from: data, eventName: eventName)
        } catch {
            errorMessage = error.localizedDescription
            importStatus = .failed(error.localizedDescription)
            TelemetryService.shared.logError(error, context: ["action": "schedule_import", "source": "file_url"])
        }
    }
    
    func exportScheduleToCSV() -> String {
        var csvString = "Match Number,Scheduled Time,Alliance Color,Alliance Partner 1,Alliance Partner 2,Opponent 1,Opponent 2,Opponent 3,Our Score,Opponent Score,Red Alliance Score,Blue Alliance Score,Event Name,Season Year,Red Team 1,Red Team 2,Red Team 3,Blue Team 1,Blue Team 2,Blue Team 3,Status,Location\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for match in matches {
            let matchNumber = match.matchNumber
            let scheduledTimeStr = formatter.string(from: match.scheduledTime)
            let allianceColorStr = match.allianceColor.rawValue.capitalized
            let partner1 = match.alliancePartner1?.description ?? ""
            let partner2 = match.alliancePartner2?.description ?? ""
            let opponent1 = match.opponent1?.description ?? ""
            let opponent2 = match.opponent2?.description ?? ""
            let opponent3 = match.opponent3?.description ?? ""
            let ourScoreStr = match.ourScore?.description ?? ""
            let opponentScoreStr = match.opponentScore?.description ?? ""
            
            let rowArray: [String] = [
                matchNumber,
                scheduledTimeStr,
                allianceColorStr,
                partner1,
                partner2,
                opponent1,
                opponent2,
                opponent3,
                ourScoreStr,
                opponentScoreStr,
                match.redAllianceScore?.description ?? "",
                match.blueAllianceScore?.description ?? "",
                match.eventName ?? "",
                match.seasonYear?.description ?? "",
                match.redTeam1 ?? "",
                match.redTeam2 ?? "",
                match.redTeam3 ?? "",
                match.blueTeam1 ?? "",
                match.blueTeam2 ?? "",
                match.blueTeam3 ?? "",
                match.status.rawValue.capitalized,
                match.location ?? ""
            ]
            
            let row = rowArray.joined(separator: ",")
            csvString += row + "\n"
        }
        
        return csvString
    }
    
    // MARK: - Quick Notes
    func quickNotes(for match: Match) -> [MatchNote] {
        quickNotes[match.id] ?? []
    }
    
    func noteCount(for match: Match) -> Int {
        quickNotes(for: match).count
    }
    
    func addQuickNote(_ text: String, to match: Match) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var bucket = quickNotes[match.id] ?? []
        let note = MatchNote(id: UUID(), body: trimmed, createdAt: Date())
        bucket.append(note)
        bucket.sort { $0.createdAt < $1.createdAt }
        quickNotes[match.id] = bucket
        persistQuickNotes()
        TelemetryService.shared.logEvent("match_quick_note_added", parameters: ["match": match.matchNumber])
    }
    
    func deleteQuickNote(_ note: MatchNote, for match: Match) {
        guard var bucket = quickNotes[match.id] else { return }
        bucket.removeAll { $0.id == note.id }
        if bucket.isEmpty {
            quickNotes.removeValue(forKey: match.id)
        } else {
            quickNotes[match.id] = bucket
        }
        persistQuickNotes()
        TelemetryService.shared.logEvent("match_quick_note_removed", parameters: ["match": match.matchNumber])
    }
    
    private func loadQuickNotes(for teamId: UUID) -> [UUID: [MatchNote]] {
        let key = quickNotesDefaultsKey(for: teamId)
        guard let data = defaults.data(forKey: key) else { return [:] }
        guard let payload = try? JSONDecoder().decode([String: [MatchNote]].self, from: data) else { return [:] }
        var result: [UUID: [MatchNote]] = [:]
        for (idString, notes) in payload {
            guard let uuid = UUID(uuidString: idString) else { continue }
            result[uuid] = notes.sorted { $0.createdAt < $1.createdAt }
        }
        return result
    }
    
    private func persistQuickNotes() {
        guard let teamId = activeTeamId else { return }
        let key = quickNotesDefaultsKey(for: teamId)
        let encodable = Dictionary(uniqueKeysWithValues: quickNotes.map { ($0.key.uuidString, $0.value) })
        if let data = try? JSONEncoder().encode(encodable) {
            defaults.set(data, forKey: key)
        }
    }
    
    private func quickNotesDefaultsKey(for teamId: UUID) -> String {
        "ftchub.quicknotes." + teamId.uuidString
    }
    
    // MARK: - Import Helpers
    func previewSchedule(from data: Data) throws -> MatchImportPreview {
        let drafts: [MatchDraft]
        let format: MatchImportFormat
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            drafts = try parseFTCLiveJSON(json)
            format = .json
        } else {
            let csvString = String(data: data, encoding: .utf8) ?? ""
            drafts = try parseCSV(csvString)
            format = .csv
        }
        
        let warnings = validationWarnings(for: drafts)
        return MatchImportPreview(drafts: drafts, format: format, warnings: warnings)
    }
    
    private func validationWarnings(for drafts: [MatchDraft]) -> [String] {
        var warnings: [String] = []
        
        if drafts.isEmpty {
            warnings.append("No matches found in the selected file.")
            return warnings
        }
        
        let duplicateMatches = Dictionary(grouping: drafts, by: { $0.matchNumber.lowercased() })
            .filter { $0.value.count > 1 }
            .keys
        if !duplicateMatches.isEmpty {
            warnings.append("Duplicate match numbers detected: \(duplicateMatches.sorted().joined(separator: ", ")).")
        }
        
        let sorteddrafts = drafts.sorted { $0.scheduledTime < $1.scheduledTime }
        for index in 1..<sorteddrafts.count {
            if sorteddrafts[index].scheduledTime < sorteddrafts[index - 1].scheduledTime {
                warnings.append("Match \(sorteddrafts[index].matchNumber) appears out of chronological order.")
                break
            }
        }
        
        let missingPartners = drafts.filter { $0.alliancePartner1 == nil && $0.alliancePartner2 == nil }
        if !missingPartners.isEmpty {
            warnings.append("Some matches do not list alliance partners. Verify partner assignments before importing.")
        }
        
        let missingOpponents = drafts.filter { $0.opponent1 == nil && $0.opponent2 == nil }
        if !missingOpponents.isEmpty {
            warnings.append("Some matches do not list opponent teams. Ensure opponent slots are filled for scouting.")
        }
        
        return warnings
    }
    
    // MARK: - Parsing helpers
    private func parseFTCLiveJSON(_ json: [String: Any]) throws -> [MatchDraft] {
        guard let matchesData = json["matches"] as? [[String: Any]] else {
            throw ScheduleError.invalidFormat
        }
        
        return try matchesData.map { try parseMatchFromJSON($0) }
    }
    
    private func parseMatchFromJSON(_ data: [String: Any]) throws -> MatchDraft {
        guard let matchNumber = data["matchNumber"] as? String,
              let scheduledTimeString = data["scheduledTime"] as? String,
              let scheduledTime = parseDate(scheduledTimeString) else {
            throw ScheduleError.invalidMatchData
        }
        
        let allianceColor = (data["allianceColor"] as? String)?.lowercased() == "red" ? AllianceColor.red : .blue
        let status = parseMatchStatus(data["status"] as? String)
        
        return MatchDraft(
            matchNumber: matchNumber,
            scheduledTime: scheduledTime,
            allianceColor: allianceColor,
            alliancePartner1: data["alliancePartner1"] as? Int,
            alliancePartner2: data["alliancePartner2"] as? Int,
            opponent1: data["opponent1"] as? Int,
            opponent2: data["opponent2"] as? Int,
            status: status,
            ourScore: data["ourScore"] as? Int,
            opponentScore: data["opponentScore"] as? Int,
            location: data["location"] as? String
        )
    }
    
    private func parseCSV(_ csvString: String) throws -> [MatchDraft] {
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { throw ScheduleError.invalidFormat }
        
        let headers = lines[0].components(separatedBy: ",")
        var drafts: [MatchDraft] = []
        
        for line in lines.dropFirst() {
            let values = line.components(separatedBy: ",")
            guard !values.isEmpty else { continue }
            let cleaned = values + Array(repeating: "", count: max(0, headers.count - values.count))
            let draft = try parseMatchFromCSV(headers: headers, values: cleaned)
            drafts.append(draft)
        }
        
        return drafts
    }
    
    private func parseMatchFromCSV(headers: [String], values: [String]) throws -> MatchDraft {
        var matchData: [String: String] = [:]
        
        for (index, header) in headers.enumerated() where index < values.count {
            matchData[header.lowercased()] = values[index].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard let matchNumber = matchData["match number"] ?? matchData["matchnumber"] ?? matchData["match_number"],
              let scheduledTimeString = matchData["scheduled time"] ?? matchData["scheduledtime"] ?? matchData["scheduled_time"],
              let scheduledTime = parseDate(scheduledTimeString) else {
            throw ScheduleError.invalidMatchData
        }
        
        let allianceColor = (matchData["alliance color"] ?? matchData["alliancecolor"] ?? matchData["alliance_color"])?.lowercased() == "red" ? AllianceColor.red : .blue
        let status = parseMatchStatus(matchData["status"])
        
        return MatchDraft(
            matchNumber: matchNumber,
            scheduledTime: scheduledTime,
            allianceColor: allianceColor,
            alliancePartner1: Int(matchData["alliance partner 1"] ?? matchData["alliancepartner1"] ?? matchData["alliance_partner_1"] ?? ""),
            alliancePartner2: Int(matchData["alliance partner 2"] ?? matchData["alliancepartner2"] ?? matchData["alliance_partner_2"] ?? ""),
            opponent1: Int(matchData["opponent 1"] ?? matchData["opponent1"] ?? matchData["opponent_1"] ?? ""),
            opponent2: Int(matchData["opponent 2"] ?? matchData["opponent2"] ?? matchData["opponent_2"] ?? ""),
            status: status,
            ourScore: Int(matchData["our score"] ?? matchData["ourscore"] ?? matchData["our_score"] ?? ""),
            opponentScore: Int(matchData["opponent score"] ?? matchData["opponentscore"] ?? matchData["opponent_score"] ?? ""),
            location: {
                let value = matchData["location"] ?? matchData["field"] ?? ""
                return value.isEmpty ? nil : value
            }()
        )
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "MM/dd/yyyy HH:mm",
            "yyyy-MM-dd"
        ]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
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
        case "in_progress", "running", "in progress":
            return .inProgress
        case "forfeited", "forfeit":
            return .forfeited
        default:
            return .scheduled
        }
    }
}

struct MatchDraft {
    var matchNumber: String
    var scheduledTime: Date
    var allianceColor: AllianceColor
    var alliancePartner1: Int?
    var alliancePartner2: Int?
    var opponent1: Int?
    var opponent2: Int?
    var status: MatchStatus
    var ourScore: Int?
    var opponentScore: Int?
    var location: String?
    
    init(
        matchNumber: String,
        scheduledTime: Date,
        allianceColor: AllianceColor,
        alliancePartner1: Int? = nil,
        alliancePartner2: Int? = nil,
        opponent1: Int? = nil,
        opponent2: Int? = nil,
        status: MatchStatus = .scheduled,
        ourScore: Int? = nil,
        opponentScore: Int? = nil,
        location: String? = nil
    ) {
        self.matchNumber = matchNumber
        self.scheduledTime = scheduledTime
        self.allianceColor = allianceColor
        self.alliancePartner1 = alliancePartner1
        self.alliancePartner2 = alliancePartner2
        self.opponent1 = opponent1
        self.opponent2 = opponent2
        self.status = status
        self.ourScore = ourScore
        self.opponentScore = opponentScore
        self.location = location
    }
    
    init(from match: Match) {
        self.init(
            matchNumber: match.matchNumber,
            scheduledTime: match.scheduledTime,
            allianceColor: match.allianceColor,
            alliancePartner1: match.alliancePartner1,
            alliancePartner2: match.alliancePartner2,
            opponent1: match.opponent1,
            opponent2: match.opponent2,
            status: match.status,
            ourScore: match.ourScore,
            opponentScore: match.opponentScore,
            location: match.location
        )
    }
    
    func makeMatch(teamId: UUID, id: UUID = UUID(), createdAt: Date = Date()) -> Match {
        Match(
            id: id,
            teamId: teamId,
            matchNumber: matchNumber,
            scheduledTime: scheduledTime,
            allianceColor: allianceColor,
            alliancePartner1: alliancePartner1,
            alliancePartner2: alliancePartner2,
            opponent1: opponent1,
            opponent2: opponent2,
            status: status,
            ourScore: ourScore,
            opponentScore: opponentScore,
            location: location,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
    
    func applying(to match: Match) -> Match {
        Match(
            id: match.id,
            teamId: match.teamId,
            matchNumber: matchNumber,
            scheduledTime: scheduledTime,
            allianceColor: allianceColor,
            alliancePartner1: alliancePartner1,
            alliancePartner2: alliancePartner2,
            opponent1: opponent1,
            opponent2: opponent2,
            status: status,
            ourScore: ourScore,
            opponentScore: opponentScore,
            location: location,
            createdAt: match.createdAt,
            updatedAt: Date()
        )
    }
}

struct MatchNote: Codable, Identifiable, Hashable {
    let id: UUID
    var body: String
    var createdAt: Date
}

// MARK: - Schedule Errors
enum ScheduleError: LocalizedError {
    case invalidFormat
    case invalidMatchData
    case importFailed
    case teamUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid schedule format"
        case .invalidMatchData:
            return "Invalid match data"
        case .importFailed:
            return "Failed to import schedule"
        case .teamUnavailable:
            return "Join or create a team to manage the match schedule."
        }
    }
}
//
