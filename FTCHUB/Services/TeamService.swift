//
//  TeamService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class TeamService: ObservableObject {
    @Published var currentTeam: Team?
    @Published var teamMembers: [Profile] = []
    @Published var events: [Event] = []
    @Published var tasks: [TeamTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    init() {
        // Set up mock data for previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.currentTeam = Team.sample
            self.teamMembers = [Profile.sample]
            self.events = []
            self.tasks = []
        }
    }
    
    // MARK: - Team Management
    func createTeam(name: String, number: String, school: String?, city: String?, state: String?) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let team = Team(
                id: UUID(),
                name: name,
                number: number,
                school: school,
                city: city,
                state: state,
                country: "USA",
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await supabase
                .from("teams")
                .insert(team)
                .execute()
            
            currentTeam = team
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func joinTeam(teamNumber: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response: [Team] = try await supabase
                .from("teams")
                .select()
                .eq("number", value: teamNumber)
                .execute()
                .value
            
            guard let team = response.first else {
                throw TeamError.teamNotFound
            }
            
            // Update user's team_id
            try await supabase
                .from("profiles")
                .update(["team_id": team.id])
                .eq("id", value: supabase.auth.currentUser?.id)
                .execute()
            
            currentTeam = team
            await loadTeamData()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func loadTeamData() async {
        guard let teamId = currentTeam?.id else { return }
        
        do {
            // Load team members
            let members: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("team_id", value: teamId)
                .execute()
                .value
            
            teamMembers = members
            
            // Load events
            let teamEvents: [Event] = try await supabase
                .from("events")
                .select()
                .eq("team_id", value: teamId)
                .order("start_date", ascending: true)
                .execute()
                .value
            
            events = teamEvents
            
            // Load tasks
            let teamTasks: [TeamTask] = try await supabase
                .from("tasks")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            tasks = teamTasks
        } catch {
            print("Failed to load team data: \(error)")
            errorMessage = "Failed to load team data"
        }
    }
    
    // MARK: - Event Management
    func createEvent(title: String, description: String?, startDate: Date, endDate: Date?, location: String?, eventType: EventType) async throws {
        guard let teamId = currentTeam?.id else { throw TeamError.noTeamSelected }
        
        let event = Event(
            id: UUID(),
            teamId: teamId,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            location: location,
            eventType: eventType,
            status: .scheduled,
            googleCalendarId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await supabase
            .from("events")
            .insert(event)
            .execute()
        
        await loadTeamData()
    }
    
    func updateEvent(_ event: Event) async throws {
        try await supabase
            .from("events")
            .update(event)
            .eq("id", value: event.id)
            .execute()
        
        await loadTeamData()
    }
    
    func deleteEvent(_ event: Event) async throws {
        try await supabase
            .from("events")
            .delete()
            .eq("id", value: event.id)
            .execute()
        
        await loadTeamData()
    }
    
    // MARK: - Task Management
    func createTask(title: String, description: String?, priority: TaskPriority, assigneeId: UUID?, dueDate: Date?) async throws {
        guard let teamId = currentTeam?.id,
              let currentUserId = supabase.auth.currentUser?.id else { throw TeamError.noTeamSelected }
        
        let task = TeamTask(
            id: UUID(),
            teamId: teamId,
            title: title,
            description: description,
            status: .todo,
            priority: priority,
            assigneeId: assigneeId,
            dueDate: dueDate,
            createdBy: currentUserId,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await supabase
            .from("tasks")
            .insert(task)
            .execute()
        
        await loadTeamData()
    }
    
    func updateTask(_ task: TeamTask) async throws {
        try await supabase
            .from("tasks")
            .update(task)
            .eq("id", value: task.id)
            .execute()
        
        await loadTeamData()
    }
    
    func deleteTask(_ task: TeamTask) async throws {
        try await supabase
            .from("tasks")
            .delete()
            .eq("id", value: task.id)
            .execute()
        
        await loadTeamData()
    }
}

enum TeamError: LocalizedError {
    case noTeamSelected
    case teamNotFound
    case invalidTeamNumber
    
    var errorDescription: String? {
        switch self {
        case .noTeamSelected:
            return "No team selected"
        case .teamNotFound:
            return "Team not found"
        case .invalidTeamNumber:
            return "Invalid team number"
        }
    }
}
