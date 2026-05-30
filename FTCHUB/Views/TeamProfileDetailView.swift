//
//  TeamProfileDetailView.swift
//  FTCHUB
//
//  Phase 2: Team Profile Detail View
//  Comprehensive team profile with statistics, match history, and pit scouting
//

import SwiftUI
import SafariServices

struct TeamProfileDetailView: View {
    let teamNumber: String
    @EnvironmentObject var explorerService: TeamExplorerService
    @EnvironmentObject var teamService: TeamService
    @State private var matchHistoryFilter: MatchHistoryFilter = .all
    @State private var profile: PublicTeamProfile?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingWebsite = false
    
    // Season filter - dynamic based on available seasons
    @State private var selectedSeasonYear: Int?
    @State private var quickStats: FTCScoutQuickStats?
    
    enum MatchHistoryFilter: String, CaseIterable {
        case all = "All"
        case wins = "Wins"
        case losses = "Losses"
    }
    
    var filteredMatches: [PublicMatch] {
        guard let profile = profile else { return [] }
        var matches = profile.recentMatches
        
        // Filter by selected season year if one is selected
        if let selectedYear = selectedSeasonYear {
            matches = matches.filter { match in
                // Extract year from match's scheduled time or use seasonYear if available
                let matchYear = match.seasonYear ?? Calendar.current.component(.year, from: match.scheduledTime)
                return matchYear == selectedYear
            }
        }
        
        switch matchHistoryFilter {
        case .all:
            break
        case .wins:
            matches = matches.filter { $0.didWin == true }
        case .losses:
            matches = matches.filter { $0.didWin == false }
        }
        
        return matches
    }
    
    var availableSeasons: [Int] {
        guard let profile = profile else { return [] }
        let seasons = Set(profile.allStatistics.compactMap { $0.seasonYear })
        return Array(seasons).sorted(by: >) // Most recent first
    }
    
    var currentStats: StatisticsService.TeamStatistics? {
        guard let profile = profile else { return nil }
        
        if let selectedYear = selectedSeasonYear {
            return profile.allStatistics.first { $0.seasonYear == selectedYear }
        } else {
            // Default to most recent season
            return availableSeasons.first.flatMap { year in
                profile.allStatistics.first { $0.seasonYear == year }
            } ?? profile.currentStatistics
        }
    }
    
    // Helper function to get season name
    private func seasonName(for year: Int) -> String {
        switch year {
        case 2025: return "Decode"
        case 2024: return "Into the Deep"
        case 2023: return "Centerstage"
        case 2022: return "Power Play"
        case 2021: return "Freight Frenzy"
        case 2020: return "Ultimate Goal"
        case 2019: return "Skystone"
        case 2018: return "Rover Ruckus"
        case 2017: return "Relic Recovery"
        case 2016: return "Velocity Vortex"
        case 2015: return "Res-Q"
        default: return "Season \(year)"
        }
    }
    
    private func seasonDisplayName(for year: Int) -> String {
        return "\(year): \(seasonName(for: year))"
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    DesignSystem.Colors.background,
                    DesignSystem.Colors.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                if isLoading {
                    ProgressView("Loading team profile...")
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let profile = profile {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Hero Header Section with gradient
                        headerSection(profile: profile)
                        
                        statisticsSection(profile: profile)
                        
                        matchHistorySection(profile: profile)
                        
                        if !profile.eventParticipations.isEmpty {
                            eventsSection(profile: profile)
                        }
                        
                        if !profile.awards.isEmpty {
                            awardsSection(profile: profile)
                        }
                        
                        attributionSection(profile: profile)
                        
                        if !profile.pitScoutingProfiles.isEmpty {
                            pitScoutingSection(profile: profile)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .tabBarScrollInset()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTeamProfile()
        }
        .onChange(of: selectedSeasonYear) { _, _ in
            updateQuickStatsFromProfile()
        }
        .sheet(isPresented: $showingWebsite) {
            if let urlString = profile?.websiteUrl, let url = URL(string: urlString) {
                TeamSafariView(url: url)
            }
        }
    }
    
    private func headerSection(profile: PublicTeamProfile) -> some View {
        VStack(spacing: 0) {
            // Hero section
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Team number - no background
                Text(profile.teamNumber)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.top, DesignSystem.Spacing.lg)
                
                // Team Name
                Text(profile.teamName)
                    .font(.system(size: 26, weight: .bold, design: .default))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                
                // Location and Robot Name in horizontal layout
                HStack(spacing: DesignSystem.Spacing.md) {
                        // Location badge
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Text(profileLocation(profile: profile))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(DesignSystem.Colors.primary.opacity(0.1))
                        )
                        
                        // Robot Name badge
                        if let robotName = profile.robotName, !robotName.isEmpty {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.accent)
                                
                                Text(robotName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(DesignSystem.Colors.accent.opacity(0.15))
                            )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Website Link
                    if let websiteUrl = profile.websiteUrl, !websiteUrl.isEmpty {
                        Button(action: {
                            showingWebsite = true
                        }) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "safari.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Visit Website")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.xl)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(DesignSystem.Gradients.primary)
                            .cornerRadius(DesignSystem.CornerRadius.lg)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, DesignSystem.Spacing.xs)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.xl)
            
            // Bio section (if available) - separate card below hero
            if let bio = profile.bio, !bio.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primary.opacity(0.6))
                        
                        Text("About")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Text(bio)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineSpacing(6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 2)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, DesignSystem.Spacing.md)
            }
        }
    }
    
    private func statisticsSection(profile: PublicTeamProfile) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Section Header with icon
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Text("Statistics")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // Season Picker
                if !availableSeasons.isEmpty {
                    Picker("Select Season", selection: $selectedSeasonYear) {
                        ForEach(availableSeasons, id: \.self) { year in
                            Text(seasonDisplayName(for: year)).tag(year as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DesignSystem.Colors.primary)
                }
            }
            
            // Unified quick stats (season summary + OPR table)
            if let stats = currentStats, stats.matchesPlayed > 0 || stats.averageScore != nil {
                if let quickStats = quickStats {
                    QuickStatsTable(quickStats: quickStats, seasonStats: stats)
                } else {
                    QuickStatsTable(quickStats: nil, seasonStats: stats)
                }

                if stats.calculationMethod == "orange_alliance_api" {
                    Text("Classic OPR via Orange Alliance")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding(.top, DesignSystem.Spacing.xs)
                }
            } else if let quickStats = quickStats {
                QuickStatsTable(quickStats: quickStats, seasonStats: nil)
            } else {
                Text("No public match data for this season yet.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, DesignSystem.Spacing.sm)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.12), lineWidth: 1)
        )
    }
    
    private func matchHistorySection(profile: PublicTeamProfile) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Section Header with icon
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                Text("Match History")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // Filter Picker
                Picker("Filter", selection: $matchHistoryFilter) {
                    ForEach(MatchHistoryFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(DesignSystem.Colors.primary)
            }
            
            if filteredMatches.isEmpty {
                ContentUnavailableView {
                    Label("No Matches Found", systemImage: "calendar")
                } description: {
                    Text("No matches match the selected filter criteria.")
                }
                .frame(height: 150)
            } else {
                // Group matches by tournament level
                let playoffMatches = filteredMatches.filter { match in
                    match.matchNumber.hasPrefix("M") || match.matchNumber.hasPrefix("P")
                }
                let qualMatches = filteredMatches.filter { match in
                    match.matchNumber.hasPrefix("Q") || (!match.matchNumber.hasPrefix("M") && !match.matchNumber.hasPrefix("P"))
                }
                
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Playoff Matches Section
                    if !playoffMatches.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.yellow)
                                
                                Text("Playoffs")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            
                            ForEach(playoffMatches.prefix(20)) { match in
                                EnhancedMatchHistoryRow(match: match, teamNumber: teamNumber)
                            }
                        }
                    }
                    
                    // Qualification Matches Section
                    if !qualMatches.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                
                                Text("Qualification Matches")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            
                            ForEach(qualMatches.prefix(20)) { match in
                                EnhancedMatchHistoryRow(match: match, teamNumber: teamNumber)
                            }
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.12), lineWidth: 1)
        )
    }
    
    private func eventsSection(profile: PublicTeamProfile) -> some View {
        let seasonEvents = profile.eventParticipations.filter { event in
            guard let selected = selectedSeasonYear else { return true }
            return event.season == selected
        }
        
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "flag.checkered")
                    .foregroundColor(DesignSystem.Colors.primary)
                Text("Events")
                    .font(.system(size: 22, weight: .bold))
            }
            
            if seasonEvents.isEmpty {
                Text("No events for selected season.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                ForEach(seasonEvents) { event in
                    NavigationLink {
                        EventDetailView(season: event.season, eventCode: event.eventCode, eventName: event.eventName ?? event.eventCode)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.eventName ?? event.eventCode)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Text("Rank #\(event.rank.map(String.init) ?? "—") · W-L-T \(event.wins)-\(event.losses)-\(event.ties)")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            Spacer()
                            if let np = event.totalPointsOPR {
                                Text(String(format: "%.0f NP", np))
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.12), lineWidth: 1)
        )
    }
    
    private func awardsSection(profile: PublicTeamProfile) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("Awards")
                    .font(.system(size: 22, weight: .bold))
            }
            ForEach(profile.awards) { award in
                HStack {
                    Text(award.name)
                        .font(.subheadline)
                    Spacer()
                    if let code = award.eventCode {
                        Text(code)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.12), lineWidth: 1)
        )
    }
    
    private func attributionSection(profile: PublicTeamProfile) -> some View {
        VStack(spacing: 4) {
            Text("Public data from FTC Scout\(profile.allStatistics.contains(where: { $0.calculationMethod == "orange_alliance_api" }) ? " · OPR fallback via Orange Alliance" : "")")
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.center)
            HStack(spacing: DesignSystem.Spacing.md) {
                Link("ftcscout.org", destination: URL(string: "https://ftcscout.org")!)
                Link("theorangealliance.org", destination: URL(string: "https://theorangealliance.org")!)
            }
            .font(.caption2)
            if let fetched = profile.lastFetchedAt {
                Text("Updated \(fetched.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func pitScoutingSection(profile: PublicTeamProfile) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // Section Header with icon
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.accent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.accent)
                }
                
                Text("Pit Scouting")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            if let currentProfile = profile.pitScoutingProfiles.first {
                NavigationLink(destination: RobotProfileView(profile: currentProfile)) {
                    PitScoutingPreviewCard(profile: currentProfile)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.xl)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 12, x: 0, y: 4)
    }
    
    private func profileLocation(profile: PublicTeamProfile) -> String {
        var parts: [String] = []
        if let city = profile.city { parts.append(city) }
        if let state = profile.state { parts.append(state) }
        if profile.country != "USA" { parts.append(profile.country) }
        return parts.isEmpty ? profile.country : parts.joined(separator: ", ")
    }
    
    private func formatMatchNumber(_ matchNumber: String) -> String {
        // Format match number like "M-3" or "Q-6" based on the number
        // If it starts with M or Q, keep it as is, otherwise format based on tournament level
        if matchNumber.hasPrefix("M") || matchNumber.hasPrefix("Q") || matchNumber.hasPrefix("P") {
            // Already formatted
            if matchNumber.contains("-") {
                return matchNumber
            } else {
                // Add dash: "M3" -> "M-3"
                let prefix = String(matchNumber.prefix(1))
                let number = String(matchNumber.dropFirst())
                return "\(prefix)-\(number)"
            }
        }
        // Default: just return the number
        return matchNumber
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.error)
            
            Text("Error")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .padding()
    }
    
    private func updateQuickStatsFromProfile() {
        guard let profile, let season = selectedSeasonYear ?? availableSeasons.first else {
            quickStats = nil
            return
        }
        quickStats = profile.quickStats(for: season)
    }
    
    private func loadTeamProfile() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let loadedProfile = try await explorerService.getTeamProfile(teamNumber: teamNumber)
            profile = loadedProfile
            // Set default selected season to the first available season
            if selectedSeasonYear == nil {
                let seasons = Set(loadedProfile.allStatistics.compactMap { $0.seasonYear })
                let sortedSeasons = Array(seasons).sorted(by: >)
                if let firstSeason = sortedSeasons.first {
                    selectedSeasonYear = firstSeason
                }
            }
            updateQuickStatsFromProfile()
        } catch {
            errorMessage = "Failed to load team profile: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views

private struct ProfileMetricTile: View {
    let title: String
    let value: String
    let subtitle: String?
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(tint.opacity(0.08))
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - Varied Stat Card Styles

private struct GradientStatCard: View {
    let title: String
    let value: String
    let rank: Int?
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Gradient background
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(gradient)
                .frame(height: 140)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Spacer()
                    
                    if let rank = rank {
                        Text("#\(rank)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.25))
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                    }
                }
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(DesignSystem.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

private struct CompactStatCard: View {
    let title: String
    let value: String
    let rank: Int?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if let rank = rank {
                    Text("#\(rank)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color)
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                }
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

private struct TeamStatCard: View {
    let title: String
    let value: String
    let rank: Int?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
            Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            }
            
            // Value - Enhanced typography
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Title
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // Rank badge - Enhanced
            if let rank = rank {
                Text("#\(rank)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(color)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.5), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1.5)
        )
    }
}

private struct RecordBadge: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(
            LinearGradient(
                colors: [color.opacity(0.15), color.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(color.opacity(0.3), lineWidth: 1.5)
        )
    }
}

private struct QuickStatBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.sm)
        .background(color.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

private struct QuickStatsTable: View {
    let quickStats: FTCScoutQuickStats?
    let seasonStats: StatisticsService.TeamStatistics?
    
    // Calculate percentile from rank
    private func percentile(rank: Int?, total: Int) -> Double? {
        guard let rank = rank, total > 0 else { return nil }
        return ((Double(total) - Double(rank)) / Double(total)) * 100.0
    }
    
    // Format rank with ordinal suffix
    private func formatRank(_ rank: Int?) -> String {
        guard let rank = rank else { return "—" }
        let suffix: String
        switch rank % 10 {
        case 1 where rank % 100 != 11: suffix = "st"
        case 2 where rank % 100 != 12: suffix = "nd"
        case 3 where rank % 100 != 13: suffix = "rd"
        default: suffix = "th"
        }
        return "\(rank)\(suffix)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Quick Stats")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            if let seasonStats {
                seasonSummaryGrid(stats: seasonStats)
            }
            
            if let quickStats {
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Table Header
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 100, alignment: .leading)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Total NP")
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Auto")
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Teleop")
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Endgame")
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Season average row
                HStack(spacing: 0) {
                    Text(seasonStats?.calculationMethod == "orange_alliance_api" ? "Season OPR" : "Season Avg")
                        .frame(width: 100, alignment: .leading)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    statCell(quickStats.tot.value)
                    statCell(quickStats.auto.value)
                    statCell(quickStats.dc.value)
                    statCell(quickStats.eg.value)
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Rank / Percentile Row
                HStack(spacing: 0) {
                    Text("Rank / Percentile")
                        .frame(width: 100, alignment: .leading)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    rankCell(rank: quickStats.tot.rank, total: quickStats.count)
                    rankCell(rank: quickStats.auto.rank, total: quickStats.count)
                    rankCell(rank: quickStats.dc.rank, total: quickStats.count)
                    rankCell(rank: quickStats.eg.rank, total: quickStats.count)
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
        }
    }
    
    @ViewBuilder
    private func seasonSummaryGrid(stats: StatisticsService.TeamStatistics) -> some View {
        let parts = summaryParts(stats: stats)
        if !parts.isEmpty {
            Text(parts.joined(separator: "  ·  "))
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }
    
    private func summaryParts(stats: StatisticsService.TeamStatistics) -> [String] {
        var parts: [String] = []
        if let winRate = stats.winRate {
            parts.append("\(winRate.formatted(.percent.precision(.fractionLength(0)))) win rate")
        }
        if stats.wins > 0 || stats.losses > 0 || stats.ties > 0 {
            parts.append("\(stats.wins)-\(stats.losses)-\(stats.ties) record")
        }
        if stats.matchesPlayed > 0 {
            parts.append("\(stats.matchesPlayed) matches")
        }
        if stats.averageAutoScore != nil || stats.averageTeleopScore != nil {
            let auto = stats.averageAutoScore.map { String(format: "%.0f", $0) } ?? "—"
            let tele = stats.averageTeleopScore.map { String(format: "%.0f", $0) } ?? "—"
            parts.append("Auto/Tele \(auto)/\(tele)")
        }
        if stats.calculationMethod == "orange_alliance_api" {
            if let dpr = stats.dpr {
                parts.append("DPR \(dpr.formatted(.number.precision(.fractionLength(1))))")
            }
            if let ccwm = stats.ccwm {
                parts.append("CCWM \(ccwm.formatted(.number.precision(.fractionLength(1))))")
            }
        }
        return parts
    }
    
    @ViewBuilder
    private func statCell(_ value: Double?) -> some View {
        if let value {
            Text(String(format: "%.2f", value))
                .frame(maxWidth: .infinity)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        } else {
            Text("—")
                .frame(maxWidth: .infinity)
                .font(.system(size: 13))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
    
    @ViewBuilder
    private func rankCell(rank: Int?, total: Int) -> some View {
        if let rank, let pct = percentile(rank: rank, total: total) {
            Text("\(formatRank(rank)) / \(String(format: "%.2f", pct))%")
                .frame(maxWidth: .infinity)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        } else {
            Text("—")
                .frame(maxWidth: .infinity)
                .font(.system(size: 13))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

private struct MatchHistoryRow: View {
    let match: PublicMatch
    let teamNumber: String
    
    var body: some View {
        EnhancedMatchHistoryRow(match: match, teamNumber: teamNumber)
    }
}

private struct EnhancedMatchHistoryRow: View {
    let match: PublicMatch
    let teamNumber: String
    
    private var badgeParts: (prefix: String, number: String) {
        MatchDisplayFormatter.badgeParts(from: match.matchNumber)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                VStack(spacing: 2) {
                    Text(badgeParts.prefix)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                    Text(badgeParts.number)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(DesignSystem.Colors.primary)
                .cornerRadius(DesignSystem.CornerRadius.md)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(match.eventName ?? "Match \(match.matchNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(match.scheduledTime, style: .date)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(match.allianceColor == .red ? Color.red : Color.blue)
                            .frame(width: 8, height: 8)
                        Text(match.allianceColor == .red ? "Red Alliance" : "Blue Alliance")
                            .font(.caption.weight(.medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer(minLength: 8)
                
                if let redScore = match.redAllianceScore, let blueScore = match.blueAllianceScore {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(redScore) – \(blueScore)")
                            .font(.headline.weight(.bold))
                        if let didWin = match.didWin {
                            Text(didWin ? "WIN" : "LOSS")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(didWin ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                    }
                }
            }
            
            if !match.redTeams.isEmpty || !match.blueTeams.isEmpty {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                    allianceTeamList(title: "Red", teams: match.redTeams, tint: .red)
                    allianceTeamList(title: "Blue", teams: match.blueTeams, tint: .blue)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    private func allianceTeamList(title: String, teams: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title) Alliance")
                .font(.caption2.weight(.semibold))
                .foregroundColor(tint)
            ForEach(teams, id: \.self) { teamNum in
                HStack(spacing: 4) {
                    if teamNum == teamNumber {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(tint)
                    }
                    Text(teamNum)
                        .font(.caption)
                        .foregroundColor(teamNum == teamNumber ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(tint.opacity(0.08))
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

private struct PitScoutingPreviewCard: View {
    let profile: PitScoutingService.RobotProfile
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.accent.opacity(0.2),
                                DesignSystem.Colors.accent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.accent)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Robot Profile")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("View full robot specifications and capabilities")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.accent.opacity(0.08),
                    DesignSystem.Colors.accent.opacity(0.03)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.accent.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - Safari View Wrapper

private struct TeamSafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    NavigationStack {
        TeamProfileDetailView(teamNumber: "12345")
            .environmentObject(TeamService())
    }
}
