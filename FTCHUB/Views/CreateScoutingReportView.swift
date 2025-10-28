//
//  CreateScoutingReportView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct CreateScoutingReportView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @Environment(\.dismiss) private var dismiss
    
    // Basic Match Info
    @State private var scoutedTeamNumber: String = ""
    @State private var matchNumber: String = ""
    @State private var allianceColor: String = "Red"
    @State private var eventName: String = ""
    
    // Autonomous (30 sec)
    @State private var autoGreenArtifacts: Int = 0
    @State private var autoPurpleArtifacts: Int = 0
    @State private var autoReliability: Int = 3
    
    // Teleop (120 sec)
    @State private var teleopGreenArtifacts: Int = 0
    @State private var teleopPurpleArtifacts: Int = 0
    @State private var allianceCoordination: Bool = false
    @State private var drivingQuality: Double = 3.0
    @State private var robotSpeed: Double = 3.0
    @State private var primaryStrategy: String = "Offensive Scoring"
    @State private var defendsWell: Bool = false
    @State private var penalties: Int = 0
    
    // Endgame (30 sec)
    @State private var endgameGreenArtifacts: Int = 0
    @State private var endgamePurpleArtifacts: Int = 0
    @State private var parkedInZone: Bool = false
    @State private var endgameExecution: Int = 3
    
    // Overall Assessment
    @State private var overallQuality: Double = 3.0
    @State private var allianceSelectionRating: Double = 3.0
    @State private var reliability: String = "Mostly Reliable"
    @State private var artifactStrategyNotes: String = ""
    @State private var generalNotes: String = ""
    @State private var allianceNotes: String = ""
    
    @State private var isSubmitting = false
    
    let strategyOptions = ["Offensive Scoring", "Defensive", "Mixed", "Artifact Collection"]
    let allianceColors = ["Red", "Blue"]
    let reliabilityOptions = ["Very Reliable", "Mostly Reliable", "Sometimes Broken", "Often Broken"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(DesignSystem.Gradients.primary)
                    
                    Text("Scout Team")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("DECODE 2025-2026")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.lg)
                
                // Match Info Card
                CardView(title: "Match Information", icon: "info.circle") {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        CustomTextField(title: "Team Number", text: $scoutedTeamNumber, placeholder: "e.g., 12345")
                        CustomTextField(title: "Match Number", text: $matchNumber, placeholder: "e.g., Q1, SF1-2")
                        CustomTextField(title: "Event Name", text: $eventName, placeholder: "e.g., Regional Qualifier")
                        
                        Picker("Alliance Color", selection: $allianceColor) {
                            ForEach(allianceColors, id: \.self) { color in
                                Text(color).tag(color)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // Autonomous Card
                CardView(title: "Autonomous (30 sec)", icon: "play.circle.fill") {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            VStack(alignment: .leading) {
                                Text("Green Artifacts")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Stepper("", value: $autoGreenArtifacts, in: 0...10)
                                Text("\(autoGreenArtifacts) scored")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Purple Artifacts")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Stepper("", value: $autoPurpleArtifacts, in: 0...10)
                                Text("\(autoPurpleArtifacts) scored")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Autonomous Reliability")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= autoReliability ? "star.fill" : "star")
                                        .foregroundColor(star <= autoReliability ? .yellow : .gray)
                                        .onTapGesture {
                                            autoReliability = star
                                        }
                                }
                            }
                        }
                    }
                }
                
                // Teleop Card
                CardView(title: "Teleop (120 sec)", icon: "person.circle.fill") {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            VStack(alignment: .leading) {
                                Text("Green Artifacts")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Stepper("", value: $teleopGreenArtifacts, in: 0...50)
                                Text("\(teleopGreenArtifacts) placed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Purple Artifacts")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Stepper("", value: $teleopPurpleArtifacts, in: 0...50)
                                Text("\(teleopPurpleArtifacts) placed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        Toggle("Alliance Coordination", isOn: $allianceCoordination)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Driving Quality")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Slider(value: $drivingQuality, in: 1...5, step: 1)
                            HStack {
                                Text("1")
                                Spacer()
                                Text("\(Int(drivingQuality))")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("5")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Robot Speed")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Slider(value: $robotSpeed, in: 1...5, step: 1)
                            HStack {
                                Text("Slow")
                                Spacer()
                                Text("\(Int(robotSpeed))")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Fast")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        Picker("Primary Strategy", selection: $primaryStrategy) {
                            ForEach(strategyOptions, id: \.self) { strategy in
                                Text(strategy).tag(strategy)
                            }
                        }
                        
                        Toggle("Defends Well", isOn: $defendsWell)
                        
                        HStack {
                            Text("Penalties")
                            Spacer()
                            Stepper("", value: $penalties, in: 0...10)
                            Text("\(penalties)")
                                .frame(width: 40)
                        }
                    }
                }
                
                // Endgame Card
                CardView(title: "Endgame (30 sec)", icon: "flag.circle.fill") {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            VStack(alignment: .leading) {
                                Text("Green Artifacts")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Stepper("", value: $endgameGreenArtifacts, in: 0...5)
                                Text("\(endgameGreenArtifacts) additional")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Purple Artifacts")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Stepper("", value: $endgamePurpleArtifacts, in: 0...5)
                                Text("\(endgamePurpleArtifacts) additional")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        Toggle("Parked in Zone", isOn: $parkedInZone)
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Endgame Execution")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            HStack {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= endgameExecution ? "star.fill" : "star")
                                        .foregroundColor(star <= endgameExecution ? .yellow : .gray)
                                        .onTapGesture {
                                            endgameExecution = star
                                        }
                                }
                            }
                        }
                    }
                }
                
                // Overall Assessment Card
                CardView(title: "Overall Assessment", icon: "chart.bar.fill") {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Overall Team Quality")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Slider(value: $overallQuality, in: 1...5, step: 1)
                            HStack {
                                Text("1")
                                Spacer()
                                Text("\(Int(overallQuality))")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("5")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Alliance Selection Rating")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Slider(value: $allianceSelectionRating, in: 1...5, step: 1)
                            HStack {
                                Text("1")
                                Spacer()
                                Text("\(Int(allianceSelectionRating))")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("5")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        Picker("Robot Reliability", selection: $reliability) {
                            ForEach(reliabilityOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Artifact Strategy Notes")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextEditor(text: $artifactStrategyNotes)
                                .frame(height: 60)
                                .padding(8)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("General Notes")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextEditor(text: $generalNotes)
                                .frame(height: 60)
                                .padding(8)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Alliance Selection Notes")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextEditor(text: $allianceNotes)
                                .frame(height: 60)
                                .padding(8)
                                .background(DesignSystem.Colors.tertiaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                    }
                }
                
                // Submit Button
                Button(action: {
                    Task {
                        await submitReport()
                    }
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isSubmitting ? "Submitting..." : "Submit Scouting Report")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? DesignSystem.Gradients.primary : DesignSystem.Gradients.secondary)
                    .foregroundColor(.white)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .disabled(!isFormValid || isSubmitting)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("New Scout Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .alert("Error", isPresented: Binding(get: { scoutingService.errorMessage != nil }, set: { _ in scoutingService.errorMessage = nil })) {
            Button("OK") { }
        } message: {
            Text(scoutingService.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    var isFormValid: Bool {
        !scoutedTeamNumber.isEmpty && !matchNumber.isEmpty
    }
    
    private func submitReport() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        // Convert form data to report format
        let reportData: [String: String] = [
            "Alliance Color": allianceColor,
            "Auto Green Artifacts": String(autoGreenArtifacts),
            "Auto Purple Artifacts": String(autoPurpleArtifacts),
            "Auto Reliability": String(autoReliability),
            "Teleop Green Artifacts": String(teleopGreenArtifacts),
            "Teleop Purple Artifacts": String(teleopPurpleArtifacts),
            "Alliance Coordination": allianceCoordination ? "true" : "false",
            "Driving Quality": String(Int(drivingQuality)),
            "Robot Speed": String(Int(robotSpeed)),
            "Primary Strategy": primaryStrategy,
            "Defends Well": defendsWell ? "true" : "false",
            "Penalties": String(penalties),
            "Endgame Green Artifacts": String(endgameGreenArtifacts),
            "Endgame Purple Artifacts": String(endgamePurpleArtifacts),
            "Parked in Zone": parkedInZone ? "true" : "false",
            "Endgame Execution": String(endgameExecution),
            "Overall Quality": String(Int(overallQuality)),
            "Alliance Selection Rating": String(Int(allianceSelectionRating)),
            "Reliability": reliability,
            "Artifact Strategy Notes": artifactStrategyNotes,
            "General Notes": generalNotes,
            "Alliance Selection Notes": allianceNotes
        ]
        
        guard let teamId = UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11") else {
            scoutingService.errorMessage = "Team ID not available."
            return
        }
        
        let newReport = ScoutingReport(
            id: UUID(),
            teamId: teamId,
            templateId: nil,
            scoutedTeamNumber: scoutedTeamNumber,
            matchNumber: matchNumber,
            eventName: eventName.isEmpty ? nil : eventName,
            phase: .teleop,
            scoutId: nil,
            reportData: reportData,
            notes: generalNotes,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await scoutingService.createScoutingReport(report: newReport)
            dismiss()
        } catch {
            // Error handled by service
        }
    }
}

// MARK: - Helper View: Card
struct CardView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(DesignSystem.Gradients.primary)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            content
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

#Preview {
    NavigationView {
        CreateScoutingReportView()
            .environmentObject(ScoutingService())
            .environmentObject(AuthService())
    }
}