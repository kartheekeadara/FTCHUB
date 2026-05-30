//
//  TeamJoinRequestsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct TeamJoinRequestsView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = false
    
    var body: some View {
        List {
            if teamService.joinRequests.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("No Pending Requests", systemImage: "person.badge.plus")
                    } description: {
                        Text("When users request to join your team, their requests will appear here for you to review.")
                    }
                }
            } else {
                Section {
                    ForEach(teamService.joinRequests) { request in
                        JoinRequestRow(request: request)
                    }
                } header: {
                    Text("\(teamService.joinRequests.count) Pending Request\(teamService.joinRequests.count == 1 ? "" : "s")")
                        .textCase(.none)
                }
            }
        }
        .navigationTitle("Join Requests")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await teamService.loadJoinRequests()
        }
        .refreshable {
            await teamService.loadJoinRequests()
        }
    }
}

struct JoinRequestRow: View {
    @EnvironmentObject var teamService: TeamService
    let request: TeamJoinRequest
    @State private var showingUserProfile: Profile?
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    if let profile = showingUserProfile {
                        Text(profile.displayName)
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(profile.email)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    } else {
                        Text("Loading...")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    if let message = request.message, !message.isEmpty {
                        Text("\"\(message)\"")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .italic()
                            .padding(.top, DesignSystem.Spacing.xs)
                    }
                }
                
                Spacer()
                
                Text(request.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Button(action: {
                    Task {
                        isLoading = true
                        do {
                            try await teamService.rejectJoinRequest(request)
                        } catch {
                            // Error handled by service
                        }
                        isLoading = false
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Decline")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.error)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.error.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .disabled(isLoading)
                
                Button(action: {
                    Task {
                        isLoading = true
                        do {
                            try await teamService.approveJoinRequest(request)
                        } catch {
                            // Error handled by service
                        }
                        isLoading = false
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Approve")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Gradients.primary)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.25), radius: 6, x: 0, y: 3)
                }
                .disabled(isLoading)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .task {
            await loadUserProfile()
        }
    }
    
    private func loadUserProfile() async {
        // Load user profile for the request
        // This would typically fetch from the service
        // For now, we'll use a placeholder approach
    }
}

#Preview {
    NavigationView {
        TeamJoinRequestsView()
            .environmentObject(TeamService())
            .environmentObject(AuthService())
    }
}

