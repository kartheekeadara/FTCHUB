//
//  Phase5GrowthHubView.swift
//  FTCHUB
//
//  Phase 5 — Growth & polish: opt-in network prefs, shareables, digest preferences,
//  deep-link documentation, and lightweight validation hooks (telemetry).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Hub

struct Phase5GrowthHubView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var scheduleService: ScheduleService
    
    @AppStorage("ftchub.phase5.scoutingExchangeOptIn") private var scoutingExchangeOptIn = false
    @AppStorage("ftchub.phase5.challengesOptIn") private var challengesOptIn = false
    @AppStorage("ftchub.phase5.parentDigestPreferred") private var parentDigestPreferred = false
    
    @State private var showingNotificationSettings = false
    
    var body: some View {
        List {
            Section {
                Text("Everything here is off by default. Opt-ins only register your preference on this device; they do not upload data until a future server feature exists and you accept updated terms.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Section("Optional community (future-ready)") {
                Toggle(isOn: $scoutingExchangeOptIn) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scouting exchange interest")
                            .font(.body.weight(.medium))
                        Text("If we ship anonymized aggregate exchange, your team can participate. No raw scout rows leave the device today.")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .onChange(of: scoutingExchangeOptIn) { _, on in
                    if on {
                        TelemetryService.shared.logEvent("phase5_scouting_exchange_opt_in", parameters: ["enabled": "true"])
                    } else {
                        TelemetryService.shared.logEvent("phase5_scouting_exchange_opt_in", parameters: ["enabled": "false"])
                    }
                }
                
                Toggle(isOn: $challengesOptIn) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Inter-team challenges interest")
                            .font(.body.weight(.medium))
                        Text("Lightweight opt-in for future friendly challenges between consenting teams.")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .onChange(of: challengesOptIn) { _, on in
                    TelemetryService.shared.logEvent("phase5_challenges_opt_in", parameters: ["enabled": on ? "true" : "false"])
                }
            }
            
            Section("Shareables") {
                if teamService.currentTeam != nil {
                    NavigationLink {
                        TeamProfileShareView()
                            .environmentObject(teamService)
                    } label: {
                        Label("Team profile text", systemImage: "person.3.sequence")
                    }
                    
                    NavigationLink {
                        MatchRecapGeneratorView()
                            .environmentObject(teamService)
                            .environmentObject(scheduleService)
                    } label: {
                        Label("Match recap (plain text)", systemImage: "text.alignleft")
                    }
                } else {
                    Text("Join a team to build shareable team and match summaries.")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Section("Parent / guardian digest") {
                Toggle("Prefer weekly-style digest copy", isOn: $parentDigestPreferred)
                    .font(.body)
                Text("When notification digests ship, this preference helps tune low-noise wording. It does not schedule anything yet.")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                Button("Notification settings") {
                    showingNotificationSettings = true
                }
            }
            
            Section("Deep links") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Registered URL scheme: ftchub (also used for sign-in callbacks).")
                        .font(.caption)
                    Text("Tab shortcuts (no auth tokens):")
                        .font(.caption.weight(.semibold))
                    Text("ftchub://tab/team · ftchub://tab/finance · ftchub://tab/tools · ftchub://tab/scouting · ftchub://tab/season · ftchub://tab/competition · ftchub://tab/settings")
                        .font(.caption2.monospaced())
                        .textSelection(.enabled)
                }
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Section("Continuous validation") {
                Text("Alliance pick feedback and learning-module feedback log anonymized telemetry when you use those buttons elsewhere in the app.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                NavigationLink {
                    InteractiveLearningView()
                } label: {
                    Label("Open learning modules", systemImage: "graduationcap")
                }
            }
        }
        .navigationTitle("Sharing & community")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            TelemetryService.shared.logEvent("phase5_growth_hub_opened")
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NavigationStack {
                NotificationSettingsView()
                    .environmentObject(NotificationService.shared)
            }
        }
    }
}

// MARK: - Team profile share

struct TeamProfileShareView: View {
    @EnvironmentObject var teamService: TeamService
    @State private var showShare = false
    @State private var shareText = ""
    
    var body: some View {
        List {
            Section {
                Text("Plain text you can paste into email, Slack, or a sponsor one-pager.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            if let team = teamService.currentTeam {
                Section("Preview") {
                    Text(previewText(for: team))
                        .font(.body)
                        .textSelection(.enabled)
                }
                Section {
                    Button("Share…") {
                        shareText = previewText(for: team)
                        showShare = true
                    }
                }
            } else {
                Section {
                    Text("No team loaded.")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .navigationTitle("Team profile")
        #if canImport(UIKit)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [shareText])
        }
        #endif
    }
    
    private func previewText(for team: Team) -> String {
        var lines: [String] = []
        lines.append("FTCHUB — team profile")
        lines.append("\(team.name) (#\(team.number))")
        if let robot = team.robotName, !robot.isEmpty {
            lines.append("Robot: \(robot)")
        }
        if let school = team.school, !school.isEmpty {
            lines.append("School/org: \(school)")
        }
        let loc = team.location
        if !loc.isEmpty {
            lines.append("Location: \(loc)")
        }
        if let web = team.websiteUrl, !web.isEmpty {
            lines.append("Website: \(web)")
        }
        if let bio = team.bio, !bio.isEmpty {
            lines.append("")
            lines.append(bio)
        }
        lines.append("")
        lines.append("Generated in FTCHUB — verify details before sending externally.")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Match recap

struct MatchRecapGeneratorView: View {
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scheduleService: ScheduleService
    @State private var showShare = false
    @State private var shareText = ""
    
    var body: some View {
        List {
            Section {
                Text("Builds a simple recap from your imported schedule and match quick notes. Does not include private scouting forms.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            if scheduleService.matches.isEmpty {
                Section {
                    Text("No matches on file — import a schedule from the Competition tab first.")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            } else {
                Section("Preview") {
                    Text(recapBody())
                        .font(.caption)
                        .textSelection(.enabled)
                }
                Section {
                    Button("Share recap…") {
                        shareText = recapBody()
                        showShare = true
                    }
                }
            }
        }
        .navigationTitle("Match recap")
        #if canImport(UIKit)
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [shareText])
        }
        #endif
    }
    
    private func recapBody() -> String {
        let teamName = teamService.currentTeam?.name ?? "Our team"
        let sorted = scheduleService.matches.sorted { $0.scheduledTime < $1.scheduledTime }
        var lines: [String] = []
        lines.append("FTCHUB — match recap")
        lines.append(teamName)
        if let ev = sorted.compactMap({ $0.eventName }).first(where: { !$0.isEmpty }) {
            lines.append("Event: \(ev)")
        }
        lines.append("Matches: \(sorted.count)")
        lines.append("")
        for m in sorted.prefix(40) {
            let notes = scheduleService.quickNotes(for: m)
            let noteSnippet = notes.map(\.body).joined(separator: " · ")
            let score: String
            if let us = m.ourScore, let them = m.opponentScore {
                score = "\(us)-\(them)"
            } else {
                score = "—"
            }
            let title = m.eventName.map { "\($0) · " } ?? ""
            lines.append("• \(title)\(m.matchNumber) @ \(m.scheduledTime.formatted(date: .abbreviated, time: .shortened)) — \(score)")
            if !noteSnippet.isEmpty {
                lines.append("  Notes: \(noteSnippet)")
            }
        }
        if sorted.count > 40 {
            lines.append("… and \(sorted.count - 40) more (trimmed for message size)")
        }
        lines.append("")
        lines.append("Reminder: recap is for coordination, not official scoring records.")
        return lines.joined(separator: "\n")
    }
}
