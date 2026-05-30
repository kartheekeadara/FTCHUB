//
//  EventDetailView.swift
//  FTCHUB
//
//  Event detail with rankings, matches, and awards from FTC Scout.
//

import SwiftUI

struct EventDetailView: View {
    let season: Int
    let eventCode: String
    let eventName: String

    @StateObject private var eventService = EventExplorerService.shared
    @State private var selectedTab = 0
    @State private var eventSummary: ExternalEventSummary?
    @State private var rankings: [ExternalEventTeamRanking] = []
    @State private var matches: [ExternalEventMatch] = []
    @State private var awards: [ExternalAward] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var rankingSort: ExternalEventRankingSort = .rank

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                if isLoading {
                    ProgressView("Loading event...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(DesignSystem.Colors.error)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    headerSection
                    Picker("Section", selection: $selectedTab) {
                        Text("Rankings").tag(0)
                        Text("Matches").tag(1)
                        Text("Awards").tag(2)
                    }
                    .pickerStyle(.segmented)

                    switch selectedTab {
                    case 0:
                        EventRankingsView(rankings: sortedRankings, season: season)
                    case 1:
                        EventMatchesView(matches: matches, season: season)
                    default:
                        EventAwardsView(awards: awards)
                    }

                    attributionFooter
                }
            }
            .padding(DesignSystem.Spacing.md)
            .padding(.bottom, 80)
        }
        .tabBarScrollInset()
        .navigationTitle(eventSummary?.name ?? eventName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadEvent() }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(eventCode)
                .font(.caption.weight(.bold))
                .foregroundColor(DesignSystem.Colors.primary)
            if let summary = eventSummary {
                if !summary.locationDisplay.isEmpty {
                    Label(summary.locationDisplay, systemImage: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                if let start = summary.startDate {
                    Label("\(start)\(summary.endDate.map { " – \($0)" } ?? "")", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                if let urlString = summary.liveStreamURL, let url = URL(string: urlString) {
                    Link(destination: url) {
                        Label("Watch livestream", systemImage: "play.rectangle.fill")
                            .font(.caption.weight(.semibold))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }

    private var sortedRankings: [ExternalEventTeamRanking] {
        switch rankingSort {
        case .rank:
            return rankings.sorted { ($0.rank ?? Int.max) < ($1.rank ?? Int.max) }
        case .totalNP:
            return rankings.sorted { ($0.totalPointsOPR ?? 0) > ($1.totalPointsOPR ?? 0) }
        case .auto:
            return rankings.sorted { ($0.autoPointsOPR ?? 0) > ($1.autoPointsOPR ?? 0) }
        case .dc:
            return rankings.sorted { ($0.dcPointsOPR ?? 0) > ($1.dcPointsOPR ?? 0) }
        case .rp:
            return rankings.sorted { ($0.rankingPoints ?? 0) > ($1.rankingPoints ?? 0) }
        }
    }

    private var attributionFooter: some View {
        VStack(spacing: 4) {
            Text("Data from FTC Scout")
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.textTertiary)
            Link("ftcscout.org", destination: URL(string: "https://ftcscout.org")!)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.md)
    }

    private func loadEvent() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        eventSummary = try? await eventService.loadEventDetail(season: season, code: eventCode)
        rankings = (try? await eventService.loadEventRankings(season: season, eventCode: eventCode)) ?? []
        matches = (try? await eventService.loadEventMatches(season: season, eventCode: eventCode)) ?? []
        awards = (try? await eventService.loadEventAwards(season: season, eventCode: eventCode)) ?? []

        if eventSummary == nil && rankings.isEmpty && matches.isEmpty {
            errorMessage = "Could not load event data. Please try again."
        }
    }
}

struct EventRankingsView: View {
    let rankings: [ExternalEventTeamRanking]
    let season: Int
    @State private var expandedTeam: Int?
    @State private var sortOption: ExternalEventRankingSort = .rank

    var sortedRankings: [ExternalEventTeamRanking] {
        switch sortOption {
        case .rank:
            return rankings.sorted { ($0.rank ?? Int.max) < ($1.rank ?? Int.max) }
        case .totalNP:
            return rankings.sorted { ($0.totalPointsOPR ?? 0) > ($1.totalPointsOPR ?? 0) }
        case .auto:
            return rankings.sorted { ($0.autoPointsOPR ?? 0) > ($1.autoPointsOPR ?? 0) }
        case .dc:
            return rankings.sorted { ($0.dcPointsOPR ?? 0) > ($1.dcPointsOPR ?? 0) }
        case .rp:
            return rankings.sorted { ($0.rankingPoints ?? 0) > ($1.rankingPoints ?? 0) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Picker("Sort", selection: $sortOption) {
                ForEach(ExternalEventRankingSort.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)

            if sortedRankings.isEmpty {
                Text("No rankings available yet.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                ForEach(sortedRankings) { team in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            NavigationLink {
                                TeamProfileDetailView(teamNumber: String(team.teamNumber))
                            } label: {
                                HStack {
                                    Text("#\(team.rank.map(String.init) ?? "—")")
                                        .font(.caption.weight(.bold))
                                        .frame(width: 36, alignment: .leading)
                                    Text(String(team.teamNumber))
                                        .font(.headline)
                                    Spacer()
                                    if let np = team.totalPointsOPR {
                                        Text(String(format: "%.0f NP", np))
                                            .font(.subheadline.weight(.semibold))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            Button {
                                expandedTeam = expandedTeam == team.teamNumber ? nil : team.teamNumber
                            } label: {
                                Image(systemName: expandedTeam == team.teamNumber ? "chevron.up" : "chevron.down")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                        HStack(spacing: DesignSystem.Spacing.md) {
                            if let rp = team.rankingPoints {
                                Text("RP \(String(format: "%.1f", rp))")
                                    .font(.caption)
                            }
                            Text("W-L-T \(team.wins)-\(team.losses)-\(team.ties)")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        if expandedTeam == team.teamNumber {
                            HStack {
                                statPill("Auto", team.autoPointsOPR)
                                statPill("TeleOp", team.dcPointsOPR)
                                statPill("Avg", team.totalPointsAvg)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
        }
    }

    private func statPill(_ label: String, _ value: Double?) -> some View {
        Text("\(label): \(value.map { String(format: "%.0f", $0) } ?? "—")")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

struct EventMatchesView: View {
    let matches: [ExternalEventMatch]
    let season: Int

    private var grouped: [(String, [ExternalEventMatch])] {
        let dict = Dictionary(grouping: matches) { match in
            let level = match.tournamentLevel?.uppercased() ?? ""
            if level.contains("PLAYOFF") || level.contains("ELIM") { return "Playoffs" }
            return "Qualification"
        }
        return dict.sorted { $0.key < $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            if matches.isEmpty {
                Text("No matches posted yet.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                ForEach(grouped, id: \.0) { group, groupMatches in
                    Text(group)
                        .font(.headline)
                    ForEach(groupMatches) { match in
                        EventMatchRow(match: match)
                    }
                }
            }
        }
    }
}

private struct EventMatchRow: View {
    let match: ExternalEventMatch

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(match.matchNumber)
                .font(.subheadline.weight(.bold))
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Red: \(match.redTeams.map(String.init).joined(separator: ", "))")
                        .font(.caption)
                    Text("Blue: \(match.blueTeams.map(String.init).joined(separator: ", "))")
                        .font(.caption)
                }
                Spacer()
                if let red = match.redScore, let blue = match.blueScore {
                    Text("\(red) – \(blue)")
                        .font(.headline)
                } else {
                    Text("Scheduled")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct EventAwardsView: View {
    let awards: [ExternalAward]

    var body: some View {
        if awards.isEmpty {
            Text("No awards listed.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        } else {
            ForEach(awards) { award in
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading) {
                        Text(award.name)
                            .font(.subheadline.weight(.semibold))
                        if let team = award.teamNumber {
                            Text("Team \(team)")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
    }
}
