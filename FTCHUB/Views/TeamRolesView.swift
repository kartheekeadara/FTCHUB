//
//  TeamRolesView.swift
//  FTCHUB
//
//  Created for Phase 2 Implementation
//

import SwiftUI

struct TeamRolesView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @State private var showingRoleAssignment = false
    @State private var memberToAssign: Profile?
    @State private var errorMessage: String?
    @State private var memberToRemove: Profile?
    @State private var showingRemoveConfirmation = false
    
    var currentUser: Profile? {
        authService.currentUser
    }
    
    var canAssignRoles: Bool {
        currentUser?.effectiveTeamRole.canAssignRoles ?? false
    }
    
    var canRemoveMembers: Bool {
        currentUser?.effectiveTeamRole.canRemoveMembers ?? false
    }
    
    var membersByRole: [TeamManagementRole: [Profile]] {
        Dictionary(grouping: teamService.teamMembers) { $0.effectiveTeamRole }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Team Roles")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Roles determine what actions team members can perform. Coaches have full control, while members have basic access.")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
            
            ForEach(TeamManagementRole.allCases.reversed(), id: \.self) { role in
                Section {
                    RoleInfoRow(role: role)
                    
                    if let members = membersByRole[role], !members.isEmpty {
                        ForEach(members) { member in
                            MemberRoleRow(
                                member: member,
                                currentUser: currentUser,
                                canAssignRoles: canAssignRoles,
                                canRemoveMembers: canRemoveMembers,
                                onAssignRole: {
                                    if let latestMember = teamService.teamMembers.first(where: { $0.id == member.id }) {
                                        memberToAssign = latestMember
                                    } else {
                                        memberToAssign = member
                                    }
                                    showingRoleAssignment = true
                                },
                                onRemoveMember: {
                                    memberToRemove = member
                                    showingRemoveConfirmation = true
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    } else {
                        Text("No members with this role")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .italic()
                    }
                } header: {
                    HStack {
                        Image(systemName: role.icon)
                        Text(role.displayName)
                    }
                }
            }
        }
        .navigationTitle("Manage Team")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await teamService.loadTeamData()
        }
        .sheet(isPresented: $showingRoleAssignment) {
            Group {
                if let member = memberToAssign {
                    RoleAssignmentView(member: member)
                        .environmentObject(teamService)
                        .environmentObject(authService)
                }
            }
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
    }
    
    private func removeMember(_ member: Profile) async {
        do {
            try await teamService.removeMember(member)
            memberToRemove = nil
            await teamService.loadTeamData()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct RoleInfoRow: View {
    let role: TeamManagementRole
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: role.icon)
                    .foregroundColor(roleColor)
                Text(role.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Text(roleDescription)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            RoleCapabilityGrid(role: role)
                .padding(.top, DesignSystem.Spacing.xs)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .padding(.leading, DesignSystem.Spacing.sm)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(roleColor.opacity(0.55))
                .frame(width: 3)
                .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }
    
    private var roleColor: Color {
        switch role {
        case .coach: return DesignSystem.Colors.primary
        case .captain: return DesignSystem.Colors.accent
        case .subcaptain: return DesignSystem.Colors.secondary
        case .member: return DesignSystem.Colors.textSecondary
        }
    }
    
    private var roleDescription: String {
        switch role {
        case .coach:
            return "Full team management access. Can create teams, manage all members, assign roles, and delete teams."
        case .captain:
            return "Can manage team members, settings, and approve join requests. Cannot assign roles or delete teams."
        case .subcaptain:
            return "Can create tasks and manage team activities. Limited management permissions."
        case .member:
            return "Basic team access. Can view team information and participate in team activities."
        }
    }
}

struct RoleCapabilityGrid: View {
    let role: TeamManagementRole
    
    private var capabilities: [(text: String, icon: String)] {
        var items: [(String, String)] = []
        if role.canManageMembers { items.append(("Manage Members", "person.2")) }
        if role.canAssignRoles { items.append(("Assign Roles", "person.badge.key")) }
        if role.canManageSettings { items.append(("Manage Settings", "gearshape")) }
        if role.canApproveRequests { items.append(("Approve Requests", "checkmark.circle")) }
        if role.canRemoveMembers { items.append(("Remove Members", "person.badge.minus")) }
        if role.canEditTeamDetails { items.append(("Edit Team Details", "pencil")) }
        return items
    }
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(capabilities, id: \.text) { capability in
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.success)
                    Image(systemName: capability.icon)
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text(capability.text)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                )
            }
        }
    }
}

struct MemberRoleRow: View {
    let member: Profile
    let currentUser: Profile?
    let canAssignRoles: Bool
    let canRemoveMembers: Bool
    let onAssignRole: () -> Void
    let onRemoveMember: () -> Void
    
    var isCurrentUser: Bool {
        member.id == currentUser?.id
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(DesignSystem.Gradients.primary)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.initials)
                        .font(.subheadline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.displayName)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Text(member.email)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.md) {
                if canAssignRoles && !isCurrentUser {
                    Button(action: onAssignRole) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .buttonStyle(.plain)
                }
                
                if canRemoveMembers && !isCurrentUser {
                    Button(action: onRemoveMember) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .contentShape(Rectangle())
    }
}

struct RoleAssignmentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    
    let member: Profile
    @State private var selectedRole: TeamManagementRole
    @State private var isAssigning = false
    @State private var errorMessage: String?
    
    init(member: Profile) {
        self.member = member
        let currentRole = member.teamRole ?? .member
        _selectedRole = State(initialValue: currentRole)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Circle()
                            .fill(DesignSystem.Gradients.primary)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(member.initials)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(member.displayName)
                                .font(.headline)
                            Text(member.email)
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                Section {
                    Picker("Team Role", selection: $selectedRole) {
                        ForEach(TeamManagementRole.allCases, id: \.self) { role in
                            HStack {
                                Image(systemName: role.icon)
                                Text(role.displayName)
                            }
                            .tag(role)
                        }
                    }
                } header: {
                    Text("Assign Role")
                } footer: {
                    Text("Changing a member's role updates their permissions immediately.")
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
            .navigationTitle("Assign Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await assignRole() }
                    }
                    .disabled(isAssigning || selectedRole == member.effectiveTeamRole)
                }
            }
        }
    }
    
    private func assignRole() async {
        isAssigning = true
        errorMessage = nil
        do {
            try await teamService.assignTeamRole(to: member, role: selectedRole)
            await teamService.loadTeamData()
            await authService.refreshCurrentProfile()
            DesignSystem.Haptics.notify(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            DesignSystem.Haptics.notify(.error)
        }
        isAssigning = false
    }
}
