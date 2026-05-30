//
//  TeamCreationView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct TeamCreationView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var teamName = ""
    @State private var teamNumber = ""
    @State private var school = ""
    @State private var city = ""
    @State private var state = ""
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("Create New Team")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Set up your FTC team profile")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, DesignSystem.Spacing.xl)
                    
                    // Form
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        CustomTextField(
                            title: "Team Name *",
                            text: $teamName,
                            placeholder: "e.g., Thunder Robotics"
                        )
                        
                        CustomTextField(
                            title: "Team Number *",
                            text: $teamNumber,
                            placeholder: "e.g., 12345"
                        )
                        .keyboardType(.numberPad)
                        
                        CustomTextField(
                            title: "School/Organization",
                            text: $school,
                            placeholder: "e.g., Lincoln High School"
                        )
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            CustomTextField(
                                title: "City",
                                text: $city,
                                placeholder: "e.g., San Francisco"
                            )
                            
                            CustomTextField(
                                title: "State",
                                text: $state,
                                placeholder: "e.g., CA"
                            )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Create Button
                    Button(action: createTeam) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isCreating ? "Creating..." : "Create Team")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? DesignSystem.Gradients.primary : DesignSystem.Gradients.secondary)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .disabled(!isFormValid || isCreating)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Create Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        !teamName.isEmpty && !teamNumber.isEmpty
    }
    
    private func createTeam() {
        guard isFormValid else { return }
        
        isCreating = true
        
        Task {
            do {
                try await teamService.createTeam(
                    name: teamName,
                    number: teamNumber,
                    school: school.isEmpty ? nil : school,
                    city: city.isEmpty ? nil : city,
                    state: state.isEmpty ? nil : state
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isCreating = false
                }
            }
        }
    }
}

#Preview {
    TeamCreationView()
        .environmentObject(TeamService())
}