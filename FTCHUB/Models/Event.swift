//
//  Event.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

enum EventType: String, Codable, CaseIterable {
    case practice = "practice"
    case competition = "competition"
    case meeting = "meeting"
    case outreach = "outreach"
    
    var displayName: String {
        switch self {
        case .practice: return "Practice"
        case .competition: return "Competition"
        case .meeting: return "Meeting"
        case .outreach: return "Outreach"
        }
    }
    
    var icon: String {
        switch self {
        case .practice: return "hammer.fill"
        case .competition: return "trophy.fill"
        case .meeting: return "person.3.fill"
        case .outreach: return "megaphone.fill"
        }
    }
    
    var color: String {
        switch self {
        case .practice: return "blue"
        case .competition: return "orange"
        case .meeting: return "green"
        case .outreach: return "purple"
        }
    }
}

enum EventStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

struct Event: Codable, Identifiable, Hashable {
    let id: UUID
    let teamId: UUID
    let title: String
    let description: String?
    let startDate: Date
    let endDate: Date?
    let location: String?
    let eventType: EventType
    let status: EventStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location
        case teamId = "team_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case eventType = "event_type"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var duration: TimeInterval {
        let end = endDate ?? startDate.addingTimeInterval(3600) // Default 1 hour
        return end.timeIntervalSince(startDate)
    }
    
    var isAllDay: Bool {
        return duration >= 86400 // 24 hours
    }
}
