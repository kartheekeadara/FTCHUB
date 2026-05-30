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
    @State private var autoArtifacts: Int = 0
    @State private var autoSuccess: Bool = false
    @State private var teleopArtifacts: Int = 0
    @State private var endgameSuccess: Bool = false
    @State private var reliabilityFlag: ReliabilityFlag = .ok
    @State private var selectedPenalties: Set<PenaltyType> = []
    @State private var quickSummary: String = ""
    @State private var isSubmitting = false
    
    @FocusState private var isTeamNumberFocused: Bool
    
    // Recent teams will be loaded from scouting service
    var recentTeams: [String] {
        // Load from recent scouting reports
        // This will be populated from ScoutingService when available
        []
    }
    
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
                    
                    // Match Performance
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Autonomous
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Autonomous")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Text("Artifacts:")
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Stepper(value: $autoArtifacts, in: 0...20) {
                                    Text("\(autoArtifacts)")
                                        .font(.headline)
                                        .frame(width: 40)
                                }
                                
                                Spacer()
                                
                                Toggle("Success", isOn: $autoSuccess)
                                    .toggleStyle(.switch)
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
                        
                        // Teleop
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Teleop")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            HStack {
                                Text("Artifacts:")
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Stepper(value: $teleopArtifacts, in: 0...50) {
                                    Text("\(teleopArtifacts)")
                                        .font(.headline)
                                        .frame(width: 40)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
                        
                        // Endgame
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Endgame")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Toggle("Park/Bonus Success", isOn: $endgameSuccess)
                                .toggleStyle(.switch)
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
                        
                        // Reliability & Penalties
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Reliability")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Picker("Reliability", selection: $reliabilityFlag) {
                                ForEach(ReliabilityFlag.allCases, id: \.self) { flag in
                                    Text(flag.displayName).tag(flag)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Divider()
                                .padding(.vertical, DesignSystem.Spacing.xs)
                            
                            Text("Penalties")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignSystem.Spacing.xs) {
                                ForEach(PenaltyType.allCases, id: \.self) { penalty in
                                    Button {
                                        if selectedPenalties.contains(penalty) {
                                            selectedPenalties.remove(penalty)
                                        } else {
                                            selectedPenalties.insert(penalty)
                                        }
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                    } label: {
                                        HStack {
                                            Image(systemName: selectedPenalties.contains(penalty) ? "checkmark.circle.fill" : "circle")
                                            Text(penalty.displayName)
                                                .font(.caption)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selectedPenalties.contains(penalty) ? DesignSystem.Colors.primary.opacity(0.2) : DesignSystem.Colors.tertiaryBackground)
                                        .foregroundColor(selectedPenalties.contains(penalty) ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)
                                        .cornerRadius(DesignSystem.CornerRadius.sm)
                                    }
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
                        
                        // Quick Summary
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("One-Line Summary")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Best short summary for drive team")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextField("e.g., Fast scorer; endgame shaky; avoid continuous contact", text: $quickSummary, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(2...4)
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
        
        // Create report data with essential fields
        let penaltyTypesString = selectedPenalties.map { $0.rawValue }.joined(separator: ", ")
        
        let reportData: [String: String] = [
            "Alliance Color": allianceColor,
            "Match Phase": MatchPhase.teleop.rawValue,
            "Auto Artifacts": String(autoArtifacts),
            "Auto Success": autoSuccess ? "true" : "false",
            "Teleop Artifacts": String(teleopArtifacts),
            "Endgame Success": endgameSuccess ? "true" : "false",
            "Reliability Flag": reliabilityFlag.rawValue,
            "Penalties": penaltyTypesString.isEmpty ? "None" : penaltyTypesString,
            "Quick Summary": quickSummary
        ]
        
        guard let teamId = scoutingService.currentTeamId else {
            scoutingService.errorMessage = "Join or create a team before saving scouting reports."
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
            notes: quickSummary.isEmpty ? nil : quickSummary,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await scoutingService.createScoutingReport(report: newReport)
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Clear form for next match (keep team number for quick entry)
            matchNumber = ""
            autoArtifacts = 0
            autoSuccess = false
            teleopArtifacts = 0
            endgameSuccess = false
            reliabilityFlag = .ok
            selectedPenalties = []
            quickSummary = ""
            
        } catch {
            // Error handling
        }
    }
}


#Preview {
    QuickScoutView()
        .environmentObject(ScoutingService())
        .environmentObject(AuthService())
}
