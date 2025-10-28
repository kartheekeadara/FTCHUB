//
//  WorkingTeamService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine

@MainActor
class WorkingTeamService: ObservableObject {
    @Published var currentTeam: Team?
    @Published var teamMembers: [Profile] = []
    @Published var events: [Event] = []
    @Published var tasks: [TeamTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        // Load mock team data
        currentTeam = Team(
            id: UUID(),
            name: "Mock Team 12345",
            number: "12345",
            school: "Mock High School",
            city: "Mock City",
            state: "Mock State",
            country: "USA",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        teamMembers = [
            Profile(
                id: UUID(),
                teamId: currentTeam?.id ?? UUID(),
                role: .admin,
                firstName: "John",
                lastName: "Doe",
                email: "john@example.com",
                phone: "123-456-7890",
                grade: 11,
                memberRole: .coach,
                experienceBadges: ["Programming", "Building"],
                emergencyContactName: "Jane Doe",
                emergencyContactPhone: "123-456-7891",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Profile(
                id: UUID(),
                teamId: currentTeam?.id ?? UUID(),
                role: .editor,
                firstName: "Jane",
                lastName: "Smith",
                email: "jane@example.com",
                phone: "123-456-7891",
                grade: 10,
                memberRole: .driver,
                experienceBadges: ["Driving", "Strategy"],
                emergencyContactName: "John Smith",
                emergencyContactPhone: "123-456-7892",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        events = [
            Event(
                id: UUID(),
                teamId: currentTeam?.id ?? UUID(),
                title: "Practice Session",
                description: "Weekly team practice",
                startDate: Date(),
                endDate: Date().addingTimeInterval(7200),
                location: "School Gym",
                eventType: .practice,
                status: .scheduled,
                googleCalendarId: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Event(
                id: UUID(),
                teamId: currentTeam?.id ?? UUID(),
                title: "Competition Day",
                description: "Regional competition",
                startDate: Date().addingTimeInterval(86400),
                endDate: Date().addingTimeInterval(172800),
                location: "Convention Center",
                eventType: .competition,
                status: .scheduled,
                googleCalendarId: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        tasks = [
            TeamTask(
                id: UUID(),
                teamId: currentTeam?.id ?? UUID(),
                title: "Robot Assembly",
                description: "Complete robot assembly for competition",
                status: .todo,
                priority: .high,
                assigneeId: nil,
                dueDate: Date().addingTimeInterval(86400 * 7), // 1 week from now
                createdBy: UUID(),
                createdAt: Date(),
                updatedAt: Date()
            ),
            TeamTask(
                id: UUID(),
                teamId: currentTeam?.id ?? UUID(),
                title: "Code Review",
                description: "Review autonomous code",
                status: .doing,
                priority: .medium,
                assigneeId: nil,
                dueDate: Date().addingTimeInterval(86400 * 3), // 3 days from now
                createdBy: UUID(),
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
    // MARK: - Team Management
    func createTeam(name: String, number: String, school: String?, city: String?, state: String?) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
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
        
        currentTeam = team
    }
    
    func joinTeam(teamNumber: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Mock joining a team
        currentTeam = Team(
            id: UUID(),
            name: "Team \(teamNumber)",
            number: teamNumber,
            school: "Mock School",
            city: "Mock City",
            state: "Mock State",
            country: "USA",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    func loadTeamData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Mock loading - data is already loaded in init
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
    }
    
    // MARK: - Events
    func createEvent(_ event: Event) async throws {
        events.append(event)
    }
    
    func updateEvent(_ event: Event) async throws {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }
    
    func deleteEvent(_ eventId: UUID) async throws {
        events.removeAll { $0.id == eventId }
    }
    
    // MARK: - Tasks
    func createTask(_ task: TeamTask) async throws {
        tasks.append(task)
    }
    
    func updateTask(_ task: TeamTask) async throws {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    func deleteTask(_ taskId: UUID) async throws {
        tasks.removeAll { $0.id == taskId }
    }
}
