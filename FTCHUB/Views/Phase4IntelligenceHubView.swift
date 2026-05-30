//
//  Phase4IntelligenceHubView.swift
//  FTCHUB
//
//  Strategy & data: event-ready hub (data health, alliance prep, match day, learning).
//

import SwiftUI

struct Phase4IntelligenceHubView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var scheduleService: ScheduleService
    
    @StateObject private var picklistStore = AlliancePicklistStore()
    @State private var showQuickScout = false
    
    private var inferredEventName: String {
        let names = scheduleService.matches.compactMap { $0.eventName }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return names.first ?? "Current season"
    }
    
    private var upcomingMatch: Match? {
        let sorted = scheduleService.matches
            .filter { $0.status == .scheduled || $0.status == .inProgress }
            .sorted { $0.scheduledTime < $1.scheduledTime }
        return sorted.first { $0.scheduledTime > Date().addingTimeInterval(-15 * 60) }
            ?? sorted.first
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                heroCard
                disclaimerCard
                dataHealthCard
                alliancePrepCard
                matchDayCard
                learnAndCalibrateCard
                feedbackCard
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .ftchubRootNavHeader(title: "Strategy & data")
        .onAppear {
            syncPicklistTeam()
            TelemetryService.shared.logEvent("phase4_intel_hub_opened")
        }
        .onChange(of: teamService.currentTeam?.id) { _, _ in
            syncPicklistTeam()
        }
        .sheet(isPresented: $showQuickScout) {
            QuickScoutView()
                .environmentObject(scoutingService)
        }
    }
    
    private func syncPicklistTeam() {
        picklistStore.updateTeamContext(teamService.currentTeam?.id)
    }
    
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: 44, height: 44)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strategy & data")
                        .font(.title2.weight(.bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Text("Turn scouting into picks, plans, and calmer decisions.")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var disclaimerCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundColor(DesignSystem.Colors.warning)
            Text("Scouting data is an input, not a promise. Consistency beats peak scores—confirm capability on the field and follow your event’s rules.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.warning.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.warning.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Data health
    
    private var dataHealthCard: some View {
        Phase4SectionCard(title: "Data health", subtitle: "Trust starts with coverage", icon: "heart.text.square", tint: DesignSystem.Colors.focus) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                if scoutingService.scoutingReports.isEmpty {
                    Text("No scouting reports yet. Add match scouting before alliance math means much.")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.bottom, DesignSystem.Spacing.sm)
                } else {
                    HStack {
                        dataPill(title: "Reports", value: "\(scoutingService.scoutingReports.count)")
                        dataPill(title: "Teams", value: "\(scoutingService.uniqueTeamsScoutedCount)")
                        if let avg = scoutingService.averageOverallQuality {
                            dataPill(title: "Avg quality", value: avg.formatted(.number.precision(.fractionLength(1))))
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.sm)
                }
                
                Phase4RowDivider()
                NavigationLink {
                    ScoutingAnalyticsView(strategyHubEntry: true)
                        .environmentObject(scoutingService)
                        .environmentObject(teamService)
                } label: {
                    Phase4LinkRow(title: "Scouting analytics (your data)", systemImage: "chart.bar.xaxis", tint: DesignSystem.Colors.focus)
                }
                .buttonStyle(.plain)
                
                if !scoutingService.scoutingReports.isEmpty {
                    Phase4RowDivider()
                    NavigationLink {
                        ScoutingReportsAnalyticsView()
                            .environmentObject(scoutingService)
                    } label: {
                        Phase4LinkRow(title: "Report depth & trends", systemImage: "chart.line.uptrend.xyaxis", tint: DesignSystem.Colors.focus)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func dataPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.tertiaryBackground.opacity(0.6))
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
    
    // MARK: - Alliance prep
    
    private var alliancePrepCard: some View {
        Phase4SectionCard(title: "Alliance prep", subtitle: "Shortlist, compare, compatibility", icon: "person.3.sequence", tint: DesignSystem.Colors.primary) {
            VStack(spacing: 0) {
                NavigationLink {
                    StrategyAlliancePicklistView(store: picklistStore)
                        .environmentObject(teamService)
                        .environmentObject(scoutingService)
                } label: {
                    Phase4LinkRow(title: "Alliance pick list", systemImage: "list.number", tint: DesignSystem.Colors.primary)
                }
                .buttonStyle(.plain)
                
                Phase4RowDivider()
                NavigationLink {
                    StrategyTeamCompareView(seedTeamNumbers: [])
                        .environmentObject(scoutingService)
                } label: {
                    Phase4LinkRow(title: "Compare teams (from your reports)", systemImage: "rectangle.split.3x1", tint: DesignSystem.Colors.primary)
                }
                .buttonStyle(.plain)
                
                Phase4RowDivider()
                NavigationLink {
                    CompatibilityCalculatorView()
                        .environmentObject(teamService)
                } label: {
                    Phase4LinkRow(title: "Alliance compatibility calculator", systemImage: "person.3.sequence", tint: DesignSystem.Colors.primary)
                }
                .buttonStyle(.plain)
                
                if teamService.currentTeam != nil {
                    Phase4RowDivider()
                    NavigationLink {
                        AllianceRecommendationsView(
                            captainTeamNumber: teamService.currentTeam?.number ?? "",
                            eventName: inferredEventName
                        )
                        .environmentObject(teamService)
                    } label: {
                        Phase4LinkRow(title: "Ideas from your reports", systemImage: "sparkles", tint: DesignSystem.Colors.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled((teamService.currentTeam?.number ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // MARK: - Match day
    
    private var matchDayCard: some View {
        Phase4SectionCard(title: "Match day", subtitle: "Fast capture + pit context", icon: "sportscourt", tint: DesignSystem.Colors.accent) {
            VStack(alignment: .leading, spacing: 0) {
                if let match = upcomingMatch {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next on schedule")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.sm)
                        Text("Match \(match.matchNumber) · \(match.scheduledTime.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        let teams = matchLineupTeamStrings(match)
                        if !teams.isEmpty {
                            Text(teams.joined(separator: " · "))
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.bottom, DesignSystem.Spacing.sm)
                        }
                    }
                    Phase4RowDivider()
                }
                
                Button {
                    showQuickScout = true
                } label: {
                    Phase4LinkRow(title: "Quick Scout (fast entry)", systemImage: "bolt.fill", tint: DesignSystem.Colors.accent, trailing: "arrow.up.right.square")
                }
                .buttonStyle(.plain)
                
                Phase4RowDivider()
                NavigationLink {
                    PitScoutingFormView()
                        .environmentObject(teamService)
                } label: {
                    Phase4LinkRow(title: "Pit scouting profile", systemImage: "wrench.and.screwdriver.fill", tint: DesignSystem.Colors.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func matchLineupTeamStrings(_ match: Match) -> [String] {
        [match.redTeam1, match.redTeam2, match.redTeam3, match.blueTeam1, match.blueTeam2, match.blueTeam3]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Learn & calibrate
    
    private var learnAndCalibrateCard: some View {
        Phase4SectionCard(title: "Learn & calibrate", subtitle: "Process over hype", icon: "book.pages", tint: DesignSystem.Colors.secondary) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Prioritize a reliable primary scoring path, then layer extras. Use scouting to find partners whose strengths cover your gaps—not only top averages.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.sm)
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    Link(destination: URL(string: "https://gm0.org/en/latest/docs/design-skills/design-strategy.html")!) {
                        Label("Design strategy (GM0)", systemImage: "link")
                            .font(.caption.weight(.semibold))
                    }
                    Link(destination: URL(string: "https://www.firstinspires.org/robotics/ftc/game-and-season")!) {
                        Label("FIRST game & season", systemImage: "link")
                            .font(.caption.weight(.semibold))
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                Phase4RowDivider()
                NavigationLink {
                    EventExplorerView()
                } label: {
                    Phase4LinkRow(
                        title: "Browse public events (FTC Scout)",
                        systemImage: "globe",
                        tint: DesignSystem.Colors.secondary,
                        trailing: "chevron.right"
                    )
                }
                .buttonStyle(.plain)
                Phase4RowDivider()
                NavigationLink {
                    StatisticsView()
                } label: {
                    Phase4LinkRow(
                        title: "Event OPR calculator (your schedule data)",
                        systemImage: "function",
                        tint: DesignSystem.Colors.secondary,
                        trailing: "chevron.right"
                    )
                }
                .buttonStyle(.plain)
                Text("Local OPR from matches your team saved — not third-party APIs.")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.sm)
            }
        }
    }
    
    private var feedbackCard: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Text("Was this hub useful?")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
            Button("Yes") {
                TelemetryService.shared.logEvent("phase4_intel_hub_feedback", parameters: ["vote": "yes"])
            }
            .buttonStyle(.bordered)
            Button("Not yet") {
                TelemetryService.shared.logEvent("phase4_intel_hub_feedback", parameters: ["vote": "not_yet"])
            }
            .buttonStyle(.bordered)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Section card

private struct Phase4SectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let tint: Color
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.sm)
            
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct Phase4LinkRow: View {
    let title: String
    let systemImage: String
    let tint: Color
    var trailing: String = "chevron.right"
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .foregroundColor(tint)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer(minLength: 8)
            Image(systemName: trailing)
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm + 2)
        .contentShape(Rectangle())
    }
}

struct Phase4RowDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 54)
    }
}
