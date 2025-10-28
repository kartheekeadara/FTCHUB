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
    
    private let supabase = SupabaseService.shared.client
    
    init() {
        // Don't automatically load data in init to prevent preview crashes
        
        // Set up mock data for previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.scoutingTemplates = [ScoutingTemplate.sample]
            self.scoutingReports = [ScoutingReport.sample]
        } else {
            // Initialize with empty arrays for runtime
            self.scoutingTemplates = []
            self.scoutingReports = []
        }
    }
    
    func loadScoutingData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // TODO: Replace with actual team_id from AuthService.currentUser.teamId
            guard let teamId = UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else { // Example UUID
                errorMessage = "Team ID not available."
                return
            }
            
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
            
            self.scoutingTemplates = templates
            self.scoutingReports = reports
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading scouting data: \(error)")
        }
    }
    
    // MARK: - Template Operations
    func createScoutingTemplate(template: ScoutingTemplate) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("scouting_templates")
                .insert(template)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateScoutingTemplate(template: ScoutingTemplate) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("scouting_templates")
                .update(template)
                .eq("id", value: template.id)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteScoutingTemplate(template: ScoutingTemplate) async throws {
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
    
    // MARK: - Report Operations
    func createScoutingReport(report: ScoutingReport) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("scouting_reports")
                .insert(report)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateScoutingReport(report: ScoutingReport) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("scouting_reports")
                .update(report)
                .eq("id", value: report.id)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteScoutingReport(report: ScoutingReport) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("scouting_reports")
                .delete()
                .eq("id", value: report.id)
                .execute()
            await loadScoutingData()
        } catch {
            errorMessage = error.localizedDescription
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