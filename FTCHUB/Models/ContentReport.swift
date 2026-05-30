//
//  ContentReport.swift
//  FTCHUB
//
//  Created for App Store Compliance - Content Moderation
//

import Foundation

struct ContentReport: Codable, Identifiable {
    let id: UUID
    let reportedBy: UUID // User who reported the content
    let contentType: ContentType
    let contentId: UUID // ID of the reported content (scouting report, etc.)
    let reason: ReportReason
    let description: String? // Optional detailed description
    let status: ReportStatus
    let reviewedBy: UUID? // Team admin who reviewed
    let reviewedAt: Date?
    let actionTaken: String? // What action was taken (removed, edited, etc.)
    let createdAt: Date
    let updatedAt: Date
    
    enum ContentType: String, Codable {
        case scoutingReport = "scouting_report"
        case troubleshootingEntry = "troubleshooting_entry"
        case teamNote = "team_note"
        case comment = "comment"
        case other = "other"
    }
    
    enum ReportReason: String, Codable, CaseIterable {
        case inappropriate = "inappropriate"
        case offensive = "offensive"
        case spam = "spam"
        case harassment = "harassment"
        case falseInformation = "false_information"
        case copyright = "copyright"
        case other = "other"
        
        var displayName: String {
            switch self {
            case .inappropriate: return "Inappropriate Content"
            case .offensive: return "Offensive Language"
            case .spam: return "Spam"
            case .harassment: return "Harassment"
            case .falseInformation: return "False Information"
            case .copyright: return "Copyright Violation"
            case .other: return "Other"
            }
        }
    }
    
    enum ReportStatus: String, Codable {
        case pending = "pending"
        case underReview = "under_review"
        case resolved = "resolved"
        case dismissed = "dismissed"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .underReview: return "Under Review"
            case .resolved: return "Resolved"
            case .dismissed: return "Dismissed"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case reportedBy = "reported_by"
        case contentType = "content_type"
        case contentId = "content_id"
        case reason
        case description
        case status
        case reviewedBy = "reviewed_by"
        case reviewedAt = "reviewed_at"
        case actionTaken = "action_taken"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

