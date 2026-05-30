//
//  Profile.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case editor = "editor"
    case readonly = "readonly"
    
    var displayName: String {
        switch self {
        case .admin: return "Admin"
        case .editor: return "Editor"
        case .readonly: return "Read Only"
        }
    }
    
    var canEdit: Bool {
        return self == .admin || self == .editor
    }
    
    var canManageUsers: Bool {
        return self == .admin
    }
}

enum MemberRole: String, Codable, CaseIterable {
    case driver = "driver"
    case programmer = "programmer"
    case builder = "builder"
    case scout = "scout"
    case coach = "coach"
    case mentor = "mentor"
    
    var displayName: String {
        switch self {
        case .driver: return "Driver"
        case .programmer: return "Programmer"
        case .builder: return "Builder"
        case .scout: return "Scout"
        case .coach: return "Coach"
        case .mentor: return "Mentor"
        }
    }
    
    var icon: String {
        switch self {
        case .driver: return "person.fill"
        case .programmer: return "laptopcomputer"
        case .builder: return "hammer.fill"
        case .scout: return "chart.bar.fill"
        case .coach: return "person.2.fill"
        case .mentor: return "graduationcap.fill"
        }
    }
}

// Team role hierarchy: Coach > Captain > Subcaptain > Member
enum TeamManagementRole: String, Codable, CaseIterable, Comparable {
    case coach = "coach"
    case captain = "captain"
    case subcaptain = "subcaptain"
    case member = "member"
    
    var displayName: String {
        switch self {
        case .coach: return "Coach"
        case .captain: return "Team Captain"
        case .subcaptain: return "Subcaptain"
        case .member: return "Member"
        }
    }
    
    var icon: String {
        switch self {
        case .coach: return "crown.fill"
        case .captain: return "star.fill"
        case .subcaptain: return "star.circle.fill"
        case .member: return "person.fill"
        }
    }
    
    var priority: Int {
        switch self {
        case .coach: return 4
        case .captain: return 3
        case .subcaptain: return 2
        case .member: return 1
        }
    }
    
    static func < (lhs: TeamManagementRole, rhs: TeamManagementRole) -> Bool {
        lhs.priority < rhs.priority
    }
    
    // Permissions
    var canCreateTeam: Bool {
        self == .coach
    }
    
    var canDeleteTeam: Bool {
        self == .coach
    }
    
    var canManageMembers: Bool {
        self == .coach || self == .captain
    }
    
    var canAssignRoles: Bool {
        self == .coach
    }
    
    var canManageSettings: Bool {
        self == .coach || self == .captain
    }
    
    var canApproveRequests: Bool {
        self == .coach
    }
    
    var canRemoveMembers: Bool {
        self == .coach || self == .captain
    }
    
    var canEditTeamDetails: Bool {
        self == .coach || self == .captain
    }
}

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    let teamId: UUID?
    let role: UserRole
    let teamRole: TeamManagementRole? // New: Team role (coach, captain, subcaptain, member)
    let firstName: String?
    let lastName: String?
    let email: String
    let phone: String?
    let grade: Int?
    let memberRole: MemberRole?
    let experienceBadges: [String]?
    let emergencyContactName: String?
    let emergencyContactPhone: String?
    let passwordResetVerified: Bool? // Controls password reset eligibility (admin-controlled)
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, phone, grade
        case teamId = "team_id"
        case role
        case teamRole = "team_role"
        case firstName = "first_name"
        case lastName = "last_name"
        case memberRole = "member_role"
        case experienceBadges = "experience_badges"
        case emergencyContactName = "emergency_contact_name"
        case emergencyContactPhone = "emergency_contact_phone"
        case passwordResetVerified = "password_reset_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties for display
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
    
    var displayName: String {
        return fullName.isEmpty ? email : fullName
    }
    
    var initials: String {
        let firstInitial = firstName?.first?.uppercased() ?? ""
        let lastInitial = lastName?.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    var gradeDisplay: String {
        guard let grade = grade else { return "N/A" }
        return "Grade \(grade)"
    }
    
    // Team role helpers
    var effectiveTeamRole: TeamManagementRole {
        teamRole ?? .member
    }
    
    var isCoach: Bool {
        effectiveTeamRole == .coach
    }
    
    var isCaptain: Bool {
        effectiveTeamRole == .captain
    }
    
    var isSubcaptain: Bool {
        effectiveTeamRole == .subcaptain
    }
}

// MARK: - Sample Data for Testing
extension Profile {
    static let sample = Profile(
        id: UUID(),
        teamId: Team.sample.id,
        role: .admin,
        teamRole: TeamManagementRole.coach,
        firstName: "John",
        lastName: "Doe",
        email: "john.doe@example.com",
        phone: "+1-555-0123",
        grade: 11,
        memberRole: .coach,
        experienceBadges: ["Programming", "Strategy"],
        emergencyContactName: "Jane Doe",
        emergencyContactPhone: "+1-555-0124",
        passwordResetVerified: true,
        createdAt: Date(),
        updatedAt: Date()
    )
}
