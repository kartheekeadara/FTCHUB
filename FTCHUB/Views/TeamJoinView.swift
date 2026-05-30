//
//  TeamJoinView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct TeamJoinView: View {
    @EnvironmentObject var teamService: TeamService
    @Environment(\.dismiss) private var dismiss
    
    @State private var teamNumber = ""
    @State private var isJoining = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("Join Existing Team")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Enter the invite code to join a team")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignSystem.Spacing.xl)
                    
                    // Form
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        CustomTextField(
                            title: "Invite Code *",
                            text: $teamNumber,
                            placeholder: "e.g., ABC123"
                        )
                        .textInputAutocapitalization(.characters)
                        
                        Text("You'll join the team immediately. Membership is permanent unless you leave or are removed.")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Join Button
                    Button(action: requestToJoin) {
                        HStack {
                            if isJoining {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isJoining ? "Joining..." : "Join Team")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? DesignSystem.Gradients.primary : DesignSystem.Gradients.secondary)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .disabled(!isFormValid || isJoining)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Join Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert(showingError && (errorMessage.contains("Successfully") || errorMessage.contains("joined")) ? "Success" : "Error", isPresented: $showingError) {
            Button("OK") {
                if errorMessage.contains("Successfully") || errorMessage.contains("joined") {
                    dismiss()
                }
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        !teamNumber.isEmpty
    }
    
    private func requestToJoin() {
        guard isFormValid else { return }
        
        isJoining = true
        
        Task {
            do {
                try await teamService.requestToJoinTeam(inviteCode: teamNumber)
                
                await MainActor.run {
                    errorMessage = "Successfully joined the team!"
                    showingError = true
                    isJoining = false
                    // Dismiss after a short delay to show success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isJoining = false
                }
            }
        }
    }
}

#Preview {
    TeamJoinView()
        .environmentObject(TeamService())
}