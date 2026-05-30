//
//  AnalyticsView.swift
//  FTCHUB
//
//  Advanced Features Hub
//  Groups all new analytics and advanced features
//

import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var teamService: TeamService
    
    var body: some View {
        Group {
            if teamService.currentTeam == nil {
                TeamAccessRequiredView(featureName: "Analytics")
                    .navigationTitle("Analytics")
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Analytics & Advanced Features")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Powerful tools for data analysis and strategic planning")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                        
                        
                        // Navigation Links
                        VStack(spacing: DesignSystem.Spacing.md) {
                            NavigationLink(destination: StatisticsView().navigationBarTitleDisplayMode(.inline)) {
                                AnalyticsRowCard(
                                    icon: "chart.bar.fill",
                                    title: "Team Statistics",
                                    description: "View OPR, DPR, CCWM and rankings",
                                    color: .blue
                                )
                            }
                            
                            NavigationLink(destination: AdvancementDashboardView().environmentObject(teamService).navigationBarTitleDisplayMode(.inline)) {
                                AnalyticsRowCard(
                                    icon: "trophy.fill",
                                    title: "Advancement Tracking",
                                    description: "Track qualification and playoff points",
                                    color: .orange
                                )
                            }
                            
                            NavigationLink(destination: CompatibilityCalculatorView().environmentObject(teamService).navigationBarTitleDisplayMode(.inline)) {
                                AnalyticsRowCard(
                                    icon: "person.3.fill",
                                    title: "Alliance Compatibility",
                                    description: "Calculate alliance compatibility scores",
                                    color: .purple
                                )
                            }
                            
                            NavigationLink(destination: PitScoutingFormView().environmentObject(teamService).navigationBarTitleDisplayMode(.inline)) {
                                AnalyticsRowCard(
                                    icon: "wrench.and.screwdriver.fill",
                                    title: "Pit Scouting",
                                    description: "Create and manage robot profiles",
                                    color: .teal
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
                .background(DesignSystem.Colors.background)
                .navigationTitle("Analytics")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .id("analytics-view-\(teamService.currentTeam?.id.uuidString ?? "no-team")")
    }
}

// MARK: - Row Card

struct AnalyticsRowCard: View {
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

#Preview {
    AnalyticsView()
        .environmentObject(TeamService())
}
