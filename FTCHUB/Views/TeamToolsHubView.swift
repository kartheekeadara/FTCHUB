//
//  TeamToolsHubView.swift
//  FTCHUB
//
//  Hub for Scouting and Season workspace (replaces a dedicated Scouting-only tab).
//

import SwiftUI

struct TeamToolsHubView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scheduleService: ScheduleService
    @StateObject private var session = SeasonWorkspaceSession()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    NavigationLink {
                            ScoutingView(embedsNavigationStack: false)
                                .environmentObject(scoutingService)
                                .environmentObject(teamService)
                                .environmentObject(scheduleService)
                        } label: {
                            HubNavigationRow(
                                title: "Scouting",
                                subtitle: "Team explorer, templates, and reports",
                                icon: "chart.bar.fill",
                                tint: DesignSystem.Colors.primary
                            )
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink {
                            Group {
                                if teamService.currentTeam != nil {
                                    SeasonEngineeringView(embedsNavigationStack: false)
                                        .environmentObject(session)
                                        .environmentObject(teamService)
                                } else {
                                    TeamAccessRequiredView(
                                        featureName: "Engineering Notebook",
                                        message: "Join or create a team to use the engineering notebook and run log."
                                    )
                                }
                            }
                        } label: {
                            HubNavigationRow(
                                title: "Engineering Notebook",
                                subtitle: "Notebook and run log",
                                icon: "note.text",
                                tint: DesignSystem.Colors.accent
                            )
                        }
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
            .background(DesignSystem.Colors.background)
            .ftchubRootNavHeader(title: "Tools")
            .onAppear { syncSessionToTeam() }
            .onChange(of: teamService.currentTeam?.id) { _, _ in
                syncSessionToTeam()
            }
        }
    }
    
    private func syncSessionToTeam() {
        session.updateTeamContext(teamService.currentTeam?.id)
    }
}
