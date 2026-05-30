//
//  Availability.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation

struct Availability: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let eventId: UUID
    var status: RSVPStatus
    var response: String?
    var canDrive: Bool
    var seatsAvailable: Int?
    let respondedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case eventId = "event_id"
        case status, response
        case canDrive = "can_drive"
        case seatsAvailable = "seats_available"
        case respondedAt = "responded_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum RSVPStatus: String, Codable {
    case pending = "pending"
    case attending = "attending"
    case declined = "declined"
    case maybe = "maybe"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .attending: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "gray"
        case .attending: return "green"
        case .declined: return "red"
        case .maybe: return "orange"
        }
    }
}

struct ConflictInfo: Identifiable {
    let id = UUID()
    let eventId: UUID
    let conflictingEventId: UUID
    let eventTitle: String
    let conflictingEventTitle: String
    let conflictType: ConflictType
    let severity: ConflictSeverity
}

enum ConflictType {
    case timeOverlap
    case sameDay
    case transportation
    case location
}

enum ConflictSeverity {
    case critical // Complete overlap
    case high      // Partial overlap
    case medium    // Same day
    case low       // Close proximity
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "blue"
        }
    }
}


