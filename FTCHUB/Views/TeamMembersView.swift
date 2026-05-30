//
//  TeamMembersView.swift
//  FTCHUB
//
//  Created for Phase 2 Implementation
//

import SwiftUI

struct TeamMembersView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""
    @State private var showingRemoveConfirmation = false
    @State private var memberToRemove: Profile?
    @State private var errorMessage: String?
    
    var currentUser: Profile? {
        authService.currentUser
    }
    
    var canManageMembers: Bool {
        guard let user = currentUser, let team = teamService.currentTeam else { return false }
        
        // Check if user has role permission OR is the team creator
        let hasRolePermission = user.effectiveTeamRole.canManageMembers
        let isTeamCreator = team.coachId == user.id
        
        let canManage = hasRolePermission || isTeamCreator
        
        // Debug logging
        DebugLog.log("�DEBUG TeamMembersView - Current user: \(user.displayName)")
        DebugLog.log("   - teamRole: \(user.teamRole?.rawValue ?? "nil")")
        DebugLog.log("   - effectiveTeamRole: \(user.effectiveTeamRole.rawValue)")
        DebugLog.log("   - hasRolePermission: \(hasRolePermission)")
        DebugLog.log("   - isTeamCreator: \(isTeamCreator)")
        DebugLog.log("   - canManageMembers: \(canManage)")
        
        return canManage
    }
    
    var filteredMembers: [Profile] {
        if searchText.isEmpty {
            return teamService.teamMembers.sorted { member1, member2 in
                // Sort by role priority, then by name
                let role1 = member1.effectiveTeamRole
                let role2 = member2.effectiveTeamRole
                if role1 != role2 {
                    return role1 > role2
                }
                return (member1.displayName) < (member2.displayName)
            }
        } else {
            return teamService.teamMembers.filter { member in
                member.displayName.localizedCaseInsensitiveContains(searchText) ||
                member.email.localizedCaseInsensitiveContains(searchText)
            }.sorted { member1, member2 in
                let role1 = member1.effectiveTeamRole
                let role2 = member2.effectiveTeamRole
                if role1 != role2 {
                    return role1 > role2
                }
                return (member1.displayName) < (member2.displayName)
            }
        }
    }
    
    var body: some View {
        List {
            if filteredMembers.isEmpty {
                ContentUnavailableView(
                    "No Members Found",
                    systemImage: "person.3",
                    description: Text(searchText.isEmpty ? "No team members yet." : "No members match your search.")
                )
            } else {
                ForEach(filteredMembers) { member in
                    TeamMembersListRow(
                        member: member,
                        currentUser: currentUser,
                        canManageMembers: canManageMembers,
                        onRemove: {
                            memberToRemove = member
                            showingRemoveConfirmation = true
                        }
                    )
                }
            }
        }
        .navigationTitle("Team Members")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search members")
        .refreshable {
            await teamService.loadTeamData()
        }
        .alert("Remove Team Member", isPresented: $showingRemoveConfirmation, presenting: memberToRemove) { member in
            Button("Cancel", role: .cancel) {
                memberToRemove = nil
            }
            Button("Remove", role: .destructive) {
                Task {
                    await removeMember(member)
                }
            }
        } message: { member in
            Text("Are you sure you want to remove \(member.displayName) from the team? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
        .task {
            await teamService.loadTeamData()
        }
    }
    
    private func removeMember(_ member: Profile) async {
        DebugLog.log("�DEBUG TeamMembersView.removeMember - Starting removal for: \(member.displayName)")
        
        // Prevent removing yourself
        guard member.id != currentUser?.id else {
            DebugLog.log("�DEBUG TeamMembersView.removeMember - Cannot remove yourself")
            errorMessage = "You cannot remove yourself from the team. Use 'Leave Team' instead."
            return
        }
        
        // Prevent removing the last coach
        if member.effectiveTeamRole == .coach {
            let coachCount = teamService.teamMembers.filter { $0.effectiveTeamRole == .coach }.count
            if coachCount <= 1 {
                DebugLog.log("�DEBUG TeamMembersView.removeMember - Cannot remove last coach")
                errorMessage = "Cannot remove the last coach. Please assign another coach first."
                return
            }
        }
        
        do {
            DebugLog.log("�DEBUG TeamMembersView.removeMember - Calling teamService.removeMember")
            try await teamService.removeMember(member)
            DebugLog.log("�DEBUG TeamMembersView.removeMember - Successfully removed member")
            memberToRemove = nil
            
            // Force refresh of team data
            DebugLog.log("�DEBUG TeamMembersView.removeMember - Refreshing team data")
            await teamService.loadTeamData()
            DebugLog.log("�DEBUG TeamMembersView.removeMember - Team data refreshed")
        } catch {
            DebugLog.log("�DEBUG TeamMembersView.removeMember - Error: \(error)")
            DebugLog.log("   Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}

struct TeamMembersListRow: View {
    let member: Profile
    let currentUser: Profile?
    let canManageMembers: Bool
    let onRemove: () -> Void
    
    var isCurrentUser: Bool {
        member.id == currentUser?.id
    }
    
    var canRemove: Bool {
        guard canManageMembers else {
            DebugLog.log("�DEBUG canRemove - canManageMembers is false")
            return false
        }
        guard !isCurrentUser else {
            DebugLog.log("�DEBUG canRemove - isCurrentUser is true")
            return false
        }
        
        // Coaches can remove anyone except themselves
        if currentUser?.effectiveTeamRole == .coach {
            DebugLog.log("�DEBUG canRemove - User is coach, can remove: true")
            return true
        }
        
        // Captains can remove members and subcaptains, but not coaches
        if currentUser?.effectiveTeamRole == .captain {
            let canRemoveMember = member.effectiveTeamRole != .coach
            DebugLog.log("�DEBUG canRemove - User is captain, member role: \(member.effectiveTeamRole.rawValue), can remove: \(canRemoveMember)")
            return canRemoveMember
        }
        
        DebugLog.log("�DEBUG canRemove - User role doesn't allow removal")
        return false
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Avatar
            Circle()
                .fill(DesignSystem.Gradients.primary)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(member.initials)
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text(member.displayName)
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Text(member.email)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // Role badge
                    Label(member.effectiveTeamRole.displayName, systemImage: member.effectiveTeamRole.icon)
                        .font(.caption)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(roleColor.opacity(0.15))
                        )
                        .foregroundColor(roleColor)
                    
                    // Member role badge (if different from team role)
                    if let memberRole = member.memberRole {
                        Text(memberRole.displayName)
                            .font(.caption2)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(DesignSystem.Colors.secondary.opacity(0.15))
                            )
                            .foregroundColor(DesignSystem.Colors.secondary)
                    }
                }
            }
            
            Spacer()
            
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "person.badge.minus")
                        .foregroundColor(DesignSystem.Colors.error)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    private var roleColor: Color {
        switch member.effectiveTeamRole {
        case .coach:
            return DesignSystem.Colors.primary
        case .captain:
            return DesignSystem.Colors.accent
        case .subcaptain:
            return DesignSystem.Colors.secondary
        case .member:
            return DesignSystem.Colors.textSecondary
        }
    }
}

#Preview {
    NavigationStack {
        TeamMembersView()
            .environmentObject(TeamService())
            .environmentObject(AuthService())
    }
}

