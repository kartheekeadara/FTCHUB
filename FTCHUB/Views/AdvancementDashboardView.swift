//
//  AdvancementDashboardView.swift
//  FTCHUB
//
//  Phase 2: Advancement Tracking Dashboard
//  Displays season summary and advancement progress
//

import SwiftUI

struct AdvancementDashboardView: View {
    @StateObject private var advancementService = AdvancementTrackingService.shared
    @EnvironmentObject var teamService: TeamService
    @State private var selectedSeasonYear: Int = Calendar.current.component(.year, from: Date())
    @State private var showingEventEntry = false
    
    var body: some View {
        ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Season Summary Card
                    if let summary = advancementService.seasonSummary {
                        SeasonSummaryCard(summary: summary)
                    } else {
                        ContentUnavailableView {
                            Label("No Season Data", systemImage: "chart.bar.fill")
                        } description: {
                            Text("Add event results to track your advancement progress")
                        }
                    }
                    
                    // Advancement Status
                    if let status = advancementService.advancementStatus {
                        AdvancementStatusCard(status: status)
                    }
                    
                    // Event Points List
                    if !advancementService.eventPoints.isEmpty {
                        EventPointsListSection(points: advancementService.eventPoints)
                    }
                    
                    // Quick Actions
                    QuickActionsSection(showingEventEntry: $showingEventEntry)
                }
                .padding(DesignSystem.Spacing.md)
            }
            .navigationTitle("Advancement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEventEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingEventEntry) {
                EventPointsEntryView()
            }
            .task {
                // Load data for current season
                if let teamId = teamService.currentTeam?.id {
                    try? await advancementService.loadSeasonSummary(teamId: teamId, seasonYear: selectedSeasonYear)
                    await advancementService.loadEventPoints(teamId: teamId, seasonYear: selectedSeasonYear)
                }
            }
    }
}

// MARK: - Season Summary Card

struct SeasonSummaryCard: View {
    let summary: AdvancementTrackingService.SeasonAdvancementSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Season \(summary.seasonYear)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Divider()
            
            // Total Points
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Total Points")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("\(summary.totalPoints)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("Events Attended")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text("\(summary.eventsAttended)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            
            // Points Breakdown
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("Qualification Points:")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text("\(summary.totalQualificationPoints)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                HStack {
                    Text("Playoff Points:")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text("\(summary.totalPlayoffPoints)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
            
            // Next Milestone
            if let nextMilestone = summary.nextMilestone, let pointsToNext = summary.pointsToNextMilestone {
                Divider()
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Next Milestone")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(nextMilestone)
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if pointsToNext > 0 {
                        HStack {
                            ProgressView(value: Double(summary.totalPoints), total: Double(summary.totalPoints + pointsToNext))
                                .tint(DesignSystem.Colors.primary)
                            Text("\(pointsToNext) points needed")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.secondaryBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Advancement Status Card

struct AdvancementStatusCard: View {
    let status: AdvancementTrackingService.AdvancementStatus
    
    var statusColor: Color {
        switch status.status {
        case .qualified:
            return .green
        case .pending:
            return .orange
        case .notQualified:
            return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: status.status == .qualified ? "checkmark.circle.fill" : "clock.fill")
                    .foregroundColor(statusColor)
                    .font(.title2)
                
                Text("Status: \(status.status.displayName)")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("Current Level:")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text(status.currentLevel.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                HStack {
                    Text("Advancement Probability:")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text(String(format: "%.0f%%", status.advancementProbability * 100))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(statusColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Event Points List Section

struct EventPointsListSection: View {
    let points: [AdvancementTrackingService.EventPoints]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Event Results")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(points) { point in
                EventPointRow(point: point)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

struct EventPointRow: View {
    let point: AdvancementTrackingService.EventPoints
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(point.eventName)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(point.totalQualificationPoints) pts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Label("\(point.winPoints)", systemImage: "trophy.fill")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                if point.tiePoints > 0 {
                    Label("\(point.tiePoints)", systemImage: "equal")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                if point.awardPoints > 0 {
                    Label("\(point.awardPoints)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                if let ranking = point.finalRanking {
                    Label("#\(ranking)", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.tertiaryBackground)
        )
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    @Binding var showingEventEntry: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Button {
                showingEventEntry = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Event Results")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(DesignSystem.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.secondaryBackground)
        )
    }
}

#Preview {
    AdvancementDashboardView()
}
