//
//  ScoutingService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class ScoutingService: ObservableObject {
    @Published var scoutingTemplates: [ScoutingTemplate] = []
    @Published var scoutingReports: [ScoutingReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private(set) var activeTeamId: UUID?
    private let supabase = SupabaseService.shared.client
    
    init() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            loadMockData()
        }
    }
    
    var currentTeamId: UUID? {
        activeTeamId
    }
    
    var hasTeamContext: Bool {
        activeTeamId != nil
    }
    
    /// Single source of truth for whether a template can be deleted by the user.
    /// Protects the seeded DECODE system template; allows everything else.
    func isUserDeletable(_ template: ScoutingTemplate) -> Bool {
        !(template.isDefault && template.name == "DECODE Match Scouting")
    }
    
    var userDeletableTemplates: [ScoutingTemplate] {
        scoutingTemplates.filter(isUserDeletable)
    }
    
    // MARK: - Analytics
    var uniqueTeamsScoutedCount: Int {
        let identifiers = scoutingReports
            .map { $0.scoutedTeamNumber.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Set(identifiers).count
    }
    
    var averageOverallQuality: Double? {
        averageNumericValue(for: "Overall Quality")
    }
    
    var averageAutonomousReliability: Double? {
        averageNumericValue(for: "Autonomous Reliability")
    }
    
    var averageAllianceSelectionRating: Double? {
        averageNumericValue(for: "Alliance Selection Rating")
    }
    
    var averageTeleopClassifiedArtifacts: Double? {
        averageNumericValue(for: "Teleop Classified Artifacts")
    }
    
    var movementRPCompletion: Double {
        ratio(for: "Movement RP")
    }
    
    var goalRPCompletion: Double {
        ratio(for: "Goal RP")
    }
    
    var patternRPCompletion: Double {
        ratio(for: "Pattern RP")
    }
    
    var topStrategyFocuses: [(label: String, count: Int)] {
        let focusCounts = scoutingReports
            .compactMap { $0.stringValue(for: "Strategy Focus") }
            .map { $0.capitalized }
        
        let grouped = Dictionary(grouping: focusCounts, by: { $0 })
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0 < rhs.0
                }
                return lhs.1 > rhs.1
            }
        
        return Array(grouped.prefix(3))
    }
    
    var reportsPerDay: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: scoutingReports) { report in
            calendar.startOfDay(for: report.createdAt)
        }
        return grouped
            .map { (date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }
    
    var startingPositionBreakdown: [(label: String, count: Int)] {
        breakdown(for: "Starting Position")
    }
    
    var driveBaseBreakdown: [(label: String, count: Int)] {
        breakdown(for: "Drive Base")
    }
    
    var preloadArtifactBreakdown: [(label: String, count: Int)] {
        breakdown(for: "Preload Artifact")
    }
    
    func updateTeamContext(teamId: UUID?) {
        guard activeTeamId != teamId else { return }
        activeTeamId = teamId
        Task { await loadScoutingData() }
    }
    
    func loadScoutingData() async {
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
            loadMockData()
            return
        }
        
        guard let teamId = activeTeamId else {
            scoutingTemplates = []
            scoutingReports = []
            errorMessage = "Join or create a team to start collecting scouting data."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let templates: [ScoutingTemplate] = try await supabase
                .from("scouting_templates")
                .select()
                .eq("team_id", value: teamId)
                .order("name", ascending: true)
                .execute()
                .value
            
            let reports: [ScoutingReport] = try await supabase
                .from("scouting_reports")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            if templates.isEmpty {
                let defaultTemplate = ScoutingTemplate.defaultDecode(teamId: teamId)
                do {
                    try await supabase
                        .from("scouting_templates")
                        .insert(defaultTemplate)
                        .execute()
                    scoutingTemplates = [defaultTemplate]
                } catch {
                    TelemetryService.shared.logError(error, context: ["action": "insert_default_template"])
                    scoutingTemplates = [defaultTemplate]
                }
            } else {
                scoutingTemplates = templates
            }
            scoutingReports = reports
        } catch {
            errorMessage = "Unable to load scouting data: \(error.localizedDescription)"
            let fallbackTemplate = ScoutingTemplate.defaultDecode(teamId: teamId)
            scoutingTemplates = [fallbackTemplate]
            scoutingReports = []
        }
    }
    
    private func loadMockData() {
        scoutingTemplates = [ScoutingTemplate.sample]
        scoutingReports = [ScoutingReport.sample]
        errorMessage = nil
    }
    
    // MARK: - Template Operations
    func createScoutingTemplate(template: ScoutingTemplate) async throws {
        if let data = try? JSONEncoder().encode(template.templateData) {
            try InputValidator.validateScoutingTemplateDataSize(data)
        }
        guard let teamId = activeTeamId else {
            errorMessage = "Join or create a team before saving scouting templates."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            var templateToSave = template
            templateToSave.teamId = teamId
            templateToSave.updatedAt = Date()
            
            try await supabase
                .from("scouting_templates")
                .insert(templateToSave)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateScoutingTemplate(template: ScoutingTemplate) async throws {
        guard activeTeamId != nil else {
            errorMessage = "Join or create a team before editing scouting templates."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            var templateToUpdate = template
            templateToUpdate.updatedAt = Date()
            
            try await supabase
                .from("scouting_templates")
                .update(templateToUpdate)
                .eq("id", value: template.id)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteScoutingTemplate(template: ScoutingTemplate) async throws {
        guard activeTeamId != nil else {
            errorMessage = "Join or create a team before modifying scouting templates."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("scouting_templates")
                .delete()
                .eq("id", value: template.id)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func duplicateScoutingTemplate(template: ScoutingTemplate) async throws {
        guard let teamId = activeTeamId else {
            throw ScoutingTemplateError.noTeamContext
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let now = Date()
        var copyData = ScoutingFormData()
        copyData.version = template.templateData.version
        copyData.lastModified = now
        copyData.sections = template.templateData.sections
            .sorted(by: { $0.order < $1.order })
            .enumerated()
            .map { sectionIndex, section in
                let fields = section.fields
                    .sorted(by: { $0.order < $1.order })
                    .enumerated()
                    .map { fieldIndex, field in
                        ScoutingField(
                            type: field.type,
                            title: field.title,
                            description: field.description,
                            isRequired: field.isRequired,
                            options: field.options,
                            minValue: field.minValue,
                            maxValue: field.maxValue,
                            step: field.step,
                            order: fieldIndex
                        )
                    }
                return ScoutingSection(title: section.title, fields: fields, order: sectionIndex)
            }
        
        let duplicate = ScoutingTemplate(
            id: UUID(),
            teamId: teamId,
            name: uniqueTemplateName(basedOn: template.name),
            description: template.description,
            isDefault: false,
            templateData: copyData,
            createdBy: supabase.auth.currentUser?.id,
            createdAt: now,
            updatedAt: now
        )
        
        do {
            try await supabase
                .from("scouting_templates")
                .insert(duplicate)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Report Operations
    func createScoutingReport(report: ScoutingReport) async throws {
        guard let teamId = activeTeamId else {
            errorMessage = "Join or create a team before saving scouting reports."
            return
        }
        
        _ = try InputValidator.ScoutingReportInput(
            notes: report.notes,
            teamNumber: report.scoutedTeamNumber
        )
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        var reportToSave = report
        reportToSave.teamId = teamId
        reportToSave.updatedAt = Date()
        
        // Set scout_id to current user if available
        do {
            let session = try await supabase.auth.session
            reportToSave.scoutId = session.user.id
        } catch {
            // If we can't get the session, leave scout_id as nil
            // The RLS policy will still allow the operation if user is in the team
        }
        
        do {
            try await supabase
                .from("scouting_reports")
                .insert(reportToSave)
                .execute()
            await loadScoutingData()
        } catch {
            if shouldQueueScoutingReportForOfflineSync(error),
               let data = try? JSONEncoder().encode(reportToSave) {
                LocalStorage.shared.addToSyncQueue(
                    operationType: "CREATE",
                    tableName: "scouting_reports",
                    recordId: reportToSave.id.uuidString,
                    data: data
                )
                NotificationCenter.default.post(name: .ftchubScoutReportQueuedLocally, object: nil)
                errorMessage = nil
                return
            }
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    private func shouldQueueScoutingReportForOfflineSync(_ error: Error) -> Bool {
        if error is CancellationError { return false }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed:
                return true
            default:
                break
            }
        }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain { return true }
        if let underlying = ns.userInfo[NSUnderlyingErrorKey] as? Error {
            return shouldQueueScoutingReportForOfflineSync(underlying)
        }
        let msg = ns.localizedDescription.lowercased()
        if msg.contains("network") || msg.contains("internet") { return true }
        if msg.contains("connection") && msg.contains("lost") { return true }
        return false
    }
    
    func updateScoutingReport(report: ScoutingReport) async throws {
        guard activeTeamId != nil else {
            errorMessage = "Join or create a team before editing scouting reports."
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            var reportToUpdate = report
            reportToUpdate.updatedAt = Date()
            
            try await supabase
                .from("scouting_reports")
                .update(reportToUpdate)
                .eq("id", value: report.id)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteScoutingReport(report: ScoutingReport) async throws {
        guard activeTeamId != nil else {
            errorMessage = "Join or create a team before deleting scouting reports."
            throw ScoutingTemplateError.noTeamContext
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("scouting_reports")
                .delete()
                .eq("id", value: report.id)
                .execute()
            
            // Remove from local array immediately for instant UI update
            scoutingReports.removeAll { $0.id == report.id }
            
            // Reload from server to ensure consistency
            await loadScoutingData()
        } catch {
            errorMessage = "Failed to delete report: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Analytics
    func getTeamPerformance(teamNumber: String) -> [ScoutingReport] {
        return scoutingReports.filter { $0.scoutedTeamNumber == teamNumber }
    }
    
    func getAverageScore(for teamNumber: String) -> Double? {
        let teamReports = getTeamPerformance(teamNumber: teamNumber)
        guard !teamReports.isEmpty else { return nil }
        
        // For now, return a simple count as we don't have complex scoring
        return Double(teamReports.count)
    }
    
    func getTopTeams(limit: Int = 10) -> [(String, Int)] {
        let teamCounts = Dictionary(grouping: scoutingReports, by: { $0.scoutedTeamNumber })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return Array(teamCounts.prefix(limit))
    }
    
    /// Per-team averages from **this team's** scouting reports (Strategy / compare tools).
    func strategyScoutSummary(for teamNumber: String) -> TeamStrategyScoutSummary? {
        let reps = getTeamPerformance(teamNumber: teamNumber)
        guard !reps.isEmpty else { return nil }
        func avg(_ key: String) -> Double? {
            let vals = reps.compactMap { $0.numericValue(for: key) }
            guard !vals.isEmpty else { return nil }
            return vals.reduce(0, +) / Double(vals.count)
        }
        let last = reps.map(\.createdAt).max()
        return TeamStrategyScoutSummary(
            teamNumber: teamNumber,
            reportCount: reps.count,
            avgOverallQuality: avg("Overall Quality"),
            avgAutonomousReliability: avg("Autonomous Reliability"),
            avgAllianceSelectionRating: avg("Alliance Selection Rating"),
            lastReportDate: last
        )
    }
    
    // MARK: - Summary Helpers
    func getReports(for teamNumber: String, eventName: String? = nil) -> [ScoutingReport] {
        var reports = scoutingReports.filter { $0.scoutedTeamNumber == teamNumber }
        if let eventName = eventName {
            reports = reports.filter { $0.eventName == eventName }
        }
        return reports
    }
    
    func hasReports(for teamNumber: String) -> Bool {
        return !scoutingReports.filter { $0.scoutedTeamNumber == teamNumber }.isEmpty
    }
    
    func getUniqueTeamNumbers() -> [String] {
        return Array(Set(scoutingReports.map { $0.scoutedTeamNumber })).sorted()
    }
    
    func getUniqueEventNames() -> [String] {
        return Array(Set(scoutingReports.compactMap { $0.eventName })).sorted()
    }
    
    // MARK: - Default Template Creation
    func createDefaultDecodeTemplate() async throws {
        let template = ScoutingTemplate.sample
        
        // Only create if it doesn't exist
        let existingTemplates = scoutingTemplates.filter { $0.name == template.name }
        if existingTemplates.isEmpty {
            try await createScoutingTemplate(template: template)
        }
    }
}

private extension ScoutingService {
    func averageNumericValue(for key: String) -> Double? {
        let values = scoutingReports.compactMap { $0.numericValue(for: key) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
    
    func ratio(for key: String) -> Double {
        let values = scoutingReports.compactMap { $0.boolValue(for: key) }
        guard !values.isEmpty else { return 0 }
        let positives = values.filter { $0 }.count
        return Double(positives) / Double(values.count)
    }
    
    func breakdown(for key: String) -> [(label: String, count: Int)] {
        let labels = scoutingReports
            .compactMap { $0.stringValue(for: key)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let grouped = Dictionary(grouping: labels, by: { $0.capitalized })
            .map { ($0.key, $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.1 == rhs.1 {
                    return lhs.0 < rhs.0
                }
                return lhs.1 > rhs.1
            }
        return grouped
    }
    
    func uniqueTemplateName(basedOn name: String) -> String {
        let base = name.isEmpty ? "Template" : name
        var candidate = "\(base) Copy"
        var index = 2
        let existingNames = Set(scoutingTemplates.map { $0.name.lowercased() })
        
        while existingNames.contains(candidate.lowercased()) {
            candidate = "\(base) Copy \(index)"
            index += 1
        }
        
        return candidate
    }
}

enum ScoutingTemplateError: LocalizedError {
    case noTeamContext
    
    var errorDescription: String? {
        switch self {
        case .noTeamContext:
            return "Join or create a team to manage scouting templates."
        }
    }
}

// MARK: - Strategy hub summaries

struct TeamStrategyScoutSummary: Equatable {
    let teamNumber: String
    let reportCount: Int
    let avgOverallQuality: Double?
    let avgAutonomousReliability: Double?
    let avgAllianceSelectionRating: Double?
    let lastReportDate: Date?
    
    var avgOverallFormatted: String { Self.formatMetric(avgOverallQuality) }
    var avgAutoFormatted: String { Self.formatMetric(avgAutonomousReliability) }
    var avgAllianceFormatted: String { Self.formatMetric(avgAllianceSelectionRating) }
    
    private static func formatMetric(_ value: Double?) -> String {
        guard let value, value.isFinite, !value.isNaN else { return "—" }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}