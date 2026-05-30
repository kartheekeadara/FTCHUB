//
//  CompatibilityCalculatorView.swift
//  FTCHUB
//
//  Phase 3: Alliance Compatibility Calculator
//  Calculate and display compatibility scores for alliance selection
//

import SwiftUI

struct CompatibilityCalculatorView: View {
    @StateObject private var compatibilityService = AllianceCompatibilityService.shared
    @EnvironmentObject var teamService: TeamService
    @State private var captainTeamNumber = ""
    @State private var partner1TeamNumber = ""
    @State private var partner2TeamNumber = ""
    @State private var eventName = ""
    @State private var calculatedScore: AllianceCompatibilityService.CompatibilityScore?
    @State private var showingRecommendations = false
    
    var body: some View {
        ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Input Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Alliance Composition")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        TextField("Captain Team Number", text: $captainTeamNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        
                        TextField("Partner 1 Team Number", text: $partner1TeamNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        
                        TextField("Partner 2 Team Number", text: $partner2TeamNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        
                        TextField("Event Name", text: $eventName)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            Task {
                                if let teamId = teamService.currentTeam?.id {
                                    calculatedScore = try? await compatibilityService.calculateCompatibility(
                                        captain: captainTeamNumber,
                                        partner1: partner1TeamNumber,
                                        partner2: partner2TeamNumber,
                                        eventName: eventName,
                                        teamId: teamId
                                    )
                                }
                            }
                        } label: {
                            HStack {
                                if compatibilityService.isLoading {
                                    ProgressView()
                                }
                                Text("Calculate Compatibility")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                        .disabled(captainTeamNumber.isEmpty || partner1TeamNumber.isEmpty || partner2TeamNumber.isEmpty || compatibilityService.isLoading)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Colors.secondaryBackground)
                    )
                    
                    // Results Section
                    if let score = calculatedScore {
                        CompatibilityScoreCard(score: score)
                        
                        // Phase Coverage Visualization
                        PhaseCoverageCard(score: score)
                        
                        // Breakdown Section
                        CompatibilityBreakdownCard(score: score)
                    }
                    
                    // Recommendations Button
                    if !captainTeamNumber.isEmpty {
                        Button {
                            showingRecommendations = true
                        } label: {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                Text("View Recommendations")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Colors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
        }
        .navigationTitle("Alliance Compatibility")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRecommendations) {
            AllianceRecommendationsView(captainTeamNumber: captainTeamNumber, eventName: eventName)
                .environmentObject(teamService)
        }
    }
}

// MARK: - Compatibility Score Card

struct CompatibilityScoreCard: View {
    let score: AllianceCompatibilityService.CompatibilityScore
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Overall Score
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Compatibility Score")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(String(format: "%.0f%%", score.overall * 100))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(score.recommendationLevel.color)
                
                Text(score.recommendationLevel.displayName)
                    .font(.headline)
                    .foregroundColor(score.recommendationLevel.color)
            }
            .padding(DesignSystem.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(score.recommendationLevel.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(score.recommendationLevel.color.opacity(0.3), lineWidth: 2)
                    )
            )
            
            // Alliance Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Alliance: Team \(score.captainTeamNumber) + \(score.partner1TeamNumber ?? "") + \(score.partner2TeamNumber ?? "")")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

// MARK: - Phase Coverage Card

struct PhaseCoverageCard: View {
    let score: AllianceCompatibilityService.CompatibilityScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Phase Coverage")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                PhaseBar(label: "Autonomous", value: score.autoCoverage)
                PhaseBar(label: "TeleOp", value: score.teleopCoverage)
                PhaseBar(label: "Endgame", value: score.endgameCoverage)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

struct PhaseBar: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(String(format: "%.0f%%", value * 100))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(value > 0.7 ? .green : value > 0.5 ? .yellow : .orange)
                        .frame(width: geometry.size.width * value, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Compatibility Breakdown Card

struct CompatibilityBreakdownCard: View {
    let score: AllianceCompatibilityService.CompatibilityScore
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Score Breakdown")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                BreakdownRow(label: "Phase Coverage", value: score.phaseCoverage, weight: 0.40)
                BreakdownRow(label: "Complementary Strengths", value: score.complementaryStrengths, weight: 0.25)
                BreakdownRow(label: "Historical Synergy", value: score.historicalSynergy, weight: 0.20)
                BreakdownRow(label: "Strategic Compatibility", value: score.strategicCompatibility, weight: 0.10)
                BreakdownRow(label: "Reliability", value: score.reliability, weight: 0.05)
            }
            
            Divider()
            
            // Key Strengths
            if !score.keyStrengths.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Key Strengths")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ForEach(score.keyStrengths, id: \.self) { strength in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(strength)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
            
            // Potential Weaknesses
            if !score.potentialWeaknesses.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Potential Weaknesses")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ForEach(score.potentialWeaknesses, id: \.self) { weakness in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(weakness)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
            
            // Strategic Notes
            if !score.strategicNotes.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Strategic Notes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(score.strategicNotes)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

struct BreakdownRow: View {
    let label: String
    let value: Double
    let weight: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(String(format: "%.2f (%.0f%%)", value, weight * 100))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

#Preview {
    CompatibilityCalculatorView()
}
