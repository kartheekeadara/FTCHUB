//
//  Task.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

enum TaskStatus: String, Codable, CaseIterable {
    case todo = "todo"
    case doing = "doing"
    case done = "done"
    
    var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .doing: return "Doing"
        case .done: return "Done"
        }
    }
    
    var color: String {
        switch self {
        case .todo: return "gray"
        case .doing: return "blue"
        case .done: return "green"
        }
    }
}

enum TaskPriority: Int, Codable, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

struct TeamTask: Codable, Identifiable, Hashable {
    let id: UUID
    let teamId: UUID
    let title: String
    let description: String?
    let status: TaskStatus
    let priority: TaskPriority
    let assigneeId: UUID?
    let assigneeIds: [UUID]? // Multiple assignees (stored as JSON in description metadata)
    let dueDate: Date?
    let createdBy: UUID
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status, priority
        case teamId = "team_id"
        case assigneeId = "assignee_id"
        case assigneeIds = "assignee_ids"
        case dueDate = "due_date"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed property to get all assignee IDs (primary + additional)
    var allAssigneeIds: [UUID] {
        var ids: [UUID] = []
        if let primaryId = assigneeId {
            ids.append(primaryId)
        }
        if let additionalIds = assigneeIds {
            ids.append(contentsOf: additionalIds.filter { $0 != assigneeId })
        }
        return Array(Set(ids)) // Remove duplicates
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && status != .done
    }
    
    var daysUntilDue: Int? {
        guard let dueDate = dueDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day
    }
}
