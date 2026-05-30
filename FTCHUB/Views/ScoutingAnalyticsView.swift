//
//  ScoutingAnalyticsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
import Charts
#if canImport(UIKit)
import UIKit
#endif

struct ScoutingAnalyticsView: View {
    /// When opened from Strategy & data hub: emphasize **your** reports; hide third‑party stat shortcuts here.
    var strategyHubEntry: Bool = false
    
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var teamService: TeamService
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(DesignSystem.Gradients.primary)
                        .padding(.top, DesignSystem.Spacing.xl)
                    
                    Text("Scouting Analytics")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(strategyHubEntry
                         ? "Numbers below come only from scouting reports your team saved in FTCHUB."
                         : "Advanced analytics and strategic planning tools")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                
                // Quick Stats Overview — hidden when entered from Strategy & data hub
                // (the hub already shows the same data-health pills, so this would duplicate).
                if !scoutingService.scoutingReports.isEmpty && !strategyHubEntry {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Quick Stats")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            QuickStatCard(
                                title: "Teams Scouted",
                                value: "\(scoutingService.uniqueTeamsScoutedCount)",
                                icon: "person.3.fill",
                                color: .blue
                            )
                            
                            QuickStatCard(
                                title: "Reports",
                                value: "\(scoutingService.scoutingReports.count)",
                                icon: "doc.text.fill",
                                color: .orange
                            )
                            
                            QuickStatCard(
                                title: "Avg Quality",
                                value: formattedAverage(scoutingService.averageOverallQuality),
                                icon: "star.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
                
                // Strategy & data hub is the single home for pit scouting, alliance compatibility,
                // pick lists, and external statistics — link there instead of duplicating those rows.
                if !strategyHubEntry {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("More Tools")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        NavigationLink(destination: Phase4IntelligenceHubView().navigationBarTitleDisplayMode(.inline)) {
                            ScoutingAnalyticsRowCard(
                                icon: "sparkles",
                                title: "Strategy & data",
                                description: "Pick lists, compatibility, pit scouting, and external stats",
                                color: .orange
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
                
                // Scouting Reports Analytics (Keep existing functionality)
                if !scoutingService.scoutingReports.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Report Analytics")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.md)
                        
                        NavigationLink(destination: ScoutingReportsAnalyticsView().environmentObject(scoutingService).navigationBarTitleDisplayMode(.inline)) {
                            ScoutingAnalyticsRowCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Scouting Reports Analytics",
                                description: "Trends, insights, and breakdowns from your reports",
                                color: .indigo
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func formattedAverage(_ value: Double?) -> String {
        guard let value, value.isFinite, !value.isNaN else { return "—" }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}

// MARK: - Helper Views

private struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

private struct ScoutingAnalyticsRowCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
    }
}
