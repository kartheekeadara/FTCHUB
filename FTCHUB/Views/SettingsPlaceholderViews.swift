//
//  SettingsPlaceholderViews.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//  Placeholder implementations for all settings views
//

import SwiftUI
import UIKit

// MARK: - Team Management
struct TeamSettingsView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    
    @State private var name = ""
    @State private var number = ""
    @State private var school = ""
    @State private var city = ""
    @State private var state = ""
    @State private var localError: String?
    @State private var successMessage: String?
    @State private var isSaving = false
    @State private var showingDeleteConfirmation = false
    @State private var showingLeaveConfirmation = false
    @State private var isDeleting = false
    @State private var isLeaving = false
    
    private var canEdit: Bool {
        guard let user = authService.currentUser else { return false }
        // Coaches can always edit team settings, or users with admin role
        return user.effectiveTeamRole == .coach || user.role.canManageUsers == true
    }
    
    private var team: Team? {
        teamService.currentTeam
    }
    
    private var isValid: Bool {
        !trimmed(name).isEmpty && !trimmed(number).isEmpty
    }
    
    private var hasChanges: Bool {
        guard let team else { return false }
        return trimmed(name) != team.name ||
        trimmed(number) != team.number ||
        trimmed(school) != (team.school ?? "") ||
        trimmed(city) != (team.city ?? "") ||
        trimmed(state) != (team.state ?? "")
    }
    
    var body: some View {
        Group {
            if let team {
                teamSettingsForm(team: team)
            } else {
                ContentUnavailableView {
                    Label(L10n.Settings.teamUnavailableTitle, systemImage: "person.3")
                } description: {
                    Text(L10n.Settings.teamUnavailableMessage)
                }
            }
        }
    }
    
    @ViewBuilder
    private func teamSettingsForm(team: Team) -> some View {
        Form {
            if let message = successMessage {
                Section {
                    SettingsInfoMessage(message: message)
                }
            }
            
            if let error = localError ?? teamService.errorMessage {
                Section {
                    SettingsErrorMessage(message: error)
                }
            }
            
            teamDetailsSection
            
            teamLocationSection
            
            teamMetadataSection(team: team)
            
            // Team Management Links
            Section {
                NavigationLink(destination: TeamMembersView()) {
                    Label("Team Members", systemImage: "person.3.fill")
                }
                
                NavigationLink(destination: TeamRolesView()) {
                    Label("Team Roles", systemImage: "person.badge.key.fill")
                }
            } header: {
                Text("Management")
            }
            
            if !canEdit {
                Section {
                    SettingsInfoMessage(message: L10n.Settings.teamReadOnlyNotice)
                }
            }
            
            // Leave Team Section
            leaveTeamSection
            
            deleteTeamSection
        }
        .disabled(isSaving || isDeleting || isLeaving)
        .navigationTitle(L10n.Settings.teamSettingsTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if canEdit {
                    Button {
                        saveTeam()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(L10n.Settings.teamSaveAction)
                        }
                    }
                    .disabled(isSaving || !isValid || !hasChanges)
                }
            }
        }
        .alert("Leave Team", isPresented: $showingLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                leaveTeam()
            }
        } message: {
            if let user = authService.currentUser, user.effectiveTeamRole == .coach {
                let coachCount = teamService.teamMembers.filter { $0.effectiveTeamRole == .coach }.count
                if coachCount <= 1 {
                    Text("You are the last coach. You cannot leave the team. Please assign another coach first or delete the team.")
                } else {
                    Text("Are you sure you want to leave this team? You will lose access to all team data and will need to be re-invited to rejoin.")
                }
            } else {
                Text("Are you sure you want to leave this team? You will lose access to all team data and will need to be re-invited to rejoin.")
            }
        }
        .alert("Delete Team", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTeam()
            }
        } message: {
            if let team = teamService.currentTeam {
                Text("Are you sure you want to delete \"\(team.name)\"? This will permanently remove all team data, members, events, and associated information. This action cannot be undone.")
            } else {
                Text("Are you sure you want to delete this team? This will permanently remove all team data, members, events, and associated information. This action cannot be undone.")
            }
        }
        .overlay {
            if isSaving || isDeleting || isLeaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .onAppear {
            populateFields()
        }
        .onChange(of: teamService.currentTeam?.id) { oldValue, newValue in
            populateFields()
        }
    }
    
    @ViewBuilder
    private var teamDetailsSection: some View {
        Section {
            TextField(L10n.Settings.teamNameField, text: $name)
                .textInputAutocapitalization(.words)
                .disabled(!canEdit)
            
            TextField(L10n.Settings.teamNumberField, text: $number)
                .keyboardType(.numbersAndPunctuation)
                .disabled(!canEdit)
        } header: {
            Text(L10n.Settings.teamDetailsTitle)
        }
    }
    
    @ViewBuilder
    private var teamLocationSection: some View {
        Section {
            TextField(L10n.Settings.teamSchoolField, text: $school)
                .textInputAutocapitalization(.words)
                .disabled(!canEdit)
            
            TextField(L10n.Settings.teamCityField, text: $city)
                .textInputAutocapitalization(.words)
                .disabled(!canEdit)
            
            TextField(L10n.Settings.teamStateField, text: $state)
                .textInputAutocapitalization(.characters)
                .disabled(!canEdit)
        } header: {
            Text(L10n.Settings.teamLocationTitle)
        }
    }
    
    @ViewBuilder
    private func teamMetadataSection(team: Team) -> some View {
        Section {
            HStack {
                Text(L10n.Settings.teamCreatedLabel)
                Spacer()
                Text(team.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            HStack {
                Text(L10n.Settings.teamUpdatedLabel)
                Spacer()
                Text(team.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        } header: {
            Text(L10n.Settings.teamMetadataTitle)
        }
    }
    
    @ViewBuilder
    private var leaveTeamSection: some View {
        Section {
            Button(role: .destructive) {
                showingLeaveConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Leave Team")
                        .fontWeight(.medium)
                }
            }
            .disabled(isLeaving || isDeleting)
        } header: {
            Text("Team Membership")
                .textCase(.none)
        } footer: {
            if let user = authService.currentUser, user.effectiveTeamRole == .coach {
                let coachCount = teamService.teamMembers.filter { $0.effectiveTeamRole == .coach }.count
                if coachCount <= 1 {
                    Text("You are the last coach. You cannot leave the team. Please assign another coach first or delete the team.")
                } else {
                    Text("Leaving the team will remove your access. You can join another team or create a new one.")
                }
            } else {
                Text("Leaving the team will remove your access. You can join another team or create a new one.")
            }
        }
    }
    
    @ViewBuilder
    private var deleteTeamSection: some View {
        if authService.currentUser?.effectiveTeamRole.canDeleteTeam == true {
            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Team")
                            .fontWeight(.medium)
                    }
                }
                .disabled(isLeaving || isDeleting)
            } header: {
                Text("Danger Zone")
                    .textCase(.none)
            } footer: {
                Text("Deleting a team will remove all team data, members, and associated information. This action cannot be undone.")
            }
        }
    }
    
    private func populateFields() {
        guard let team = teamService.currentTeam else { return }
        name = team.name
        number = team.number
        school = team.school ?? ""
        city = team.city ?? ""
        state = team.state ?? ""
        localError = nil
        successMessage = nil
    }
    
    private func saveTeam() {
        guard canEdit else { return }
        localError = nil
        successMessage = nil
        
        if !isValid {
            localError = L10n.Settings.teamValidationMessage
            return
        }
        
        isSaving = true
        Task {
            do {
                try await teamService.updateTeamDetails(
                    name: name,
                    number: number,
                    school: school,
                    city: city,
                    state: state
                )
                DesignSystem.Haptics.notify(.success)
                isSaving = false
                successMessage = L10n.Settings.teamUpdatedMessage
                populateFields()
            } catch {
                DesignSystem.Haptics.notify(.error)
                localError = error.localizedDescription
                isSaving = false
            }
        }
    }
    
    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func leaveTeam() {
        isLeaving = true
        localError = nil
        
        Task {
            do {
                try await teamService.leaveTeam()
                DesignSystem.Haptics.notify(.success)
                isLeaving = false
                // Navigation will be handled automatically when team is left
            } catch {
                DesignSystem.Haptics.notify(.error)
                localError = error.localizedDescription
                isLeaving = false
            }
        }
    }
    
    private func deleteTeam() {
        guard authService.currentUser?.effectiveTeamRole.canDeleteTeam == true else { return }
        isDeleting = true
        localError = nil
        
        Task {
            do {
                try await teamService.deleteTeam()
                DesignSystem.Haptics.notify(.success)
                isDeleting = false
                // Navigation will be handled automatically when team is deleted
            } catch {
                DesignSystem.Haptics.notify(.error)
                localError = error.localizedDescription
                isDeleting = false
            }
        }
    }
}

struct MemberManagementView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedMember: Profile?
    @State private var memberToRemove: Profile?
    @State private var actionError: String?
    
    private var canManage: Bool {
        authService.currentUser?.effectiveTeamRole.canManageMembers == true
    }
    
    private var members: [Profile] {
        teamService.teamMembers.sorted { lhs, rhs in
            let lhsPriority = memberPriority(lhs)
            let rhsPriority = memberPriority(rhs)
            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }
    
    var body: some View {
        Group {
            if let team = teamService.currentTeam {
                membersList(for: team)
            } else {
                ContentUnavailableView {
                    Label(L10n.Settings.teamUnavailableTitle, systemImage: "person.3")
                } description: {
                    Text(L10n.Settings.teamUnavailableMessage)
                }
            }
        }
    }
    
    @ViewBuilder
    private func membersList(for team: Team) -> some View {
        List {
            if let error = actionError ?? teamService.errorMessage {
                Section {
                    SettingsErrorMessage(message: error)
                }
            }
            
            if canManage {
                inviteSection(for: team)
            }
            
            membersSection()
        }
        .animation(.default, value: members)
        .navigationTitle(L10n.Settings.inviteMembersTitle)
        .sheet(item: $selectedMember) { member in
            MemberDetailSheet(member: member, canManage: canManage)
                .environmentObject(teamService)
                .environmentObject(authService)
        }
        .confirmationDialog(
            L10n.Settings.membersRemoveConfirmTitle,
            isPresented: Binding(get: { memberToRemove != nil }, set: { if !$0 { memberToRemove = nil } })
        ) {
            Button(L10n.Settings.membersRemoveConfirmButton, role: .destructive) {
                if let member = memberToRemove {
                    performRemove(member)
                }
            }
            Button(L10n.General.actionClose, role: .cancel) {
                memberToRemove = nil
            }
        } message: {
            if let member = memberToRemove {
                Text(L10n.Settings.membersRemoveConfirmMessage(member.displayName))
            }
        }
    }
    
    @ViewBuilder
    private func inviteSection(for team: Team) -> some View {
        Section {
            // Invite Code Display
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invite Code")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(team.inviteCode)
                            .font(.title2)
                            .fontWeight(.bold)
                            .fontDesign(.monospaced)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    Spacer()
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Button(action: {
                            #if canImport(UIKit)
                            UIPasteboard.general.string = team.inviteCode
                            DesignSystem.Haptics.notify(.success)
                            #endif
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.title3)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        
                        ShareLink(item: "Join my FTC team! Use invite code: \(team.inviteCode)") {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
                
                Text("Share this code with people who want to join your team. They can use it to request approval.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // Join Requests Link (for coaches)
            if authService.currentUser?.effectiveTeamRole.canApproveRequests == true {
                NavigationLink(destination: TeamJoinRequestsView()
                    .environmentObject(teamService)
                    .environmentObject(authService)) {
                    HStack {
                        Label("Join Requests", systemImage: "person.badge.plus")
                        Spacer()
                        if teamService.joinRequests.count > 0 {
                            Text("\(teamService.joinRequests.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(DesignSystem.Colors.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        } header: {
            Text("Team Invitations")
                .textCase(.none)
        }
    }
    
    @ViewBuilder
    private func membersSection() -> some View {
        Section {
            if members.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text(L10n.Settings.membersEmptyTitle)
                        .font(.headline)
                    Text(L10n.Settings.membersEmptySubtitle)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            } else {
                ForEach(members) { member in
                    TeamMemberRow(member: member, isCurrentUser: member.id == authService.currentUser?.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if canManage {
                                selectedMember = member
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if canManage && member.id != authService.currentUser?.id {
                                Button(role: .destructive) {
                                    memberToRemove = member
                                } label: {
                                    Label(L10n.Settings.membersRemoveAction, systemImage: "trash")
                                }
                            }
                        }
                }
            }
        } header: {
            Text(L10n.Settings.membersAllSectionTitle)
        } footer: {
            Text(L10n.Settings.membersCountFooter(members.count))
        }
    }
    
    private func performRemove(_ member: Profile) {
        actionError = nil
        Task {
            do {
                try await teamService.removeMember(member)
                DesignSystem.Haptics.notify(.success)
                memberToRemove = nil
            } catch {
                DesignSystem.Haptics.notify(.error)
                actionError = error.localizedDescription
            }
        }
    }
    
    private func memberPriority(_ member: Profile) -> Int {
        // Sort by team role first, then by user role
        let teamRolePriority = member.effectiveTeamRole.priority
        let userRolePriority: Int
        switch member.role {
        case .admin: userRolePriority = 0
        case .editor: userRolePriority = 1
        case .readonly: userRolePriority = 2
        }
        return teamRolePriority * 10 + userRolePriority
    }
    
    private func teamRoleColor(_ role: TeamManagementRole) -> Color {
        switch role {
        case .coach: return DesignSystem.Colors.primary
        case .captain: return DesignSystem.Colors.accent
        case .subcaptain: return DesignSystem.Colors.secondary
        case .member: return DesignSystem.Colors.textSecondary
        }
    }
    
    private func inviteMessage(for team: Team) -> String {
        L10n.Settings.membersInviteMessage(team.displayName)
    }
}

private struct TeamMemberRow: View {
    let member: Profile
    let isCurrentUser: Bool
    
    private func teamRoleColor(_ role: TeamManagementRole) -> Color {
        switch role {
        case .coach: return DesignSystem.Colors.primary
        case .captain: return DesignSystem.Colors.accent
        case .subcaptain: return DesignSystem.Colors.secondary
        case .member: return DesignSystem.Colors.textSecondary
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(member.initials.isEmpty ? "?" : member.initials)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(DesignSystem.Colors.primary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(member.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    if isCurrentUser {
                        Text(L10n.Settings.membersYouBadge)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.accent.opacity(0.2))
                            .foregroundColor(DesignSystem.Colors.accent)
                            .clipShape(Capsule())
                    }
                }
                
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    if let teamRole = member.teamRole {
                        HStack(spacing: 4) {
                            Image(systemName: teamRole.icon)
                                .font(.caption2)
                            Text(teamRole.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(teamRoleColor(teamRole))
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(teamRoleColor(teamRole).opacity(0.15))
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                    }
                    
                    if let memberRole = member.memberRole {
                        Text(memberRole.displayName)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            Text(member.role.displayName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, 4)
                .background(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(DesignSystem.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

private struct MemberDetailSheet: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    let member: Profile
    let canManage: Bool
    
    @State private var selectedMemberRole: MemberRole?
    @State private var selectedTeamRole: TeamManagementRole?
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private var isCurrentUser: Bool {
        member.id == authService.currentUser?.id
    }
    
    private var canAssignRoles: Bool {
        authService.currentUser?.effectiveTeamRole.canAssignRoles == true
    }
    
    init(member: Profile, canManage: Bool) {
        self.member = member
        self.canManage = canManage
        _selectedMemberRole = State(initialValue: member.memberRole)
        _selectedTeamRole = State(initialValue: member.teamRole)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text(L10n.Settings.profileFirstName)
                        Spacer()
                        Text(member.firstName ?? L10n.Settings.membersNotProvided)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    HStack {
                        Text(L10n.Settings.profileLastName)
                        Spacer()
                        Text(member.lastName ?? L10n.Settings.membersNotProvided)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    HStack {
                        Text(L10n.Settings.profilePhone)
                        Spacer()
                        Text(member.phone ?? L10n.Settings.membersNotProvided)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                } header: {
                    Text(L10n.Settings.membersMemberInfoTitle)
                }
                
                Section {
                    Picker(L10n.Settings.profileMemberRole, selection: $selectedMemberRole) {
                        Text(L10n.Settings.membersTeamRoleNone).tag(MemberRole?.none)
                        ForEach(MemberRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(Optional(role))
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!canManage)
                } header: {
                    Text("Member Role")
                }
                
                // Team Management Role (Coach, Captain, Subcaptain, Member)
                if canAssignRoles {
                    Section {
                        Picker("Team Role", selection: $selectedTeamRole) {
                            ForEach(TeamManagementRole.allCases, id: \.self) { role in
                                HStack {
                                    Image(systemName: role.icon)
                                    Text(role.displayName)
                                }
                                .tag(Optional(role))
                            }
                        }
                        .pickerStyle(.menu)
                        .disabled(member.effectiveTeamRole == .coach || isCurrentUser) // Can't change coach role or your own role
                        
                        if member.effectiveTeamRole == .coach {
                            Text("The coach role cannot be changed. It is automatically assigned when creating a team.")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        } else if isCurrentUser {
                            Text("You cannot edit your own team role. Only a coach can assign roles.")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    } header: {
                        Text("Team Management Role")
                    } footer: {
                        Text("Team roles determine permissions within the team. Only coaches can assign roles.")
                    }
                }
                
                if let errorMessage {
                    Section {
                        SettingsErrorMessage(message: errorMessage)
                    }
                }
            }
            .disabled(isSaving)
            .navigationTitle(L10n.Settings.membersEditTitle(member.displayName))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.General.actionClose) {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if canManage {
                        Button {
                            saveChanges()
                        } label: {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text(L10n.Settings.membersSaveAction)
                            }
                        }
                        .disabled(isSaving || !hasRoleChanges)
                    }
                }
            }
        }
    }
    
    private var hasRoleChanges: Bool {
        selectedMemberRole != member.memberRole ||
        (canAssignRoles && selectedTeamRole != member.teamRole)
    }
    
    private func saveChanges() {
        guard canManage else {
            dismiss()
            return
        }
        
        isSaving = true
        errorMessage = nil
        Task {
            do {
                // Update member role
                try await teamService.updateMember(member, userRole: member.role, memberRole: selectedMemberRole)
                
                // Update team role if changed and user can assign roles
                if canAssignRoles, let newTeamRole = selectedTeamRole, newTeamRole != member.teamRole {
                    try await teamService.assignTeamRole(to: member, role: newTeamRole)
                }
                
                DesignSystem.Haptics.notify(.success)
                isSaving = false
                dismiss()
            } catch {
                DesignSystem.Haptics.notify(.error)
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}

// MARK: - Scouting & Analytics
struct ScoutingSettingsView: View {
    var body: some View {
        Form {
            Section("Templates") {
                Text("Configure scouting form templates")
                Text("Customize fields and sections")
            }
            Section("Data Collection") {
                Text("Offline sync preferences")
            }
        }
        .navigationTitle("Scouting Settings")
    }
}

struct AllianceSelectionSettingsView: View {
    var body: some View {
        Form {
            Section("Ranking Criteria") {
                Text("Configure team ranking weights")
                Text("Customize scoring priorities")
            }
            Section("Strategy") {
                Text("Set default alliance strategy")
                Text("Configure selection preferences")
            }
        }
        .navigationTitle("Alliance Selection")
    }
}


// MARK: - Inventory & Finance
struct InventorySettingsView: View {
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var notificationService: NotificationService
    @State private var editingCategory: String?
    @State private var editingThreshold: Int = 1
    @State private var showThresholdEditor = false
    @State private var isProcessing = false
    @State private var infoMessage: String?
    
    private var categories: [CategoryStat] {
        var stats: [CategoryStat] = []
        let categoryNames = inventoryService.categories
        for category in categoryNames {
            let items = inventoryService.items(in: category)
            let lowStock = items.filter { $0.isLowStock }.count
            stats.append(
                CategoryStat(
                    name: category,
                    displayName: category,
                    itemCount: items.count,
                    lowStockCount: lowStock,
                    threshold: inventoryService.lowStockThreshold(for: category)
                )
            )
        }
        
        let uncategorizedItems = inventoryService.items(in: nil)
        if !uncategorizedItems.isEmpty {
            let lowStock = uncategorizedItems.filter { $0.isLowStock }.count
            stats.append(
                CategoryStat(
                    name: nil,
                    displayName: L10n.Settings.inventoryCategoryUncategorized,
                    itemCount: uncategorizedItems.count,
                    lowStockCount: lowStock,
                    threshold: inventoryService.lowStockThreshold(for: nil)
                )
            )
        }
        return stats.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
    
    private var overview: InventoryOverview {
        let items = inventoryService.inventoryItems
        let totalItems = items.count
        let totalQuantity = items.reduce(0) { $0 + $1.quantityOnHand }
        let lowStock = items.filter { $0.isLowStock }.count
        let outOfStock = items.filter { $0.quantityOnHand == 0 }.count
        let totalValue = items.reduce(Decimal(0)) { running, item in
            guard let cost = item.unitCost else { return running }
            return running + (cost * Decimal(item.quantityOnHand))
        }
        return InventoryOverview(
            totalItems: totalItems,
            totalQuantity: totalQuantity,
            lowStock: lowStock,
            outOfStock: outOfStock,
            totalValue: totalValue
        )
    }
    
    private var lowStockPreview: [InventoryItem] {
        Array(inventoryService.lowStockItems.prefix(5))
    }
    
    var body: some View {
        List {
            if let message = infoMessage {
                Section {
                    SettingsInfoMessage(message: message)
                }
            }
            
            if let error = inventoryService.errorMessage {
                Section {
                    SettingsErrorMessage(message: error)
                }
            }
            
            overviewSection
            
            if !categories.isEmpty {
                categoriesSection
            }
            
            notificationsSection
            
            if !lowStockPreview.isEmpty {
                lowStockSection
            }
        }
        .overlay {
            if inventoryService.isLoading || isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .navigationTitle(L10n.Settings.inventorySettingsTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await inventoryService.loadInventoryItems()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel(L10n.Settings.inventoryRefresh)
            }
        }
        .task {
            if inventoryService.inventoryItems.isEmpty {
                await inventoryService.loadInventoryItems()
            }
        }
        .sheet(isPresented: $showThresholdEditor) {
            if let category = editingCategory {
                InventoryThresholdEditor(
                    categoryName: category,
                    threshold: $editingThreshold,
                    onSave: { newValue in
                        Task { await saveThreshold(for: category, value: newValue) }
                    },
                    onCancel: { showThresholdEditor = false }
                )
                .environmentObject(inventoryService)
            } else {
                InventoryThresholdEditor(
                    categoryName: L10n.Settings.inventoryCategoryUncategorized,
                    threshold: $editingThreshold,
                    onSave: { newValue in
                        Task { await saveThreshold(for: nil, value: newValue) }
                    },
                    onCancel: { showThresholdEditor = false }
                )
                .environmentObject(inventoryService)
            }
        }
    }
    
    private var overviewSection: some View {
        Section {
            HStack {
                StatisticCard(
                    icon: "cube.box.fill",
                    value: "\(overview.totalItems)",
                    label: L10n.Settings.inventoryStatItems
                )
                StatisticCard(
                    icon: "number",
                    value: "\(overview.totalQuantity)",
                    label: L10n.Settings.inventoryStatQuantity
                )
            }
            HStack {
                StatisticCard(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(overview.lowStock)",
                    label: L10n.Settings.inventoryStatLowStock,
                    color: DesignSystem.Colors.warning
                )
                StatisticCard(
                    icon: "xmark.seal.fill",
                    value: "\(overview.outOfStock)",
                    label: L10n.Settings.inventoryStatOutStock,
                    color: DesignSystem.Colors.error
                )
            }
            if overview.totalValue > 0 {
                StatisticCard(
                    icon: "dollarsign.circle.fill",
                    value: overview.formattedValue,
                    label: L10n.Settings.inventoryStatValue,
                    color: DesignSystem.Colors.accent
                )
            }
        } header: {
            Text(L10n.Settings.inventoryOverviewSection)
        }
    }
    
    private var categoriesSection: some View {
        Section {
            ForEach(categories) { category in
                Button {
                    editingCategory = category.name
                    editingThreshold = category.threshold
                    showThresholdEditor = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text(L10n.Settings.inventoryCategorySummary(category.itemCount, category.lowStockCount))
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                        Label {
                            Text(L10n.Settings.inventoryThresholdValue(category.threshold))
                                .font(.caption.weight(.semibold))
                        } icon: {
                            Image(systemName: "arrow.down.circle")
                        }
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 6)
                        .background(DesignSystem.Colors.cardBackground)
                        .clipShape(Capsule())
                    }
                }
            }
        } header: {
            Text(L10n.Settings.inventoryCategoriesSection)
        } footer: {
            Text(L10n.Settings.inventoryThresholdFooter)
        }
    }
    
    private var notificationsSection: some View {
        Section {
            Toggle(L10n.Settings.inventoryAlertsToggle, isOn: Binding {
                notificationService.enableInventoryAlerts
            } set: { newValue in
                notificationService.enableInventoryAlerts = newValue
                notificationService.savePreferences()
            })
            
            Button {
                notificationService.scheduleLowStockAlertPreview()
                infoMessage = L10n.Settings.inventoryAlertsTestScheduled
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    infoMessage = nil
                }
            } label: {
                Label(L10n.Settings.inventoryAlertsTest, systemImage: "bell.badge")
            }
            .disabled(!notificationService.isAuthorized || !notificationService.enableInventoryAlerts)
        } header: {
            Text(L10n.Settings.inventoryAlertsSection)
        } footer: {
            Text(notificationService.isAuthorized ? L10n.Settings.inventoryAlertsFooter : L10n.Settings.inventoryAlertsDisabledFooter)
        }
    }
    
    private var lowStockSection: some View {
        Section {
            ForEach(lowStockPreview) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.Settings.inventoryLowStockRow(item.quantityOnHand, item.lowStockThreshold))
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            if inventoryService.lowStockItems.count > lowStockPreview.count {
                Text(L10n.Settings.inventoryLowStockMore(inventoryService.lowStockItems.count - lowStockPreview.count))
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        } header: {
            Text(L10n.Settings.inventoryLowStockSection)
        }
    }
    
    private func saveThreshold(for category: String?, value: Int) async {
        isProcessing = true
        do {
            try await inventoryService.updateLowStockThreshold(for: category, to: value)
            showThresholdEditor = false
            infoMessage = L10n.Settings.inventoryThresholdUpdated
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                infoMessage = nil
            }
        } catch {
            infoMessage = nil
        }
        isProcessing = false
    }
    
    private struct CategoryStat: Identifiable {
        let id = UUID()
        let name: String?
        let displayName: String
        let itemCount: Int
        let lowStockCount: Int
        let threshold: Int
    }
    
    private struct InventoryOverview {
        let totalItems: Int
        let totalQuantity: Int
        let lowStock: Int
        let outOfStock: Int
        let totalValue: Decimal
        
        var formattedValue: String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            return formatter.string(from: totalValue as NSDecimalNumber) ?? "$0.00"
        }
    }
    
    private struct StatisticCard: View {
        let icon: String
        let value: String
        let label: String
        var color: Color = DesignSystem.Colors.primary
        
        var body: some View {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Text(label)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                Spacer()
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }
}

private struct InventoryThresholdEditor: View {
    @EnvironmentObject var inventoryService: InventoryService
    let categoryName: String
    @Binding var threshold: Int
    var onSave: (Int) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
        Form {
                Section {
                    Stepper(
                        L10n.Settings.inventoryThresholdValue(threshold),
                        value: $threshold,
                        in: 0...50
                    )
                } header: {
                    Text(L10n.Settings.inventoryThresholdEditorHeader(categoryName))
                } footer: {
                    Text(L10n.Settings.inventoryThresholdEditorFooter)
                }
            }
            .navigationTitle(L10n.Settings.inventoryThresholdEditorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.General.actionClose) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.General.actionSave) {
                        onSave(threshold)
                    }
                }
            }
        }
    }
}

struct FinanceSettingsView: View {
    @EnvironmentObject var financeService: FinanceService
    @Environment(\.dismiss) private var dismiss
    @State private var infoMessage: String?
    
    private var summary: FinancialSummary { financeService.getFinancialSummary() }
    
    private var budgetSummary: BudgetSummary? {
        financeService.budgetSummary
    }
    
    private var topVendors: [VendorStat] {
        Array(financeService.vendorSummaries.prefix(3))
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    var body: some View {
        List {
            if let message = infoMessage {
                Section {
                    SettingsInfoMessage(message: message)
                }
            }
            
            if let error = financeService.errorMessage {
                Section {
                    SettingsErrorMessage(message: error)
                }
            }
            
            overviewSection
            alertsSection
            spendingSection
            vendorsSection
            
            Section {
                NavigationLink(destination: BudgetsListView().environmentObject(financeService)) {
                    Label(L10n.Settings.financeViewBudgets, systemImage: "chart.pie.fill")
                }
                NavigationLink(destination: OrdersListView().environmentObject(financeService)) {
                    Label(L10n.Settings.financeViewOrders, systemImage: "shippingbox.fill")
                }
                NavigationLink(destination: VendorsListView().environmentObject(financeService)) {
                    Label(L10n.Settings.financeViewVendors, systemImage: "building.2.fill")
                }
            } header: {
                Text(L10n.Settings.financeNavigationSection)
            }
        }
        .navigationTitle(L10n.Settings.financeSettingsTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await financeService.loadFinancialData()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel(L10n.Settings.financeRefresh)
            }
        }
        .task {
            await financeService.loadFinancialData()
        }
        .onDisappear {
            financeService.savePreferences()
        }
    }
    
    private var overviewSection: some View {
        Section {
            HStack {
                FinanceStatCard(
                    icon: "dollarsign.circle.fill",
                    value: currencyFormatter.string(from: summary.totalBudget as NSDecimalNumber) ?? "$0",
                    label: L10n.Settings.financeStatBudget
                )
                FinanceStatCard(
                    icon: "arrow.down.circle.fill",
                    value: currencyFormatter.string(from: summary.totalSpent as NSDecimalNumber) ?? "$0",
                    label: L10n.Settings.financeStatSpent,
                    color: DesignSystem.Colors.warning
                )
            }
            HStack {
                FinanceStatCard(
                    icon: "arrowshape.turn.up.left.fill",
                    value: currencyFormatter.string(from: summary.totalRemaining as NSDecimalNumber) ?? "$0",
                    label: L10n.Settings.financeStatRemaining,
                    color: DesignSystem.Colors.accent
                )
                FinanceStatCard(
                    icon: "doc.on.doc.fill",
                    value: "\(summary.orderCount)",
                    label: L10n.Settings.financeStatOrders
                )
            }
            if let budgetSummary {
                Text(L10n.Settings.financeBudgetOverview(budgetSummary.categoryCount, budgetSummary.overBudgetCategories))
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        } header: {
            Text(L10n.Settings.financeOverviewSection)
        }
    }
    
    private var alertsSection: some View {
        Section {
            Toggle(L10n.Settings.financeBudgetAlertsToggle, isOn: Binding {
                financeService.enableBudgetAlerts
            } set: { newValue in
                financeService.enableBudgetAlerts = newValue
                financeService.savePreferences()
            })
            
            if financeService.enableBudgetAlerts {
                Stepper(
                    L10n.Settings.financeBudgetAlertStepper(financeService.budgetAlertThreshold),
                    value: Binding {
                        financeService.budgetAlertThreshold
                    } set: { newValue in
                        financeService.budgetAlertThreshold = newValue
                        financeService.savePreferences()
                    },
                    in: 5...50,
                    step: 5
                )
            }
            
            Toggle(L10n.Settings.financeSpendingAlertsToggle, isOn: Binding {
                financeService.enableSpendingAlerts
            } set: { newValue in
                financeService.enableSpendingAlerts = newValue
                financeService.savePreferences()
            })
            
            if financeService.enableSpendingAlerts {
                Stepper(
                    L10n.Settings.financeSpendingAlertStepper(financeService.spendingAlertLimit),
                    value: Binding {
                        financeService.spendingAlertLimit
                    } set: { newValue in
                        financeService.spendingAlertLimit = newValue
                        financeService.savePreferences()
                    },
                    in: 50...2000,
                    step: 50
                )
            }
            
            Toggle(L10n.Settings.financeAutoCategorizeToggle, isOn: Binding {
                financeService.autoCategorizeOrders
            } set: { newValue in
                financeService.autoCategorizeOrders = newValue
                financeService.savePreferences()
            })
        } header: {
            Text(L10n.Settings.financeAlertsSection)
        } footer: {
            Text(L10n.Settings.financeAlertsFooter)
        }
    }
    
    private var spendingSection: some View {
        Section {
            HStack {
                Text(L10n.Settings.financePendingOrders)
                Spacer()
                Text("\(financeService.pendingOrdersCount)")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            HStack {
                Text(L10n.Settings.financeTotalSpend)
                Spacer()
                Text(currencyFormatter.string(from: financeService.totalSpendThisSeason as NSDecimalNumber) ?? "$0")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            HStack {
                Text(L10n.Settings.financeAverageOrder)
                Spacer()
                Text(currencyFormatter.string(from: financeService.averageOrderValue as NSDecimalNumber) ?? "$0")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        } header: {
            Text(L10n.Settings.financeSpendingSection)
        }
    }
    
    private var vendorsSection: some View {
        Section {
            if topVendors.isEmpty {
                Text(L10n.Settings.financeNoVendors)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.vertical, DesignSystem.Spacing.sm)
            } else {
                ForEach(topVendors) { vendor in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vendor.name)
                                .font(.subheadline.weight(.semibold))
                            Text(L10n.Settings.financeVendorSummary(vendor.orderCount, vendor.formattedAmount))
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        infoMessage = L10n.Settings.financeVendorTapHint(vendor.name)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            infoMessage = nil
                        }
                    }
                }
            }
        } header: {
            Text(L10n.Settings.financeVendorsSection)
        } footer: {
            if topVendors.count >= 3 {
                Text(L10n.Settings.financeViewMoreVendors)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

private struct FinanceStatCard: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = DesignSystem.Colors.primary
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.headline)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(label)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

struct GrantDeadlinesView: View {
    @State private var grants = [
        GrantDeadline(name: "FIRST Grant", deadline: Date().addingTimeInterval(86400 * 30), amount: 5000),
        GrantDeadline(name: "Local Sponsor", deadline: Date().addingTimeInterval(86400 * 15), amount: 2500)
    ]
    
    var body: some View {
        List {
            ForEach(grants) { grant in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(grant.name)
                            .font(.headline)
                        Spacer()
                        Text("$\(grant.amount)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    Text("Due: \(grant.deadline.formatted(date: .long, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if grant.daysRemaining < 7 {
                        Label("\(grant.daysRemaining) days remaining", systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Grant Deadlines")
    }
}

struct GrantDeadline: Identifiable {
    let id = UUID()
    let name: String
    let deadline: Date
    let amount: Int
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }
}

// MARK: - Data & Sync
// OfflineSettingsView removed - offline features are no longer supported

struct PrivacySettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var errorMessage: String?
    @State private var showDeletionAlert = false
    @State private var telemetryEnabled = TelemetryService.shared.isEnabled
    
    var body: some View {
        List {
            if let errorMessage {
                Section {
                    SettingsErrorMessage(message: errorMessage)
                }
            }
            
            telemetrySection
            dataRightsSection
            legalSection
        }
        .navigationTitle(L10n.Settings.privacySettingsTitle)
        .alert(L10n.Settings.privacyDeleteAlertTitle, isPresented: $showDeletionAlert) {
            Button(L10n.Settings.privacyDeleteAlertConfirm, role: .destructive) {
                openDeletionRequest()
            }
            Button(L10n.General.actionClose, role: .cancel) { }
        } message: {
            Text(L10n.Settings.privacyDeleteAlertMessage)
        }
        .onAppear {
            telemetryEnabled = TelemetryService.shared.isEnabled
        }
    }
    
    private var telemetrySection: some View {
        Section {
            NavigationLink(destination: TelemetryPreferencesView(isEnabled: $telemetryEnabled)) {
                SettingsRow(
                    icon: "waveform.path.ecg",
                    title: L10n.Settings.telemetryTitle,
                    subtitle: telemetryEnabled ? L10n.General.statusEnabled : L10n.General.statusDisabled,
                    trailing: AnyView(telemetryStatusBadge)
                )
            }
        } header: {
            Text(L10n.Settings.privacyTelemetrySection)
        } footer: {
            Text(L10n.Settings.privacyTelemetryFooter)
        }
    }
    
    private var dataRightsSection: some View {
        Section {
            Button(role: .destructive) {
                showDeletionAlert = true
            } label: {
                Label(L10n.Settings.privacyDeleteData, systemImage: "trash.fill")
            }
        } header: {
            Text(L10n.Settings.privacyDataSection)
        } footer: {
            Text(L10n.Settings.privacyDataFooter)
        }
    }
    
    private var legalSection: some View {
        Section {
            NavigationLink(destination: LegalDocumentView(title: L10n.Legal.privacyPolicyTitle, resourceName: "PrivacyPolicy")) {
                Label(L10n.Legal.privacyPolicyTitle, systemImage: "shield.lefthalf.filled")
            }
            NavigationLink(destination: LegalDocumentView(title: L10n.Legal.termsTitle, resourceName: "TermsOfService")) {
                Label(L10n.Legal.termsTitle, systemImage: "doc.richtext")
            }
            NavigationLink(destination: LegalDocumentView(title: L10n.Settings.supportFAQ, resourceName: "SupportGuide")) {
                Label(L10n.Settings.supportFAQ, systemImage: "questionmark.circle")
            }
        } header: {
            Text(L10n.Settings.privacyLegalSection)
        }
    }
    
    private func openDeletionRequest() {
        guard let url = URL(string: "mailto:kartheek.eadara@gmail.com?subject=FTC%20HUB%20Data%20Deletion%20Request") else { return }
        UIApplication.shared.open(url)
    }
    
    private var telemetryStatusBadge: some View {
        Text(telemetryEnabled ? L10n.General.statusEnabled : L10n.General.statusDisabled)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs / 2)
            .foregroundColor(telemetryEnabled ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
            .background(
                (telemetryEnabled ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                    .opacity(0.12)
            )
            .clipShape(Capsule())
    }
}

struct DataManagementView: View {
    var body: some View {
        List {
            Text("Data management features are available through account settings.")
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .navigationTitle(L10n.Settings.dataManagementTitle)
    }
}

// MARK: - Support
struct HelpCenterView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink("Quick Start Guide") { Text("Guide content") }
                NavigationLink("Team Setup") { Text("Setup guide") }
                NavigationLink("Scouting Tutorial") { Text("Tutorial") }
            }
            Section(L10n.Settings.supportSectionSupport) {
                Link(L10n.Settings.supportEmail, destination: URL(string: "mailto:kartheek.eadara@gmail.com")!)
                Link(L10n.Settings.supportCommunity, destination: URL(string: "https://discord.gg/ftchub")!)
                NavigationLink(L10n.Settings.supportFAQ) {
                    LegalDocumentView(title: L10n.Settings.supportFAQ, resourceName: "SupportGuide")
                }
            }
            Section("Resources") {
                Link("FIRST Tech Challenge", destination: URL(string: "https://www.firstinspires.org/robotics/ftc")!)
                Link("FTC Resources", destination: URL(string: "https://www.firstinspires.org/resource-library")!)
            }
        }
        .navigationTitle("Help & Support")
    }
}

struct AboutView: View {
    var body: some View {
        Form {
            Section("App Information") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(appBuild)
                        .foregroundColor(.secondary)
                }
            }
            Section("Legal") {
                NavigationLink(L10n.Legal.termsTitle) {
                    LegalDocumentView(title: L10n.Legal.termsTitle, resourceName: "TermsOfService")
                }
                NavigationLink(L10n.Legal.privacyPolicyTitle) {
                    LegalDocumentView(title: L10n.Legal.privacyPolicyTitle, resourceName: "PrivacyPolicy")
                }
                NavigationLink(L10n.Settings.aboutLicenses) {
                    Text("Open source licenses will be displayed here.")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            Section("Credits") {
                Text("Developed for FIRST Tech Challenge teams")
                Text("© 2025 FTC HUB")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("About")
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

// MARK: - Onboarding
struct OnboardingFlowView: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    
    let pages = [
        OnboardingPage(icon: "person.3.fill", title: "Welcome to FTC HUB", description: "Your all-in-one team management solution"),
        OnboardingPage(icon: "chart.bar.fill", title: "Scouting & Analytics", description: "Track performance and make data-driven decisions"),
        OnboardingPage(icon: "cube.box.fill", title: "Inventory Management", description: "Keep track of all your parts and supplies"),
        OnboardingPage(icon: "trophy.fill", title: "Competition Tools", description: "Everything you need on competition day")
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 20) {
                        Image(systemName: page.icon)
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text(page.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(page.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            Button(action: {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else {
                    dismiss()
                }
            }) {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
}

#Preview("Team Settings") {
    NavigationView {
        TeamSettingsView()
    }
}

#Preview("About") {
    NavigationView {
        AboutView()
    }
}

#Preview("Onboarding") {
    OnboardingFlowView()
}


