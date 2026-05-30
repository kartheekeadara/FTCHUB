//
//  TeamExplorerView.swift
//  FTCHUB
//
//  Phase 2: Team Explorer View
//  Search and browse public teams similar to FTC Scout and The Orange Alliance
//

import SwiftUI
import Combine

struct TeamExplorerView: View {
    var isEmbeddedInScoutingHub: Bool = false
    var scoutingSelectedTab: Binding<Int> = .constant(0)
    
    @StateObject private var explorerService = TeamExplorerService()
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var scheduleService: ScheduleService
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    
    // Debounce search
    private let searchDebouncer = PassthroughSubject<String, Never>()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                ScoutingSearchBar(
                    text: $searchText,
                    placeholder: "Search by team number, name, or location...",
                    isEmbeddedInScoutingHub: isEmbeddedInScoutingHub,
                    onClear: { explorerService.searchResults = [] }
                )
                
                // Search Results or Empty State
                if explorerService.isLoading {
                    loadingStateView
                } else if let error = explorerService.errorMessage {
                    errorView(message: error)
                } else if !explorerService.searchResults.isEmpty {
                    searchResultsSection
                } else if searchText.isEmpty {
                    emptyStateView
                } else {
                    noResultsView
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, 100)
        }
        .tabBarScrollInset()
        .scrollBounceBehavior(.basedOnSize)
        .background(DesignSystem.Colors.background)
        .modifier(TeamExplorerNavigationModifier(isEmbedded: isEmbeddedInScoutingHub))
        .toolbar {
            if !isEmbeddedInScoutingHub {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            explorerService.searchResults = []
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            searchDebouncer.send(newValue)
        }
        .onReceive(searchDebouncer.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)) { query in
            performSearch(query: query)
        }
    }
    
    private struct TeamExplorerNavigationModifier: ViewModifier {
        let isEmbedded: Bool
        
        func body(content: Content) -> some View {
            if isEmbedded {
                content
            } else {
                content
                    .navigationTitle("Team Explorer")
                    .navigationBarTitleDisplayMode(.large)
            }
        }
    }
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Search Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(explorerService.searchResults.count) team\(explorerService.searchResults.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(explorerService.searchResults) { profile in
                    NavigationLink(destination: TeamProfileDetailView(teamNumber: profile.teamNumber)
                        .environmentObject(explorerService)
                        .environmentObject(teamService)) {
                        EnhancedTeamProfileCard(profile: profile)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var loadingStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(DesignSystem.Colors.primary)
            
            Text("Searching teams...")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("Searching FTC Scout database")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Find Teams")
                    .font(.title3.weight(.bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Public directory — not your saved scouting reports")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("Search any FTC team by number, name, or location to view public stats, match history, and event results.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineSpacing(3)
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                ExplorerTipCard(icon: "number", title: "Team number", example: "Try 1829 or 254")
                ExplorerTipCard(icon: "textformat", title: "Team name", example: "Search by school or club name")
                ExplorerTipCard(icon: "location.fill", title: "Location", example: "City, state, or region")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var noResultsView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.tertiaryBackground)
                    .frame(width: 72, height: 72)
                Image(systemName: "person.3.sequence")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Text("No teams found")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Try a team number, name, or location")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding()
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
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
    
    private func performSearch(query: String? = nil) {
        searchTask?.cancel()
        searchTask = Task {
            do {
                try await explorerService.searchTeams(
                    query: query ?? searchText,
                    filters: nil
                )
            } catch {
                // Error handled by service
            }
        }
    }
}

// MARK: - Supporting Views

private struct EnhancedTeamProfileCard: View {
    let profile: PublicTeamProfile
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.primary.opacity(0.12))
                    .frame(width: 56, height: 56)
                Text(profile.teamNumber)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            
            // Team Info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // Team Name - Enhanced typography
                Text(profile.teamName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Location - Enhanced
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(locationText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                // Statistics Preview - Enhanced badges
                if let stats = profile.currentStatistics, stats.matchesPlayed > 0 {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if let avgScore = stats.averageScore {
                            StatBadge(label: "Avg", value: String(format: "%.0f", avgScore), color: .blue)
                        }
                        if let opr = stats.opr ?? stats.averageScore {
                            StatBadge(label: stats.oprRank != nil ? "NP" : "Avg", value: String(format: "%.0f", opr), color: .green)
                        }
                        if let rank = stats.oprRank {
                            StatBadge(label: "Rank", value: "#\(rank)", color: .purple)
                        }
                        if stats.matchesPlayed > 0 {
                            StatBadge(label: "Matches", value: "\(stats.matchesPlayed)", color: .orange)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.borderSubtle.opacity(0.6), lineWidth: 1)
        )
    }
    
    private var locationText: String {
        var parts: [String] = []
        if let city = profile.city, !city.isEmpty {
            parts.append(city)
        }
        if let state = profile.state, !state.isEmpty {
            parts.append(state)
        }
        if parts.isEmpty {
            return profile.country
        }
        return parts.joined(separator: ", ")
    }
}

private struct TeamProfileCard: View {
    let profile: PublicTeamProfile
    
    var body: some View {
        EnhancedTeamProfileCard(profile: profile)
    }
}

// MARK: - Tip Card Component

private struct ExplorerTipCard: View {
    let icon: String
    let title: String
    let example: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DesignSystem.Colors.primary.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(example)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.borderSubtle.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Tip Row Component (legacy)
private struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

private struct StatBadge: View {
    let label: String
    let value: String
    let color: Color?
    
    init(label: String, value: String, color: Color? = nil) {
        self.label = label
        self.value = value
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(color ?? DesignSystem.Colors.textPrimary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.xs)
        .padding(.vertical, 4)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

#Preview {
    NavigationStack {
        TeamExplorerView()
            .environmentObject(TeamService())
    }
}
