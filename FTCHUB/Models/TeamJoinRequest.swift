//
//  TeamJoinRequest.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

enum JoinRequestStatus: String, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
}

struct TeamJoinRequest: Codable, Identifiable {
    let id: UUID
    let teamId: UUID
    let userId: UUID
    let inviteCode: String
    let status: JoinRequestStatus
    let message: String? // Optional message from requester
    let respondedBy: UUID? // Coach who approved/rejected
    let respondedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case userId = "user_id"
        case inviteCode = "invite_code"
        case status
        case message
        case respondedBy = "responded_by"
        case respondedAt = "responded_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

