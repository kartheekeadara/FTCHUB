//
//  Team.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

struct Team: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let number: String
    let school: String?
    let city: String?
    let state: String?
    let country: String
    let coachId: UUID // ID of the coach who created the team
    let inviteCode: String // Unique invite code for joining
    // Phase 2: Public team visibility fields
    let isPublic: Bool? // Whether team profile is publicly visible
    let websiteUrl: String? // Team website URL
    let bio: String? // Team bio/description
    let robotName: String? // Current robot name
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, number, school, city, state, country
        case coachId = "coach_id"
        case inviteCode = "invite_code"
        case isPublic = "is_public"
        case websiteUrl = "website_url"
        case bio
        case robotName = "robot_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties for display
    var displayName: String {
        return "\(name) (#\(number))"
    }
    
    var location: String {
        var locationParts: [String] = []
        if let city = city { locationParts.append(city) }
        if let state = state { locationParts.append(state) }
        if country != "USA" { locationParts.append(country) }
        return locationParts.joined(separator: ", ")
    }
}

// MARK: - Sample Data for Testing
extension Team {
    static let sample = Team(
        id: UUID(),
        name: "Robo Warriors",
        number: "12345",
        school: "Sample High School",
        city: "Sample City",
        state: "CA",
        country: "USA",
        coachId: UUID(),
        inviteCode: "ABC123",
        isPublic: true,
        websiteUrl: nil,
        bio: nil,
        robotName: "RoboBot 3000",
        createdAt: Date(),
        updatedAt: Date()
    )
}
