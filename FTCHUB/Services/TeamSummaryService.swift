//
//  TeamSummaryService.swift
//  FTCHUB
//
//  Created on 11/16/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class TeamSummaryService: ObservableObject {
    @Published var summaries: [TeamScoutingSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    // MARK: - Summary Generation
    
    func generateSummary(
        for teamNumber: String,
        reports: [ScoutingReport],
        eventName: String?,
        scoutName: String?,
        teamId: UUID
    ) -> TeamScoutingSummary {
        let stats = calculateStats(from: reports)
        
        // Auto-generate insights
        let strengths = generateStrengths(from: stats, reports: reports)
        let weaknesses = generateWeaknesses(from: stats, reports: reports)
        let (primaryRole, secondaryRole) = generateRoleRecommendation(from: stats)
        let pickPriority = calculatePickPriority(from: stats)
        
        // Generate match tactics from data patterns
        let tactics = generateMatchTactics(from: stats, reports: reports)
        
        // Generate alliance fit
        let allianceFit = AllianceFit(
            idealPartners: generateIdealPartners(from: stats),
            pickPriority: pickPriority,
            priorityReason: generatePriorityReason(from: stats, pickPriority: pickPriority)
        )
        
        // Generate raw data links
        let rawDataLinks = "Full reports in FTC HUB → Reports → Team \(teamNumber) → last \(reports.count) matches; Trend: Analytics → Team Performance"
        
        return TeamScoutingSummary(
            id: UUID(),
            teamId: teamId,
            scoutedTeamNumber: teamNumber,
            eventName: eventName,
            matchesSampled: reports.count,
            scoutName: scoutName,
            lastUpdated: Date(),
            avgAutoArtifacts: stats.avgAutoArtifacts,
            autoSuccessRate: stats.autoSuccessRate,
            avgTeleopArtifacts: stats.avgTeleopArtifacts,
            avgEndgameSuccess: stats.avgEndgameSuccess,
            reliability: stats.reliability,
            avgPenalties: stats.avgPenalties,
            penaltyTypes: stats.penaltyTypes,
            consistency: stats.consistency,
            strengths: strengths,
            weaknesses: weaknesses,
            primaryRole: primaryRole,
            secondaryRole: secondaryRole,
            matchTactics: tactics,
            allianceFit: allianceFit,
            exploitationNotes: "",
            countermeasures: "",
            pitNotes: PitNotes(
                batteryHealth: "Unknown",
                knownFailureModes: [],
                humanFactors: ""
            ),
            quickActionItems: [],
            rawDataLinks: rawDataLinks,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Statistics Calculation
    
    private func calculateStats(from reports: [ScoutingReport]) -> SummaryStats {
        guard !reports.isEmpty else {
            return SummaryStats()
        }
        
        // Auto artifacts
        let autoArtifacts = reports.compactMap { $0.numericValue(for: "Auto Artifacts") }
        let avgAutoArtifacts = autoArtifacts.isEmpty ? 0 : autoArtifacts.reduce(0, +) / Double(autoArtifacts.count)
        
        // Auto success rate
        let autoSuccessCount = reports.filter { $0.boolValue(for: "Auto Success") == true }.count
        let autoSuccessRate = Double(autoSuccessCount) / Double(reports.count) * 100
        
        // Teleop artifacts
        let teleopArtifacts = reports.compactMap { $0.numericValue(for: "Teleop Artifacts") }
        let avgTeleopArtifacts = teleopArtifacts.isEmpty ? 0 : teleopArtifacts.reduce(0, +) / Double(teleopArtifacts.count)
        
        // Endgame success rate
        let endgameSuccessCount = reports.filter { $0.boolValue(for: "Endgame Success") == true }.count
        let avgEndgameSuccess = Double(endgameSuccessCount) / Double(reports.count) * 100
        
        // Reliability
        let okCount = reports.filter { report in
            report.stringValue(for: "Reliability Flag") == "OK"
        }.count
        let reliability = Double(okCount) / Double(reports.count) * 100
        
        // Penalties
        let penaltyCounts = reports.compactMap { report -> Double? in
            let penaltyString = report.stringValue(for: "Penalties") ?? ""
            if penaltyString.lowercased() == "none" || penaltyString.isEmpty {
                return 0
            }
            // Count commas + 1 as rough estimate, or parse if structured
            let count = penaltyString.split(separator: ",").count
            return Double(count)
        }
        let avgPenalties = penaltyCounts.isEmpty ? 0 : penaltyCounts.reduce(0, +) / Double(penaltyCounts.count)
        
        // Penalty types
        let allPenaltyStrings = reports.compactMap { $0.stringValue(for: "Penalties") }
        let penaltyTypes = extractPenaltyTypes(from: allPenaltyStrings)
        
        // Consistency (standard deviation of total artifacts)
        let totalArtifacts = reports.map { report in
            (report.numericValue(for: "Auto Artifacts") ?? 0) + (report.numericValue(for: "Teleop Artifacts") ?? 0)
        }
        let consistency = calculateStandardDeviation(totalArtifacts)
        
        return SummaryStats(
            avgAutoArtifacts: avgAutoArtifacts,
            autoSuccessRate: autoSuccessRate,
            avgTeleopArtifacts: avgTeleopArtifacts,
            avgEndgameSuccess: avgEndgameSuccess,
            reliability: reliability,
            avgPenalties: avgPenalties,
            penaltyTypes: penaltyTypes,
            consistency: consistency
        )
    }
    
    private func extractPenaltyTypes(from penaltyStrings: [String]) -> [String] {
        var types: Set<String> = []
        for penaltyString in penaltyStrings {
            if penaltyString.lowercased() == "none" || penaltyString.isEmpty {
                continue
            }
            let parts = penaltyString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            for part in parts {
                if !part.isEmpty {
                    types.insert(part.capitalized)
                }
            }
        }
        return Array(types).sorted()
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    // MARK: - Auto-Generation Logic
    
    private func generateStrengths(from stats: SummaryStats, reports: [ScoutingReport]) -> [String] {
        var strengths: [String] = []
        
        if stats.autoSuccessRate >= 80 {
            strengths.append("Reliable autonomous preload (scores ~\(String(format: "%.1f", stats.avgAutoArtifacts)) artifacts consistently, \(String(format: "%.0f", stats.autoSuccessRate))% success rate)")
        }
        
        if stats.avgTeleopArtifacts >= 6 {
            strengths.append("High teleop throughput (\(String(format: "%.1f", stats.avgTeleopArtifacts)) artifacts/match when unobstructed)")
        }
        
        if stats.reliability >= 85 {
            strengths.append("Consistent performance — \(String(format: "%.0f", stats.reliability))% reliability across matches")
        }
        
        if stats.avgPenalties < 0.5 {
            strengths.append("Clean play — minimal penalties (\(String(format: "%.1f", stats.avgPenalties))/match)")
        }
        
        if stats.avgEndgameSuccess >= 70 {
            strengths.append("Strong endgame execution — \(String(format: "%.0f", stats.avgEndgameSuccess))% success rate")
        }
        
        // Ensure we have at least 2-3 strengths
        if strengths.count < 2 {
            if stats.avgAutoArtifacts > 0 {
                strengths.append("Capable autonomous scoring")
            }
            if stats.avgTeleopArtifacts > 0 {
                strengths.append("Active teleop participation")
            }
        }
        
        return Array(strengths.prefix(4)) // Max 4
    }
    
    private func generateWeaknesses(from stats: SummaryStats, reports: [ScoutingReport]) -> [String] {
        var weaknesses: [String] = []
        
        if stats.avgEndgameSuccess < 60 {
            let failureRate = 100 - stats.avgEndgameSuccess
            weaknesses.append("Endgame reliability concerns — fails to complete endgame in \(String(format: "%.0f", failureRate))% of matches")
        }
        
        if stats.reliability < 70 {
            weaknesses.append("Mechanical issues observed — \(String(format: "%.0f", 100 - stats.reliability))% of matches had reliability problems")
        }
        
        if stats.avgPenalties > 1 {
            weaknesses.append("Penalty-prone under pressure — averages \(String(format: "%.1f", stats.avgPenalties)) penalties per match")
        }
        
        if stats.consistency > 10 {
            weaknesses.append("Inconsistent scoring — high variance (\(String(format: "%.1f", stats.consistency)) point SD) across matches")
        }
        
        if stats.avgTeleopArtifacts < 3 && stats.avgAutoArtifacts < 1 {
            weaknesses.append("Low scoring output — limited artifact placement capability")
        }
        
        // Ensure we have at least 2-3 weaknesses
        if weaknesses.count < 2 {
            if stats.autoSuccessRate < 50 {
                weaknesses.append("Autonomous execution needs improvement")
            }
            if stats.avgEndgameSuccess < 50 {
                weaknesses.append("Endgame completion inconsistent")
            }
        }
        
        return Array(weaknesses.prefix(4)) // Max 4
    }
    
    private func generateRoleRecommendation(from stats: SummaryStats) -> (primary: String, secondary: String) {
        let teleopScore = stats.avgTeleopArtifacts
        let autoScore = stats.avgAutoArtifacts
        let endgameScore = stats.avgEndgameSuccess
        let reliabilityScore = stats.reliability
        
        // Determine primary role
        var primary: String
        if teleopScore >= 6 && endgameScore < 60 {
            primary = "Teleop scorer / cycle partner"
        } else if endgameScore >= 80 {
            primary = "Anchor / endgame specialist"
        } else if teleopScore >= 4 && reliabilityScore >= 75 {
            primary = "Transporter / cycle extender"
        } else if autoScore >= 2 && autoScore < 4 {
            primary = "Balanced scorer"
        } else {
            primary = "Support role"
        }
        
        // Determine secondary role
        var secondary: String
        if endgameScore >= 70 && teleopScore < 5 {
            secondary = "Endgame backup"
        } else if reliabilityScore >= 80 && teleopScore >= 4 {
            secondary = "Reliable cycle partner"
        } else {
            secondary = "Flexible support"
        }
        
        return (primary, secondary)
    }
    
    private func calculatePickPriority(from stats: SummaryStats) -> Int {
        // Composite score calculation
        var score: Double = 0
        
        // Auto contribution (0-25 points)
        score += (stats.autoSuccessRate / 100) * 25
        
        // Teleop contribution (0-35 points)
        score += min((stats.avgTeleopArtifacts / 10) * 35, 35)
        
        // Endgame contribution (0-20 points)
        score += (stats.avgEndgameSuccess / 100) * 20
        
        // Reliability contribution (0-20 points)
        score += (stats.reliability / 100) * 20
        
        // Penalty deduction
        score -= min(stats.avgPenalties * 5, 10)
        
        // Convert to priority (1-5 scale, inverted)
        // Higher score = lower priority number (better pick)
        if score >= 80 {
            return 1 // Must-pick
        } else if score >= 65 {
            return 2 // Strong candidate
        } else if score >= 50 {
            return 3 // Consider
        } else if score >= 35 {
            return 4 // Low priority
        } else {
            return 5 // Avoid
        }
    }
    
    private func generateMatchTactics(from stats: SummaryStats, reports: [ScoutingReport]) -> MatchTactics {
        let autoSuccess = stats.autoSuccessRate >= 70
        let teleopStrong = stats.avgTeleopArtifacts >= 5
        let endgameWeak = stats.avgEndgameSuccess < 60
        
        let autonomous = autoSuccess
            ? "Let them run autonomous — they score preloads reliably; don't block starting zone"
            : "Monitor their autonomous — may need support if they struggle"
        
        let teleop = teleopStrong && endgameWeak
            ? "Pair them with a partner that finishes endgame RP. Keep them on outside lanes for longer cycles"
            : teleopStrong
            ? "Assign them to high-throughput cycles — averages \(String(format: "%.1f", stats.avgTeleopArtifacts)) artifacts/match"
            : "Use them for support cycles or defense"
        
        let defense = stats.avgPenalties > 0.5
            ? "Apply light contact to force errors — they're penalty-prone under pressure"
            : "Use short harassment to disrupt cycles; avoid continuous contact"
        
        let endgame = endgameWeak
            ? "Don't depend on them for RP unless they show two consecutive successful endgames in scouting"
            : "They can reliably complete endgame — assign RP responsibility"
        
        return MatchTactics(
            autonomous: autonomous,
            teleop: teleop,
            defense: defense,
            endgame: endgame
        )
    }
    
    private func generateIdealPartners(from stats: SummaryStats) -> String {
        var needs: [String] = []
        
        if stats.avgEndgameSuccess < 60 {
            needs.append("Strong endgame specialist (park/climb ~95%)")
        }
        
        if stats.avgTeleopArtifacts >= 6 {
            needs.append("Consistent loader to minimize travel time")
        }
        
        if stats.reliability < 75 {
            needs.append("Reliable partner to compensate for mechanical issues")
        }
        
        if stats.avgAutoArtifacts < 1 {
            needs.append("Strong autonomous scorer")
        }
        
        if needs.isEmpty {
            return "Flexible partner — they can adapt to various roles"
        }
        
        return needs.joined(separator: ", and ")
    }
    
    private func generatePriorityReason(from stats: SummaryStats, pickPriority: Int) -> String {
        switch pickPriority {
        case 1:
            return "Excellent all-around performance — high scoring, reliable, consistent"
        case 2:
            if stats.avgTeleopArtifacts >= 6 {
                return "Strong scorer but needs endgame partner"
            } else if stats.avgEndgameSuccess >= 80 {
                return "Reliable endgame specialist but limited teleop"
            } else {
                return "Good performance with minor weaknesses"
            }
        case 3:
            return "Average performance — consider if no better options available"
        case 4:
            return "Below average — only consider if desperate"
        case 5:
            return "Avoid — multiple reliability or performance issues"
        default:
            return "Needs evaluation"
        }
    }
    
    // MARK: - Database Operations
    
    func saveSummary(_ summary: TeamScoutingSummary) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            var summaryToSave = summary
            summaryToSave.updatedAt = Date()
            summaryToSave.lastUpdated = Date()
            
            // Check if summary exists
            let existing: [TeamScoutingSummary] = try await supabase
                .from("team_scouting_summaries")
                .select()
                .eq("team_id", value: summary.teamId)
                .eq("scouted_team_number", value: summary.scoutedTeamNumber)
                .eq("event_name", value: summary.eventName ?? "")
                .execute()
                .value
            
            if let existingSummary = existing.first {
                // Update existing
                try await supabase
                    .from("team_scouting_summaries")
                    .update(summaryToSave)
                    .eq("id", value: existingSummary.id)
                    .execute()
            } else {
                // Insert new
                try await supabase
                    .from("team_scouting_summaries")
                    .insert(summaryToSave)
                    .execute()
            }
            
            try await loadSummaries(teamId: summary.teamId)
        } catch {
            errorMessage = "Failed to save summary: \(error.localizedDescription)"
            throw error
        }
    }
    
    func loadSummaries(teamId: UUID) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let loaded: [TeamScoutingSummary] = try await supabase
                .from("team_scouting_summaries")
                .select()
                .eq("team_id", value: teamId)
                .order("last_updated", ascending: false)
                .execute()
                .value
            
            summaries = loaded
        } catch {
            errorMessage = "Failed to load summaries: \(error.localizedDescription)"
            summaries = []
        }
    }
    
    func getSummary(for teamNumber: String, eventName: String? = nil) -> TeamScoutingSummary? {
        return summaries.first { summary in
            summary.scoutedTeamNumber == teamNumber &&
            summary.eventName == eventName
        }
    }
    
    func deleteSummary(_ summary: TeamScoutingSummary) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("team_scouting_summaries")
                .delete()
                .eq("id", value: summary.id)
                .execute()
            
            summaries.removeAll { $0.id == summary.id }
        } catch {
            errorMessage = "Failed to delete summary: \(error.localizedDescription)"
            throw error
        }
    }
}

// MARK: - Supporting Structures

private struct SummaryStats {
    var avgAutoArtifacts: Double = 0
    var autoSuccessRate: Double = 0
    var avgTeleopArtifacts: Double = 0
    var avgEndgameSuccess: Double = 0
    var reliability: Double = 0
    var avgPenalties: Double = 0
    var penaltyTypes: [String] = []
    var consistency: Double = 0
}

