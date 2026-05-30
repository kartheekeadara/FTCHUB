//
//  PublicDataExplorerHubView.swift
//  FTCHUB
//
//  Teams / Events toggle for public FTC Scout data in the Scouting hub.
//

import SwiftUI

enum PublicExplorerMode: String, CaseIterable {
    case teams = "Teams"
    case events = "Events"
}

struct PublicDataExplorerHubView: View {
    @Binding var scoutingSelectedTab: Int
    @State private var mode: PublicExplorerMode = .teams
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var scheduleService: ScheduleService

    var body: some View {
        VStack(spacing: 0) {
            Picker("Explorer", selection: $mode) {
                ForEach(PublicExplorerMode.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.sm)

            switch mode {
            case .teams:
                TeamExplorerView(isEmbeddedInScoutingHub: true, scoutingSelectedTab: $scoutingSelectedTab)
                    .environmentObject(teamService)
                    .environmentObject(scoutingService)
                    .environmentObject(scheduleService)
            case .events:
                EventExplorerView()
            }
        }
    }
}
