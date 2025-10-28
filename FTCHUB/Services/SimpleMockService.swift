//
//  SimpleMockService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine

// Simple mock service that provides static data
class SimpleMockService: ObservableObject {
    static let shared = SimpleMockService()
    
    // Mock data
    @Published var teams: [Team] = [
        Team(
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
    ]
    
    @Published var profiles: [Profile] = [
        Profile(
            id: UUID(),
            teamId: UUID(),
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
        )
    ]
    
    @Published var events: [Event] = [
        Event(
            id: UUID(),
            teamId: UUID(),
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
        )
    ]
    
    @Published var tasks: [TeamTask] = [
        TeamTask(
            id: UUID(),
            teamId: UUID(),
            title: "Robot Assembly",
            description: "Complete robot assembly for competition",
            status: .todo,
            priority: .high,
            assigneeId: nil,
            dueDate: Date().addingTimeInterval(86400 * 7), // 1 week from now
            createdBy: UUID(),
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    @Published var scoutingTemplates: [ScoutingTemplate] = [
        ScoutingTemplate(
            id: UUID(),
            teamId: UUID(),
            name: "DECODE Game Template",
            description: "Template for DECODE game scouting",
            isDefault: true,
            templateData: ScoutingFormData(),
            createdBy: UUID(),
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    @Published var scoutingReports: [ScoutingReport] = [
        ScoutingReport(
            id: UUID(),
            teamId: UUID(),
            templateId: UUID(),
            scoutedTeamNumber: "12345",
            matchNumber: "1",
            eventName: "Mock Competition",
            phase: .auto,
            scoutId: nil,
            reportData: ["score": "100", "notes": "Great performance"],
            notes: "Mock scouting report",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    @Published var inventoryItems: [InventoryItem] = [
        InventoryItem(
            id: UUID(),
            teamId: UUID(),
            sku: "REV-001",
            name: "REV Control Hub",
            manufacturer: "REV Robotics",
            partNumber: "REV-31-1595",
            category: "Electronics",
            location: "Workbench A",
            quantityOnHand: 2,
            lowStockThreshold: 1,
            unitCost: 199.99,
            description: "REV Control Hub for robot control",
            imageUrl: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    private init() {}
}
