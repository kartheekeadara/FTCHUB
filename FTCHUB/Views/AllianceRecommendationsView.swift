//
//  AllianceRecommendationsView.swift
//  FTCHUB
//
//  Phase 3: Alliance Recommendations
//  Displays recommended alliance partners for a captain
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AllianceRecommendationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var compatibilityService = AllianceCompatibilityService.shared
    @EnvironmentObject var teamService: TeamService
    let captainTeamNumber: String
    let eventName: String
    
    @State private var showShareSheet = false
    @State private var shareText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if compatibilityService.isLoading {
                    ProgressView("Generating recommendations…")
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else if let errorMessage = compatibilityService.errorMessage {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else if compatibilityService.recommendations.isEmpty {
                    ContentUnavailableView(
                        "No recommendations yet",
                        systemImage: "person.3",
                        description: Text("Generate ideas from your scouting data. Fewer reports means less reliable suggestions.")
                    )
                } else {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("These rankings are hints from your own scouting data—not a promise of performance. Watch matches and talk to drive teams before picking.")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.sm)
                        
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(compatibilityService.recommendations) { recommendation in
                                RecommendationCard(recommendation: recommendation)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        alliancePicksFeedbackRow
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.bottom, DesignSystem.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Alliance picks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !compatibilityService.recommendations.isEmpty {
                        Button {
                            shareText = exportPickListPlainText()
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share pick list")
                    }
                }
            }
            .task {
                if let teamId = teamService.currentTeam?.id {
                    try? await compatibilityService.generateRecommendations(
                        for: captainTeamNumber,
                        eventName: eventName,
                        teamId: teamId
                    )
                }
            }
            #if canImport(UIKit)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
            #endif
        }
    }
    
    private var alliancePicksFeedbackRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Were these pick ideas useful?")
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            HStack(spacing: 10) {
                Button("Yes") {
                    TelemetryService.shared.logEvent(
                        "alliance_picks_feedback",
                        parameters: ["vote": "yes", "event": eventName]
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                Button("Not really") {
                    TelemetryService.shared.logEvent(
                        "alliance_picks_feedback",
                        parameters: ["vote": "no", "event": eventName]
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func exportPickListPlainText() -> String {
        var lines: [String] = [
            "FTCHUB — \(eventName)",
            "Captain team: \(captainTeamNumber)",
            "",
            "Reminder: compatibility scores are estimates from limited scouting. Verify on the field.",
            ""
        ]
        for (index, rec) in compatibilityService.recommendations.enumerated() {
            lines.append("\(index + 1). Teams \(rec.partner1TeamNumber) + \(rec.partner2TeamNumber) — compatibility ~\(Int(rec.compatibilityScore * 100))% (\(rec.recommendationLevel.displayName))")
        }
        return lines.joined(separator: "\n")
    }
}

struct RecommendationCard: View {
    let recommendation: AllianceCompatibilityService.CompatibilityRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Team \(recommendation.partner1TeamNumber) + Team \(recommendation.partner2TeamNumber)")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Estimated compatibility: \(Int(recommendation.compatibilityScore * 100))% (small sample — confirm in person)")
                        .font(.caption)
                        .foregroundColor(recommendation.recommendationLevel.color)
                }
                
                Spacer()
                
                // Recommendation Level Badge
                Text(recommendation.recommendationLevel.displayName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(recommendation.recommendationLevel.color)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            }
            
            Divider()
            
            // Reasoning
            if !recommendation.reasoning.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Why This Works")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ForEach(recommendation.reasoning, id: \.self) { reason in
                        HStack(alignment: .top) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
            
            // Key Strengths
            if !recommendation.keyStrengths.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Strengths")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ForEach(recommendation.keyStrengths.prefix(3), id: \.self) { strength in
                        Text("• \(strength)")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            // Potential Weaknesses
            if !recommendation.potentialWeaknesses.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Considerations")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ForEach(recommendation.potentialWeaknesses.prefix(2), id: \.self) { weakness in
                        Text("• \(weakness)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.secondaryBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    AllianceRecommendationsView(captainTeamNumber: "1234", eventName: "Regional")
        .environmentObject(TeamService())
}
