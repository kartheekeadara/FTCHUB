//
//  EventExplorerView.swift
//  FTCHUB
//
//  Search and browse FTC events via FTC Scout.
//

import SwiftUI
import Combine

struct EventExplorerView: View {
    @StateObject private var eventService = EventExplorerService.shared
    @State private var searchText = ""
    @State private var selectedSeason = FTCSeasonHelper.currentSeasonYear
    @State private var searchTask: Task<Void, Never>?
    private let searchDebouncer = PassthroughSubject<String, Never>()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                seasonPicker

                ScoutingSearchBar(
                    text: $searchText,
                    placeholder: "Search events by name, code, or region...",
                    isEmbeddedInScoutingHub: true,
                    onClear: { eventService.searchResults = [] }
                )

                if eventService.isLoading {
                    ProgressView("Searching events...")
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else if let error = eventService.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.error)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                } else if !eventService.searchResults.isEmpty {
                    resultsSection
                } else if searchText.isEmpty {
                    emptyState
                } else {
                    Text("No events found")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, 100)
        }
        .tabBarScrollInset()
        .onChange(of: searchText) { _, newValue in
            searchDebouncer.send(newValue)
        }
        .onChange(of: selectedSeason) { _, _ in
            performSearch(query: searchText)
        }
        .onReceive(searchDebouncer.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)) { query in
            performSearch(query: query)
        }
    }

    private var seasonPicker: some View {
        HStack {
            Text("Season")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Picker("Season", selection: $selectedSeason) {
                ForEach(FTCSeasonHelper.recentSeasons(count: 6), id: \.self) { year in
                    Text(FTCSeasonHelper.seasonLabel(for: year)).tag(year)
                }
            }
            .pickerStyle(.menu)
            Spacer()
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("\(eventService.searchResults.count) event\(eventService.searchResults.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)

            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(eventService.searchResults) { event in
                    NavigationLink {
                        EventDetailView(season: event.season, eventCode: event.code, eventName: event.name)
                    } label: {
                        EventSearchResultCard(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Browse Events")
                .font(.title3.weight(.bold))
            Text("Search public FTC events to view rankings, match results, and awards from FTC Scout.")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text("Try \"Massachusetts\", \"USMACMP\", or your state abbreviation.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func performSearch(query: String? = nil) {
        searchTask?.cancel()
        searchTask = Task {
            await eventService.searchEvents(query: query ?? searchText, season: selectedSeason)
        }
    }
}

private struct EventSearchResultCard: View {
    let event: ExternalEventSummary

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(event.code)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
                if !event.locationDisplay.isEmpty {
                    Label(event.locationDisplay, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                if let start = event.startDate {
                    Text(start)
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            Spacer()
            if event.hasMatches {
                Text("Results")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.success.opacity(0.15))
                    .foregroundColor(DesignSystem.Colors.success)
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            }
            Image(systemName: "chevron.right")
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
}
