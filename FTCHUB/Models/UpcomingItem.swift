//
//  UpcomingItem.swift
//  FTCHUB
//
//  Unified type for displaying tasks and events together
//

import Foundation

enum UpcomingItemType {
    case task
    case event
}

enum UpcomingItem: Identifiable, Hashable {
    case task(TeamTask)
    case event(Event)
    
    var id: UUID {
        switch self {
        case .task(let task):
            return task.id
        case .event(let event):
            return event.id
        }
    }
    
    var date: Date {
        switch self {
        case .task(let task):
            return task.dueDate ?? Date.distantFuture
        case .event(let event):
            return event.startDate
        }
    }
    
    var title: String {
        switch self {
        case .task(let task):
            return task.title
        case .event(let event):
            return event.title
        }
    }
    
    var type: UpcomingItemType {
        switch self {
        case .task:
            return .task
        case .event:
            return .event
        }
    }
    
    // Check if this task is assigned to the given user
    func isAssignedTo(userId: UUID?) -> Bool {
        guard let userId = userId else { return false }
        switch self {
        case .task(let task):
            return task.allAssigneeIds.contains(userId)
        case .event:
            return false // Events don't have assignments
        }
    }
    
    // Extract the underlying task if this is a task
    var asTask: TeamTask? {
        switch self {
        case .task(let task):
            return task
        case .event:
            return nil
        }
    }
    
    // Extract the underlying event if this is an event
    var asEvent: Event? {
        switch self {
        case .task:
            return nil
        case .event(let event):
            return event
        }
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: UpcomingItem, rhs: UpcomingItem) -> Bool {
        lhs.id == rhs.id
    }
}
