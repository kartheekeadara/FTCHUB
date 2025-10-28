//
//  QuickScoutView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct QuickScoutView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @Environment(\.dismiss) private var dismiss
    
    @State private var teamNumber: String = ""
    @State private var matchNumber: String = ""
    @State private var allianceColor: String = "Red"
    @State private var autoRating: Int = 3
    @State private var teleopRating: Int = 3
    @State private var overallRating: Int = 3
    @State private var quickNotes: String = ""
    @State private var isSubmitting = false
    
    @FocusState private var isTeamNumberFocused: Bool
    
    let recentTeams = ["12345", "54321", "99999"] // TODO: Load from recent reports
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("Quick Scout")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Fast 30-second data entry")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Match Info
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Team Number
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Team Number")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            HStack {
                                TextField("e.g., 12345", text: $teamNumber)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .focused($isTeamNumberFocused)
                                
                                if !recentTeams.isEmpty {
                                    Menu {
                                        ForEach(recentTeams, id: \.self) { team in
                                            Button(action: { teamNumber = team }) {
                                                Label("Team \(team)", systemImage: "clock.arrow.circlepath")
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "clock")
                                            .font(.title3)
                                            .foregroundColor(DesignSystem.Colors.primary)
                                            .padding(DesignSystem.Spacing.sm)
                                            .background(DesignSystem.Colors.tertiaryBackground)
                                            .cornerRadius(DesignSystem.CornerRadius.sm)
                                    }
                                }
                            }
                        }
                        
                        // Match Number
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Match Number")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("e.g., Q1, SF1-2", text: $matchNumber)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Alliance Color
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Alliance")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Alliance", selection: $allianceColor) {
                                Text("Red").tag("Red")
                                Text("Blue").tag("Blue")
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
                    
                    // Quick Ratings
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Quick Ratings (1-5)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            QuickRatingRow(label: "Autonomous", rating: $autoRating)
                            QuickRatingRow(label: "Teleop", rating: $teleopRating)
                            QuickRatingRow(label: "Overall", rating: $overallRating)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
                        
                        // Quick Notes
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Quick Notes")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextEditor(text: $quickNotes)
                                .frame(height: 80)
                                .padding(8)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                )
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
                    }
                    
                    // Submit Button
                    Button {
                        Task {
                            await submitQuickReport()
                        }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit & Next Match")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? DesignSystem.Gradients.primary : DesignSystem.Gradients.secondary)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .disabled(!isFormValid || isSubmitting)
                    .padding(.bottom, DesignSystem.Spacing.xl)
                    
                    // Full Scout Mode Button
                    Button(action: {
                        // Navigate to full scouting form
                        dismiss()
                    }) {
                        Text("Switch to Full Scout Mode")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding(.bottom, DesignSystem.Spacing.lg)
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Quick Scout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .alert("Success", isPresented: .constant(false)) {
                Button("OK") { }
            } message: {
                Text("Report submitted successfully!")
            }
            .onAppear {
                isTeamNumberFocused = true
            }
        }
    }
    
    var isFormValid: Bool {
        !teamNumber.isEmpty && !matchNumber.isEmpty
    }
    
    private func submitQuickReport() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        // Create minimal report data
        let reportData: [String: String] = [
            "Alliance Color": allianceColor,
            "Quick Auto Rating": String(autoRating),
            "Quick Teleop Rating": String(teleopRating),
            "Quick Overall Rating": String(overallRating),
            "Quick Notes": quickNotes
        ]
        
        guard let teamId = UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else {
            return
        }
        
        let newReport = ScoutingReport(
            id: UUID(),
            teamId: teamId,
            templateId: nil,
            scoutedTeamNumber: teamNumber,
            matchNumber: matchNumber,
            eventName: nil,
            phase: .teleop,
            scoutId: nil,
            reportData: reportData,
            notes: quickNotes,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await scoutingService.createScoutingReport(report: newReport)
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Clear form for next match
            teamNumber = ""
            matchNumber = ""
            autoRating = 3
            teleopRating = 3
            overallRating = 3
            quickNotes = ""
            
        } catch {
            // Error handling
        }
    }
}

struct QuickRatingRow: View {
    let label: String
    @Binding var rating: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Button {
                        rating = index
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        Image(systemName: index <= rating ? "star.fill" : "star")
                            .foregroundColor(index <= rating ? .yellow : .gray)
                            .font(.title2)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    QuickScoutView()
        .environmentObject(ScoutingService())
        .environmentObject(AuthService())
}
