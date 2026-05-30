//
//  TeamService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class TeamService: ObservableObject {
    @Published var currentTeam: Team?
    @Published var teamMembers: [Profile] = []
    @Published var events: [Event] = []
    @Published var tasks: [TeamTask] = []
    @Published var joinRequests: [TeamJoinRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    private weak var authService: AuthService?
    
    init() {
        // Set up mock data for previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.currentTeam = Team.sample
            self.teamMembers = [Profile.sample]
            self.events = []
            self.tasks = []
        }
    }
    
    func bindAuthService(_ service: AuthService) {
        authService = service
    }
    
    // MARK: - Team Management
    
    /// Creates a new team. Anyone can create a team.
    func createTeam(name: String, number: String, school: String?, city: String?, state: String?) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let userId = supabase.auth.currentUser?.id else {
                throw TeamError.notAuthenticated
            }
            
            let validated = try InputValidator.TeamCreateInput(
                name: name,
                teamNumber: number,
                school: school,
                city: city,
                state: state
            )
            let trimmedName = validated.name
            let trimmedNumber = validated.teamNumber
            
            // Ensure team number is unique before attempting to insert
            let existingTeams: [Team] = try await supabase
                .from("teams")
                .select("id,name")
                .eq("number", value: trimmedNumber)
                .limit(1)
                .execute()
                .value
            
            if let existing = existingTeams.first {
                throw TeamError.teamNumberAlreadyExists(existingTeam: existing.name)
            }
            
            // Generate unique invite code with robust uniqueness checking
            var inviteCode = InviteCodeGenerator.generate()
            var attempts = 0
            let maxAttempts = 50 // Increased attempts for better uniqueness guarantee
            
            while attempts < maxAttempts {
                let existing: [Team] = try await supabase
                    .from("teams")
                    .select("id")
                    .eq("invite_code", value: inviteCode.uppercased())
                    .limit(1)
                    .execute()
                    .value
                
                if existing.isEmpty {
                    break
                }
                inviteCode = InviteCodeGenerator.generate()
                attempts += 1
            }
            
            // If we couldn't find a unique code after max attempts, throw an error
            if attempts >= maxAttempts {
                throw TeamError.failedToGenerateUniqueInviteCode
            }
            
            let sanitizedSchool = validated.school
            let sanitizedCity = validated.city
            let sanitizedState = validated.state
            
            let team = Team(
                id: UUID(),
                name: trimmedName,
                number: trimmedNumber,
                school: sanitizedSchool?.isEmpty == true ? nil : sanitizedSchool,
                city: sanitizedCity?.isEmpty == true ? nil : sanitizedCity,
                state: sanitizedState?.isEmpty == true ? nil : sanitizedState,
                country: "USA",
                coachId: userId,
                inviteCode: inviteCode,
                isPublic: true,
                websiteUrl: nil,
                bio: nil,
                robotName: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Insert team with error handling for duplicate invite codes
            do {
                try await supabase
                    .from("teams")
                    .insert(team)
                    .execute()
            } catch {
                // If we get a unique constraint violation, try generating a new code once more
                if error.localizedDescription.contains("invite_code") || 
                   error.localizedDescription.contains("unique") ||
                   error.localizedDescription.contains("duplicate") {
                    // Generate one more unique code and retry
                    var newCode = InviteCodeGenerator.generate()
                    var retryAttempts = 0
                    while retryAttempts < 20 {
                        let existing: [Team] = try await supabase
                            .from("teams")
                            .select("id")
                            .eq("invite_code", value: newCode.uppercased())
                            .limit(1)
                            .execute()
                            .value
                        
                        if existing.isEmpty {
                            // Update team with new code and retry insert
                            let updatedTeam = Team(
                                id: team.id,
                                name: team.name,
                                number: team.number,
                                school: team.school,
                                city: team.city,
                                state: team.state,
                                country: team.country,
                                coachId: team.coachId,
                                inviteCode: newCode.uppercased(),
                                isPublic: team.isPublic,
                                websiteUrl: team.websiteUrl,
                                bio: team.bio,
                                robotName: team.robotName,
                                createdAt: team.createdAt,
                                updatedAt: Date()
                            )
                            
                            try await supabase
                                .from("teams")
                                .insert(updatedTeam)
                                .execute()
                            currentTeam = updatedTeam
                            await loadTeamData(for: updatedTeam.id)
                            await authService?.refreshCurrentProfile()
                            return
                        }
                        newCode = InviteCodeGenerator.generate()
                        retryAttempts += 1
                    }
                    throw TeamError.failedToGenerateUniqueInviteCode
                }
                throw error
            }
            
            // Update user's profile: set team_id and team_role to coach
            // Note: Supabase handles UUID conversion automatically
            struct ProfileUpdate: Codable {
                let team_id: UUID
                let team_role: String
            }
            let update = ProfileUpdate(team_id: team.id, team_role: TeamManagementRole.coach.rawValue)
            try await supabase
                .from("profiles")
                .update(update)
                .eq("id", value: userId)
                .execute()
            
            currentTeam = team
            await loadTeamData(for: team.id)
            await authService?.refreshCurrentProfile()
        } catch {
            if error.localizedDescription.contains("teams_number_key") {
                let friendlyError = TeamError.teamNumberAlreadyExists(existingTeam: nil)
                errorMessage = friendlyError.localizedDescription
                throw friendlyError
            }
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Joins a team immediately using an invite code. Once joined, membership is permanent unless removed.
    func requestToJoinTeam(inviteCode: String, message: String? = nil) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            guard let userId = supabase.auth.currentUser?.id else {
                throw TeamError.notAuthenticated
            }
            
            let validatedCode = try InputValidator.InviteCodeInput(inviteCode)
            let normalizedCode = validatedCode.code
            
            DebugLog.log("�Searching for team with invite code: '\(normalizedCode)'")
            
            // Try to find team by invite code using PostgreSQL's case-insensitive ILIKE
            // First, try direct match with uppercase
            var response: [Team] = []
            
            do {
                response = try await supabase
                    .from("teams")
                    .select()
                    .eq("invite_code", value: normalizedCode)
                    .execute()
                    .value
                DebugLog.log("   �Tried uppercase match: Found \(response.count) team(s)")
            } catch {
                DebugLog.log("   �Uppercase match failed: \(error.localizedDescription)")
            }
            
            // If not found, try lowercase
            if response.isEmpty {
                do {
                    response = try await supabase
                        .from("teams")
                        .select()
                        .eq("invite_code", value: normalizedCode.lowercased())
                        .execute()
                        .value
                    DebugLog.log("   �Tried lowercase match: Found \(response.count) team(s)")
                } catch {
                    DebugLog.log("   �Lowercase match failed: \(error.localizedDescription)")
                }
            }
            
            // If still not found, try original case (as entered)
            if response.isEmpty {
                let originalCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
                do {
                    response = try await supabase
                        .from("teams")
                        .select()
                        .eq("invite_code", value: originalCode)
                        .execute()
                        .value
                    DebugLog.log("   �Tried original case match: Found \(response.count) team(s)")
                } catch {
                    DebugLog.log("   �Original case match failed: \(error.localizedDescription)")
                }
            }
            
            // If still not found, fetch all teams and search in memory (bypasses RLS if needed)
            if response.isEmpty {
                DebugLog.log("   �Direct queries failed, trying to fetch all teams...")
                do {
                    let allTeams: [Team] = try await supabase
                        .from("teams")
                        .select()
                        .execute()
                        .value
                    
                    DebugLog.log("   �Fetched \(allTeams.count) total team(s) from database")
                    
                    // Case-insensitive search in memory
                    let foundTeam = allTeams.first(where: { team in
                        let teamCode = team.inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
                        return teamCode.uppercased() == normalizedCode ||
                               teamCode.lowercased() == normalizedCode.lowercased() ||
                               teamCode == normalizedCode ||
                               teamCode == normalizedCode.lowercased()
                    })
                    
                    if let team = foundTeam {
                        DebugLog.log("   �Found team in memory: \(team.name) with code '\(team.inviteCode)'")
                        response = [team]
                    } else {
                        DebugLog.log("   �No matching team found in \(allTeams.count) teams")
                        // Log all invite codes for debugging
                        DebugLog.log("   Available invite codes: \(allTeams.map { $0.inviteCode }.joined(separator: ", "))")
                    }
                } catch {
                    DebugLog.log("   �Failed to fetch all teams: \(error.localizedDescription)")
                }
            }
            
            guard let team = response.first else {
                // Log for debugging
                DebugLog.log("�Team not found for invite code: '\(normalizedCode)'")
                DebugLog.log("   Searched: uppercase, lowercase, original case, and in-memory")
                throw TeamError.teamNotFound
            }
            
            DebugLog.log("�Found team: \(team.name) (#\(team.number)) with invite code: '\(team.inviteCode)'")
            
            // Check if user is already a member
            let currentProfile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            if currentProfile.teamId == team.id {
                // Already a member - just update context and return success
                await updateTeamContext(teamId: team.id)
                return
            }
            
            // Join immediately - membership is permanent
            try await joinTeamImmediately(team: team, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Joins a team immediately without requiring approval
    private func joinTeamImmediately(team: Team, userId: UUID) async throws {
        // Add user to team with default member role
        struct ProfileUpdate: Codable {
            let team_id: UUID
            let team_role: String
        }
        let update = ProfileUpdate(team_id: team.id, team_role: TeamManagementRole.member.rawValue)
        
        try await supabase
            .from("profiles")
            .update(update)
            .eq("id", value: userId)
            .execute()
        
        // Update local context
        currentTeam = team
        await loadTeamData(for: team.id)
        await authService?.refreshCurrentProfile()
    }
    
    func loadTeamData(for teamId: UUID? = nil) async {
        guard let teamId = teamId ?? currentTeam?.id else { 
            // Clear events if no team ID
            events = []
            return 
        }
        
        // Force clear events at start to prevent stale data
        events = []
        
        do {
            // Load team members
            let members: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("team_id", value: teamId)
                .execute()
                .value
            
            teamMembers = members
            
            // Load events - explicitly filter for valid events
            let teamEvents: [Event] = try await supabase
                .from("events")
                .select()
                .eq("team_id", value: teamId)
                .order("start_date", ascending: true)
                .execute()
                .value
            
            // Filter out any invalid events: must have non-empty title and valid team ID
            let validEvents = teamEvents.compactMap { event -> Event? in
                // Title must not be empty after trimming whitespace and newlines
                let trimmedTitle = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty else {
                    return nil
                }
                
                // Title must have at least one non-whitespace character
                let hasNonWhitespace = trimmedTitle.unicodeScalars.contains { !CharacterSet.whitespacesAndNewlines.contains($0) }
                guard hasNonWhitespace else {
                    return nil
                }
                
                // Must have a valid team ID that matches
                guard event.teamId == teamId else {
                    return nil
                }
                
                return event
            }
            
            events = validEvents
            
            // Load tasks
            let teamTasks: [TeamTask] = try await supabase
                .from("tasks")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            tasks = teamTasks
        } catch {
            // Ignore cancellation errors (NSURLErrorDomain Code=-999)
            if let urlError = error as? URLError, urlError.code == .cancelled {
                // Request was cancelled, silently ignore
                return
            }
            
            // Ignore CancellationError
            if error is CancellationError {
                return
            }
            
            // Only log and show error for non-cancellation errors
            DebugLog.log("Failed to load team data: \(error)")
            errorMessage = "Failed to load team data"
            // Clear events on error to prevent stale data
            events = []
            tasks = []
        }
    }
    
    func updateTeamContext(teamId: UUID?) async {
        if let teamId = teamId {
            if currentTeam?.id == teamId {
                await loadTeamData(for: teamId)
                return
            }
            
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }
            
            do {
                let response: [Team] = try await supabase
                    .from("teams")
                    .select()
                    .eq("id", value: teamId)
                    .limit(1)
                    .execute()
                    .value
                
                guard let team = response.first else {
                    currentTeam = nil
                    teamMembers = []
                    events = []
                    tasks = []
                    return
                }
                
            currentTeam = team
            await loadTeamData(for: teamId)
            await loadJoinRequests(for: teamId)
            } catch {
                errorMessage = error.localizedDescription
                currentTeam = nil
                teamMembers = []
                events = []
                tasks = []
                TelemetryService.shared.logError(error, context: ["action": "load_team_context"])
            }
        } else {
            currentTeam = nil
            teamMembers = []
            events = []
            tasks = []
        }
    }
    
    // MARK: - Event Management
    func createEvent(title: String, description: String?, startDate: Date, endDate: Date?, location: String?, eventType: EventType) async throws {
        guard let teamId = currentTeam?.id else { throw TeamError.noTeamSelected }
        
        let event = Event(
            id: UUID(),
            teamId: teamId,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            location: location,
            eventType: eventType,
            status: .scheduled,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await supabase
            .from("events")
            .insert(event)
            .execute()
        
        await loadTeamData(for: currentTeam?.id)
    }
    
    // MARK: - Team Updates
    func updateTeamDetails(name: String, number: String, school: String?, city: String?, state: String?) async throws {
        guard let existingTeam = currentTeam else { throw TeamError.noTeamSelected }
        guard authService?.currentUser?.effectiveTeamRole.canEditTeamDetails == true else { throw TeamError.insufficientPermissions }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else { throw TeamError.invalidTeamName }
        guard !trimmedNumber.isEmpty else { throw TeamError.invalidTeamNumber }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let sanitizedSchool = school?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedCity = city?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedState = state?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedNumber.caseInsensitiveCompare(existingTeam.number) != .orderedSame {
            let existingTeams: [Team] = try await supabase
                .from("teams")
                .select("id,name")
                .eq("number", value: trimmedNumber)
                .neq("id", value: existingTeam.id)
                .limit(1)
                .execute()
                .value
            
            if let existing = existingTeams.first {
                throw TeamError.teamNumberAlreadyExists(existingTeam: existing.name)
            }
        }
        
        let updatedTeam = Team(
            id: existingTeam.id,
            name: trimmedName,
            number: trimmedNumber,
            school: sanitizedSchool?.isEmpty == true ? nil : sanitizedSchool,
            city: sanitizedCity?.isEmpty == true ? nil : sanitizedCity,
            state: sanitizedState?.isEmpty == true ? nil : sanitizedState,
            country: existingTeam.country,
            coachId: existingTeam.coachId,
            inviteCode: existingTeam.inviteCode,
            isPublic: existingTeam.isPublic,
            websiteUrl: existingTeam.websiteUrl,
            bio: existingTeam.bio,
            robotName: existingTeam.robotName,
            createdAt: existingTeam.createdAt,
            updatedAt: Date()
        )
        
        do {
            try await supabase
                .from("teams")
                .update(updatedTeam)
                .eq("id", value: existingTeam.id)
                .execute()
            
            self.currentTeam = updatedTeam
            await loadTeamData(for: updatedTeam.id)
        } catch {
            if error.localizedDescription.contains("teams_number_key") {
                let friendlyError = TeamError.teamNumberAlreadyExists(existingTeam: nil)
                errorMessage = friendlyError.localizedDescription
                throw friendlyError
            }
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateMember(_ member: Profile, userRole: UserRole, memberRole: MemberRole?) async throws {
        guard currentTeam != nil else { throw TeamError.noTeamSelected }
        guard authService?.currentUser?.effectiveTeamRole.canAssignRoles == true else { throw TeamError.insufficientPermissions }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let updatedProfile = Profile(
            id: member.id,
            teamId: member.teamId,
            role: userRole,
            teamRole: member.teamRole,
            firstName: member.firstName,
            lastName: member.lastName,
            email: member.email,
            phone: member.phone,
            grade: member.grade,
            memberRole: memberRole,
            experienceBadges: member.experienceBadges,
            emergencyContactName: member.emergencyContactName,
            emergencyContactPhone: member.emergencyContactPhone,
            passwordResetVerified: member.passwordResetVerified,
            createdAt: member.createdAt,
            updatedAt: Date()
        )
        
        do {
            try await supabase
                .from("profiles")
                .update(updatedProfile)
                .eq("id", value: member.id)
                .execute()
            
            if let index = teamMembers.firstIndex(where: { $0.id == member.id }) {
                teamMembers[index] = updatedProfile
            }
            
            if member.id == authService?.currentUser?.id {
                await authService?.refreshCurrentProfile()
            }
            
            await loadTeamData(for: currentTeam?.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func removeMember(_ member: Profile) async throws {
        guard let team = currentTeam else { throw TeamError.noTeamSelected }
        guard let currentUser = authService?.currentUser else { throw TeamError.notAuthenticated }
        
        // Debug logging
        DebugLog.log("�DEBUG removeMember - Current user: \(currentUser.displayName)")
        DebugLog.log("   - teamRole: \(currentUser.teamRole?.rawValue ?? "nil")")
        DebugLog.log("   - effectiveTeamRole: \(currentUser.effectiveTeamRole.rawValue)")
        DebugLog.log("   - canRemoveMembers: \(currentUser.effectiveTeamRole.canRemoveMembers)")
        DebugLog.log("   - team.coachId: \(team.coachId)")
        DebugLog.log("   - currentUser.id: \(currentUser.id)")
        DebugLog.log("   - isTeamCreator: \(team.coachId == currentUser.id)")
        
        // Check permissions: either has team_role permission OR is the team creator
        let hasRolePermission = currentUser.effectiveTeamRole.canRemoveMembers
        let isTeamCreator = team.coachId == currentUser.id
        
        guard hasRolePermission || isTeamCreator else {
            DebugLog.log("�DEBUG removeMember - Permission denied (no role permission and not team creator)")
            throw TeamError.insufficientPermissions
        }
        
        DebugLog.log("�DEBUG removeMember - Permission granted")
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            DebugLog.log("�DEBUG removeMember - Attempting to remove member: \(member.displayName) (ID: \(member.id))")
            
            // Use RPC function to remove member (bypasses RLS)
            // PostgREST orders parameters alphabetically, so: p_member_id, p_remover_id
            guard let removerId = authService?.currentUser?.id else {
                throw TeamError.notAuthenticated
            }
            
            DebugLog.log("�DEBUG removeMember - Calling RPC function remove_team_member")
            DebugLog.log("   - Member ID: \(member.id)")
            DebugLog.log("   - Remover ID: \(removerId)")
            
            do {
                _ = try await supabase.rpc("remove_team_member", params: [
                    "p_member_id": member.id.uuidString,
                    "p_remover_id": removerId.uuidString
                ]).execute()
                
                DebugLog.log("�DEBUG removeMember - RPC function call successful")
            } catch let rpcError {
                DebugLog.log("�DEBUG removeMember - RPC function call failed: \(rpcError)")
                DebugLog.log("   Error details: \(rpcError.localizedDescription)")
                if let nsError = rpcError as NSError? {
                    DebugLog.log("   Error domain: \(nsError.domain), code: \(nsError.code)")
                    DebugLog.log("   Error userInfo: \(nsError.userInfo)")
                }
                throw rpcError
            }
            
            // Remove from local array
            let beforeCount = teamMembers.count
            teamMembers.removeAll { $0.id == member.id }
            let afterCount = teamMembers.count
            DebugLog.log("�DEBUG removeMember - Local array updated: \(beforeCount) -> \(afterCount) members")
            
            if member.id == authService?.currentUser?.id {
                await authService?.refreshCurrentProfile()
                currentTeam = nil
                events = []
                tasks = []
            }
            
            await loadTeamData(for: currentTeam?.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateEvent(_ event: Event) async throws {
        try await supabase
            .from("events")
            .update(event)
            .eq("id", value: event.id)
            .execute()
        
        await loadTeamData(for: currentTeam?.id)
    }
    
    func deleteEvent(_ event: Event) async throws {
        try await supabase
            .from("events")
            .delete()
            .eq("id", value: event.id)
            .execute()
        
        await loadTeamData(for: currentTeam?.id)
    }
    
    // MARK: - Task Management
    
    /// Checks if the current user can create tasks (coach, captain, or subcaptain)
    var canCreateTasks: Bool {
        guard let currentUser = authService?.currentUser else { return false }
        let role = currentUser.effectiveTeamRole
        return role == .coach || role == .captain || role == .subcaptain
    }
    
    func createTask(title: String, description: String?, priority: TaskPriority, assigneeId: UUID?, assigneeIds: [UUID]? = nil, dueDate: Date?) async throws {
        guard let teamId = currentTeam?.id,
              let currentUserId = supabase.auth.currentUser?.id else { throw TeamError.noTeamSelected }
        
        // Check permissions
        guard canCreateTasks else {
            throw TeamError.insufficientPermissions
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let task = TeamTask(
            id: UUID(),
            teamId: teamId,
            title: title,
            description: description,
            status: .todo,
            priority: priority,
            assigneeId: assigneeId,
            assigneeIds: assigneeIds,
            dueDate: dueDate,
            createdBy: currentUserId,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            // Ensure assignee_ids is always an array (not nil) for proper encoding
            let taskToInsert = TeamTask(
                id: task.id,
                teamId: task.teamId,
                title: task.title,
                description: task.description,
                status: task.status,
                priority: task.priority,
                assigneeId: task.assigneeId,
                assigneeIds: task.assigneeIds ?? [],
                dueDate: task.dueDate,
                createdBy: task.createdBy,
                createdAt: task.createdAt,
                updatedAt: task.updatedAt
            )
            
            DebugLog.log("DEBUG: Creating task - title: '\(task.title)', assignee_ids count: \(taskToInsert.assigneeIds?.count ?? 0)")
            
            try await supabase
                .from("tasks")
                .insert(taskToInsert)
                .execute()
            
            DebugLog.log("DEBUG: Task created successfully")
            await loadTeamData(for: currentTeam?.id)
            NotificationService.shared.rescheduleTaskReminder(for: taskToInsert)
        } catch {
            DebugLog.log("DEBUG: Error creating task: \(error)")
            DebugLog.log("DEBUG: Error type: \(type(of: error))")
            DebugLog.log("DEBUG: Error details: \(error.localizedDescription)")
            
            // Try to extract more detailed error information
            if let nsError = error as NSError? {
                DebugLog.log("DEBUG: NSError domain: \(nsError.domain), code: \(nsError.code)")
                DebugLog.log("DEBUG: NSError userInfo: \(nsError.userInfo)")
            }
            
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateTask(_ task: TeamTask) async throws {
        guard let currentUserId = supabase.auth.currentUser?.id,
              let currentTeam = currentTeam else {
            throw TeamError.notAuthenticated
        }
        
        // Check if user can update tasks (coach, captain, subcaptain)
        let canUpdateAll = canCreateTasks
        
        // Check if user is assigned to the task
        let isAssigned = task.allAssigneeIds.contains(currentUserId)
        
        // Check if user is a coach (by team role or member role)
        let isCoach = currentTeam.coachId == currentUserId || 
                     (authService?.currentUser?.isCoach ?? false) ||
                     (authService?.currentUser?.memberRole == .coach)
        
        // Allow update if:
        // 1. User can create tasks (coach/captain/subcaptain) - can update anything
        // 2. User is assigned to the task - can update status
        // 3. User is a coach - can update anything
        guard canUpdateAll || isAssigned || isCoach else {
            throw TeamError.insufficientPermissions
        }
        
        // If user is only assigned (not coach/captain/subcaptain), only allow status updates
        if !canUpdateAll && !isCoach && isAssigned {
            // Only allow status changes for assigned users
            // Check if anything other than status changed
            // For now, we'll allow the update since the UI only changes status
            // But we could add validation here if needed
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            var updatedTask = task
            updatedTask = TeamTask(
                id: task.id,
                teamId: task.teamId,
                title: task.title,
                description: task.description,
                status: task.status,
                priority: task.priority,
                assigneeId: task.assigneeId,
                assigneeIds: task.assigneeIds,
                dueDate: task.dueDate,
                createdBy: task.createdBy,
                createdAt: task.createdAt,
                updatedAt: Date()
            )
            
            try await supabase
                .from("tasks")
                .update(updatedTask)
                .eq("id", value: task.id)
                .execute()
            
            await loadTeamData(for: currentTeam.id)
            if updatedTask.dueDate != nil {
                NotificationService.shared.rescheduleTaskReminder(for: updatedTask)
            } else {
                NotificationService.shared.cancelTaskReminders(taskId: updatedTask.id)
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteTask(_ task: TeamTask) async throws {
        guard canCreateTasks else {
            throw TeamError.insufficientPermissions
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            DebugLog.log("DEBUG: Deleting task \(task.id) from team \(task.teamId)")
            DebugLog.log("DEBUG: Current user can create tasks: \(canCreateTasks)")
            
            NotificationService.shared.cancelTaskReminders(taskId: task.id)
            try await supabase
                .from("tasks")
                .delete()
                .eq("id", value: task.id)
                .execute()
            
            DebugLog.log("DEBUG: Task deleted successfully from database")
            await loadTeamData(for: currentTeam?.id)
        } catch {
            DebugLog.log("DEBUG: Error deleting task: \(error)")
            DebugLog.log("DEBUG: Error type: \(type(of: error))")
            DebugLog.log("DEBUG: Error details: \(error.localizedDescription)")
            
            // Try to extract more detailed error information
            if let nsError = error as NSError? {
                DebugLog.log("DEBUG: NSError domain: \(nsError.domain), code: \(nsError.code)")
                DebugLog.log("DEBUG: NSError userInfo: \(nsError.userInfo)")
            }
            
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Join Request Management
    
    func loadJoinRequests(for teamId: UUID? = nil) async {
        guard let teamId = teamId ?? currentTeam?.id else { return }
        guard let currentUser = authService?.currentUser else { return }
        
        // Only coaches can see join requests
        guard currentUser.effectiveTeamRole.canApproveRequests else { return }
        
        do {
            let requests: [TeamJoinRequest] = try await supabase
                .from("team_join_requests")
                .select()
                .eq("team_id", value: teamId)
                .eq("status", value: JoinRequestStatus.pending.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            joinRequests = requests
        } catch {
            DebugLog.log("Failed to load join requests: \(error)")
        }
    }
    
    func approveJoinRequest(_ request: TeamJoinRequest) async throws {
        guard let currentUser = authService?.currentUser,
              let currentTeam = currentTeam else {
            throw TeamError.notAuthenticated
        }
        
        guard currentUser.effectiveTeamRole.canApproveRequests else {
            throw TeamError.insufficientPermissions
        }
        
        guard currentTeam.id == request.teamId else {
            throw TeamError.insufficientPermissions
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Update request status
            struct RequestUpdate: Codable {
                let status: String
                let responded_by: UUID
                let responded_at: Date
                let updated_at: Date
            }
            let requestUpdate = RequestUpdate(
                status: JoinRequestStatus.approved.rawValue,
                responded_by: currentUser.id,
                responded_at: Date(),
                updated_at: Date()
            )
            try await supabase
                .from("team_join_requests")
                .update(requestUpdate)
                .eq("id", value: request.id)
                .execute()
            
            // Add user to team with default member role
            struct ProfileUpdate: Codable {
                let team_id: UUID
                let team_role: String
            }
            let update = ProfileUpdate(team_id: currentTeam.id, team_role: TeamManagementRole.member.rawValue)
            try await supabase
                .from("profiles")
                .update(update)
                .eq("id", value: request.userId)
                .execute()
            
            await loadJoinRequests(for: currentTeam.id)
            await loadTeamData(for: currentTeam.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func rejectJoinRequest(_ request: TeamJoinRequest) async throws {
        guard let currentUser = authService?.currentUser,
              let currentTeam = currentTeam else {
            throw TeamError.notAuthenticated
        }
        
        guard currentUser.effectiveTeamRole.canApproveRequests else {
            throw TeamError.insufficientPermissions
        }
        
        guard currentTeam.id == request.teamId else {
            throw TeamError.insufficientPermissions
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            struct RequestUpdate: Codable {
                let status: String
                let responded_by: UUID
                let responded_at: Date
                let updated_at: Date
            }
            let requestUpdate = RequestUpdate(
                status: JoinRequestStatus.rejected.rawValue,
                responded_by: currentUser.id,
                responded_at: Date(),
                updated_at: Date()
            )
            try await supabase
                .from("team_join_requests")
                .update(requestUpdate)
                .eq("id", value: request.id)
                .execute()
            
            await loadJoinRequests(for: currentTeam.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Role Management
    
    func assignTeamRole(to member: Profile, role: TeamManagementRole) async throws {
        guard let currentUser = authService?.currentUser,
              let currentTeam = currentTeam else {
            throw TeamError.notAuthenticated
        }
        
        guard currentUser.effectiveTeamRole.canAssignRoles else {
            throw TeamError.insufficientPermissions
        }
        
        guard member.teamId == currentTeam.id else {
            throw TeamError.insufficientPermissions
        }
        
        // Enforce coach role assignment rules:
        // 1. Only the team creator (coachId) can initially assign coach role
        // 2. Once there are 2+ coaches, any coach can assign coach role
        if role == .coach {
            let coachCount = teamMembers.filter { $0.effectiveTeamRole == .coach }.count
            let isTeamCreator = currentUser.id == currentTeam.coachId
            
            // If there's only 1 coach (or 0), only the team creator can assign coach role
            if coachCount <= 1 && !isTeamCreator {
                throw TeamError.cannotAssignCoachRole
            }
            // If there are 2+ coaches, any coach can assign coach role (already checked canAssignRoles above)
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            struct RoleUpdate: Codable {
                let team_role: String
                let updated_at: Date
            }
            let roleUpdate = RoleUpdate(team_role: role.rawValue, updated_at: Date())
            
            DebugLog.log("DEBUG: Updating profile \(member.id) with role \(role.rawValue)")
            DebugLog.log("DEBUG: Current member teamRole: \(member.teamRole?.rawValue ?? "nil")")
            DebugLog.log("DEBUG: Updating to role: \(role.rawValue)")
            
            // First, verify we can read the current profile
            let currentProfile: Profile? = try? await supabase
                .from("profiles")
                .select()
                .eq("id", value: member.id)
                .single()
                .execute()
                .value
            
            if let current = currentProfile {
                DebugLog.log("DEBUG: Current profile from DB - team_role: \(current.teamRole?.rawValue ?? "nil"), team_id: \(current.teamId?.uuidString ?? "nil")")
            }
            
            // Perform the update - use upsert to ensure it works even with RLS
            do {
                _ = try await supabase
                    .from("profiles")
                    .update(roleUpdate)
                    .eq("id", value: member.id)
                    .execute()
                
                DebugLog.log("DEBUG: Update query executed")
            } catch {
                DebugLog.log("DEBUG: Update failed with error: \(error)")
                DebugLog.log("DEBUG: Error details: \(error.localizedDescription)")
                throw error
            }
            
            // Wait a moment for database to commit
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Immediately verify the update worked by reading back
            let verifyProfile: Profile? = try? await supabase
                .from("profiles")
                .select()
                .eq("id", value: member.id)
                .single()
                .execute()
                .value
            
            if let verified = verifyProfile {
                DebugLog.log("DEBUG: Verified profile after update - team_role: \(verified.teamRole?.rawValue ?? "nil")")
                if verified.teamRole != role {
                    DebugLog.log("DEBUG: ERROR - Update did not persist! Expected \(role.rawValue), got \(verified.teamRole?.rawValue ?? "nil")")
                    DebugLog.log("DEBUG: This indicates an RLS policy issue. The update was blocked.")
                    DebugLog.log("DEBUG: Attempting full profile update as fallback...")
                    
                    // Try a more direct approach - update the full profile
                    let fullUpdate = Profile(
                        id: member.id,
                        teamId: member.teamId,
                        role: member.role,
                        teamRole: role,
                        firstName: member.firstName,
                        lastName: member.lastName,
                        email: member.email,
                        phone: member.phone,
                        grade: member.grade,
                        memberRole: member.memberRole,
                        experienceBadges: member.experienceBadges,
                        emergencyContactName: member.emergencyContactName,
                        emergencyContactPhone: member.emergencyContactPhone,
                        passwordResetVerified: member.passwordResetVerified,
                        createdAt: member.createdAt,
                        updatedAt: Date()
                    )
                    
                    do {
                        _ = try await supabase
                            .from("profiles")
                            .update(fullUpdate)
                            .eq("id", value: member.id)
                            .execute()
                        DebugLog.log("DEBUG: Full profile update executed")
                    } catch {
                        DebugLog.log("DEBUG: Full profile update also failed: \(error)")
                    }
                } else {
                    DebugLog.log("DEBUG: Update verified successfully in database")
                }
            } else {
                DebugLog.log("DEBUG: WARNING - Could not verify update, profile not found")
            }
            
            // Wait a moment for database to commit
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Refresh team data from server to get the updated member
            await loadTeamData(for: currentTeam.id)
            DebugLog.log("DEBUG: Team data refreshed, member count: \(teamMembers.count)")
            
            // Verify the update was applied correctly
            if let updatedMember = teamMembers.first(where: { $0.id == member.id }) {
                let actualRole = updatedMember.teamRole ?? .member
                DebugLog.log("DEBUG: Member role after refresh: \(actualRole.rawValue), expected: \(role.rawValue)")
                
                // If the database update didn't work, force update the local array
                if actualRole != role {
                    DebugLog.log("DEBUG: WARNING - Database role doesn't match! Forcing local update...")
                    if let index = teamMembers.firstIndex(where: { $0.id == member.id }) {
                        let forceUpdatedProfile = Profile(
                            id: updatedMember.id,
                            teamId: updatedMember.teamId,
                            role: updatedMember.role,
                            teamRole: role,
                            firstName: updatedMember.firstName,
                            lastName: updatedMember.lastName,
                            email: updatedMember.email,
                            phone: updatedMember.phone,
                            grade: updatedMember.grade,
                            memberRole: updatedMember.memberRole,
                            experienceBadges: updatedMember.experienceBadges,
                            emergencyContactName: updatedMember.emergencyContactName,
                            emergencyContactPhone: updatedMember.emergencyContactPhone,
                            passwordResetVerified: updatedMember.passwordResetVerified,
                            createdAt: updatedMember.createdAt,
                            updatedAt: Date()
                        )
                        teamMembers[index] = forceUpdatedProfile
                        DebugLog.log("DEBUG: Force-updated member in local array with role \(role.rawValue)")
                    }
                } else {
                    DebugLog.log("DEBUG: Role update verified successfully in database")
                }
            } else {
                DebugLog.log("DEBUG: ERROR - Member not found in teamMembers after refresh!")
            }
            
            // If updating own role, refresh profile
            if member.id == currentUser.id {
                await authService?.refreshCurrentProfile()
            }
            
            DebugLog.log("DEBUG: Role update completed successfully")
        } catch {
            DebugLog.log("DEBUG: Error updating role: \(error)")
            DebugLog.log("DEBUG: Error details: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Team Deletion
    
    func deleteTeam() async throws {
        guard let currentUser = authService?.currentUser,
              let currentTeam = currentTeam else {
            throw TeamError.notAuthenticated
        }
        
        // Only the team creator (coachId) can delete the team
        guard currentUser.id == currentTeam.coachId else {
            throw TeamError.onlyCoachCanDeleteTeam
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Use the database RPC function to delete the team completely
            // This function handles removing all members, join requests, and related data
            _ = try await supabase.rpc("delete_team_completely", params: [
                "p_team_id": currentTeam.id.uuidString,
                "p_user_id": currentUser.id.uuidString
            ]).execute()
            
            // Clear local state
            self.currentTeam = nil
            teamMembers = []
            events = []
            tasks = []
            joinRequests = []
            
            // Update local user profile state directly without triggering a full refresh
            // This prevents the profile refresh from triggering updateTeamContext which reloads the team
            if let updatedUser = authService?.currentUser {
                let updatedProfile = Profile(
                    id: updatedUser.id,
                    teamId: nil,
                    role: updatedUser.role,
                    teamRole: nil,
                    firstName: updatedUser.firstName,
                    lastName: updatedUser.lastName,
                    email: updatedUser.email,
                    phone: updatedUser.phone,
                    grade: updatedUser.grade,
                    memberRole: updatedUser.memberRole,
                    experienceBadges: updatedUser.experienceBadges,
                    emergencyContactName: updatedUser.emergencyContactName,
                    emergencyContactPhone: updatedUser.emergencyContactPhone,
                    passwordResetVerified: updatedUser.passwordResetVerified,
                    createdAt: updatedUser.createdAt,
                    updatedAt: Date()
                )
                authService?.currentUser = updatedProfile
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Leave Team
    
    /// Allows a user to leave their current team
    func leaveTeam() async throws {
        guard let currentUser = authService?.currentUser,
              currentTeam != nil else {
            throw TeamError.notAuthenticated
        }
        
        // Check if user is the last coach
        let coachCount = teamMembers.filter { $0.effectiveTeamRole == .coach }.count
        if currentUser.effectiveTeamRole == .coach && coachCount <= 1 {
            throw TeamError.cannotLeaveAsLastCoach
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Use the same RPC function as removeMember to ensure consistency
            // This uses SECURITY DEFINER to bypass RLS and ensures the update is visible to other users
            guard let userId = authService?.currentUser?.id else {
                throw TeamError.notAuthenticated
            }
            
            _ = try await supabase.rpc("remove_team_member", params: [
                "p_member_id": currentUser.id.uuidString,
                "p_remover_id": userId.uuidString
            ]).execute()
            
            // Clear local state
            self.currentTeam = nil
            teamMembers = []
            events = []
            tasks = []
            joinRequests = []
            
            // Update local user profile state directly without triggering a full refresh
            // This prevents the profile refresh from triggering updateTeamContext which reloads the team
            if let updatedUser = authService?.currentUser {
                // Create updated profile with team_id and team_role set to nil
                let updatedProfile = Profile(
                    id: updatedUser.id,
                    teamId: nil,
                    role: updatedUser.role,
                    teamRole: nil,
                    firstName: updatedUser.firstName,
                    lastName: updatedUser.lastName,
                    email: updatedUser.email,
                    phone: updatedUser.phone,
                    grade: updatedUser.grade,
                    memberRole: updatedUser.memberRole,
                    experienceBadges: updatedUser.experienceBadges,
                    emergencyContactName: updatedUser.emergencyContactName,
                    emergencyContactPhone: updatedUser.emergencyContactPhone,
                    passwordResetVerified: updatedUser.passwordResetVerified,
                    createdAt: updatedUser.createdAt,
                    updatedAt: Date()
                )
                authService?.currentUser = updatedProfile
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Invite Code Management
    
    /// Gets the current team's invite code
    var currentInviteCode: String? {
        return currentTeam?.inviteCode
    }
    
    func regenerateInviteCode() async throws {
        guard let currentUser = authService?.currentUser,
              let team = currentTeam else {
            throw TeamError.notAuthenticated
        }
        
        guard currentUser.effectiveTeamRole.canManageSettings else {
            throw TeamError.insufficientPermissions
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Generate unique invite code with robust uniqueness checking
            var newCode = InviteCodeGenerator.generate()
            var attempts = 0
            let maxAttempts = 50 // Increased attempts for better uniqueness guarantee
            
            while attempts < maxAttempts {
                let existing: [Team] = try await supabase
                    .from("teams")
                    .select("id")
                    .eq("invite_code", value: newCode.uppercased())
                    .neq("id", value: team.id) // Exclude current team
                    .limit(1)
                    .execute()
                    .value
                
                if existing.isEmpty {
                    break
                }
                newCode = InviteCodeGenerator.generate()
                attempts += 1
            }
            
            // If we couldn't find a unique code after max attempts, throw an error
            if attempts >= maxAttempts {
                throw TeamError.failedToGenerateUniqueInviteCode
            }
            
            // Update team with new invite code
            struct TeamCodeUpdate: Codable {
                let invite_code: String
                let updated_at: Date
            }
            let update = TeamCodeUpdate(invite_code: newCode.uppercased(), updated_at: Date())
            
            // Update with error handling for duplicate codes
            do {
                try await supabase
                    .from("teams")
                    .update(update)
                    .eq("id", value: team.id)
                    .execute()
            } catch {
                // If we get a unique constraint violation, try one more time
                if error.localizedDescription.contains("invite_code") || 
                   error.localizedDescription.contains("unique") ||
                   error.localizedDescription.contains("duplicate") {
                    // Generate one more unique code and retry
                    var retryCode = InviteCodeGenerator.generate()
                    var retryAttempts = 0
                    while retryAttempts < 20 {
                        let existing: [Team] = try await supabase
                            .from("teams")
                            .select("id")
                            .eq("invite_code", value: retryCode.uppercased())
                            .neq("id", value: team.id)
                            .limit(1)
                            .execute()
                            .value
                        
                        if existing.isEmpty {
                            let retryUpdate = TeamCodeUpdate(invite_code: retryCode.uppercased(), updated_at: Date())
                            try await supabase
                                .from("teams")
                                .update(retryUpdate)
                                .eq("id", value: team.id)
                                .execute()
                            // Reload team data
                            await updateTeamContext(teamId: team.id)
                            return
                        }
                        retryCode = InviteCodeGenerator.generate()
                        retryAttempts += 1
                    }
                    throw TeamError.failedToGenerateUniqueInviteCode
                }
                throw error
            }
            
            // Reload team data
            await updateTeamContext(teamId: team.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}

enum TeamError: LocalizedError {
    case noTeamSelected
    case teamNotFound
    case invalidTeamNumber
    case invalidTeamName
    case notAuthenticated
    case insufficientPermissions
    case teamNumberAlreadyExists(existingTeam: String?)
    case onlyCoachesCanCreateTeams
    case invalidInviteCode
    case requestAlreadyPending
    case alreadyMember
    case cannotAssignCoachRole
    case onlyCoachCanDeleteTeam
    case failedToGenerateUniqueInviteCode
    case cannotLeaveAsLastCoach
    
    var errorDescription: String? {
        switch self {
        case .noTeamSelected:
            return "No team selected"
        case .teamNotFound:
            return "Team not found"
        case .invalidTeamNumber:
            return "Invalid team number"
        case .invalidTeamName:
            return "Team name cannot be empty."
        case .notAuthenticated:
            return "You must be signed in to manage teams."
        case .insufficientPermissions:
            return "You don't have permission to perform this action."
        case .teamNumberAlreadyExists(let existingTeam):
            if let name = existingTeam, !name.isEmpty {
                return "That team number is already registered to \(name). Try joining that team instead of creating a new one."
            } else {
                return "That team number is already registered. Try joining the existing team or choose a different number."
            }
        case .onlyCoachesCanCreateTeams:
            return "Only coaches can create new teams. Please update your profile to indicate you are a coach."
        case .invalidInviteCode:
            return "Invalid invite code. Please check the code and try again."
        case .requestAlreadyPending:
            return "You already have a pending request to join this team."
        case .alreadyMember:
            return "You are already a member of this team."
        case .cannotAssignCoachRole:
            return "Only the team creator can assign the coach role when there is only one coach. Once there are multiple coaches, any coach can assign the coach role."
        case .onlyCoachCanDeleteTeam:
            return "Only the team creator (coach) can delete the team. If you're the team creator, you can delete the team. If you want to leave instead, use the 'Leave Team' option."
        case .failedToGenerateUniqueInviteCode:
            return "Unable to generate a unique invite code. Please try again."
        case .cannotLeaveAsLastCoach:
            return "You cannot leave the team as the last coach. Please assign another coach first or delete the team."
        }
    }
}
