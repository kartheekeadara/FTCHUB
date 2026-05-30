//
//  StatisticsView.swift
//  FTCHUB
//
//  Phase 1: Statistics Main View
//  Displays team statistics including OPR, DPR, and CCWM
//

import SwiftUI

struct StatisticsView: View {
    @StateObject private var statisticsService = StatisticsService.shared
    @State private var selectedEventName: String?
    @State private var selectedSeasonYear: Int?
    @State private var showingEventPicker = false
    @State private var searchText = ""
    @State private var selectedMetric: StatisticsService.StatisticMetric = .opr
    
    var filteredStatistics: [StatisticsService.TeamStatistics] {
        var stats = statisticsService.statistics
        
        if !searchText.isEmpty {
            stats = stats.filter { stat in
                stat.teamNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return stats
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Header with filters
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Event and Season Picker
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Button {
                            showingEventPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                Text(selectedEventName ?? "Select Event")
                                    .lineLimit(1)
                            }
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.secondaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                if let eventName = selectedEventName {
                                    try? await statisticsService.calculateStatisticsForEvent(
                                        eventName: eventName,
                                        seasonYear: selectedSeasonYear
                                    )
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(DesignSystem.Spacing.sm)
                                .background(DesignSystem.Colors.secondaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                        .disabled(selectedEventName == nil || statisticsService.isLoading)
                    }
                    
                    // Search Bar
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        TextField("Search team number...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tertiaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    
                    // Metric Selector
                    Picker("Metric", selection: $selectedMetric) {
                        Text("OPR").tag(StatisticsService.StatisticMetric.opr)
                        Text("DPR").tag(StatisticsService.StatisticMetric.dpr)
                        Text("CCWM").tag(StatisticsService.StatisticMetric.ccwm)
                        Text("Win Rate").tag(StatisticsService.StatisticMetric.winRate)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground)
                
                // Content
                if statisticsService.isLoading {
                    ProgressView("Calculating Statistics...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = statisticsService.errorMessage {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredStatistics.isEmpty {
                    ContentUnavailableView {
                        Label("No Statistics", systemImage: "chart.bar")
                    } description: {
                        if selectedEventName == nil {
                            Text("Select an event to view statistics")
                        } else {
                            Text("No statistics found for this event. Calculate statistics to get started.")
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            // Statistics Cards for Top Teams
                            if !filteredStatistics.isEmpty {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                    Text("Top Teams")
                                        .font(.headline)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                        .padding(.horizontal, DesignSystem.Spacing.md)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: DesignSystem.Spacing.md) {
                                            ForEach(Array(filteredStatistics.prefix(5))) { stat in
                                                TeamStatisticsCard(statistics: stat)
                                            }
                                        }
                                        .padding(.horizontal, DesignSystem.Spacing.md)
                                    }
                                }
                                .padding(.vertical, DesignSystem.Spacing.sm)
                            }
                            
                            // Rankings Table
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text("Rankings")
                                    .font(.headline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                
                                RankingsTable(statistics: sortedStatistics)
                            }
                            .padding(.vertical, DesignSystem.Spacing.sm)
                        }
                        .padding(.vertical, DesignSystem.Spacing.md)
                    }
                }
            }
        .navigationTitle("Team Statistics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEventPicker) {
            EventPickerView(
                selectedEventName: $selectedEventName,
                selectedSeasonYear: $selectedSeasonYear
            ) { eventName, seasonYear in
                selectedEventName = eventName
                selectedSeasonYear = seasonYear
                Task {
                    await statisticsService.loadStatistics(
                        eventName: eventName,
                        seasonYear: seasonYear
                    )
                }
            }
        }
    }
    
    private var sortedStatistics: [StatisticsService.TeamStatistics] {
        let sorted = filteredStatistics.sorted { stat1, stat2 in
            switch selectedMetric {
            case .opr:
                return (stat1.opr ?? -Double.infinity) > (stat2.opr ?? -Double.infinity)
            case .dpr:
                return (stat1.dpr ?? -Double.infinity) > (stat2.dpr ?? -Double.infinity)
            case .ccwm:
                return (stat1.ccwm ?? -Double.infinity) > (stat2.ccwm ?? -Double.infinity)
            case .winRate:
                return (stat1.winRate ?? -Double.infinity) > (stat2.winRate ?? -Double.infinity)
            }
        }
        return sorted
    }
}

// MARK: - Team Statistics Card

struct TeamStatisticsCard: View {
    let statistics: StatisticsService.TeamStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Team \(statistics.teamNumber)")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                if let opr = statistics.opr {
                    HStack {
                        Text("OPR:")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text(String(format: "%.1f", opr))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
                
                if let ccwm = statistics.ccwm {
                    HStack {
                        Text("CCWM:")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text(String(format: "%.1f", ccwm))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
                
                if let winRate = statistics.winRate {
                    HStack {
                        Text("Win Rate:")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Spacer()
                        Text(String(format: "%.1f%%", winRate * 100))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.secondaryBackground)
                .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Rankings Table

struct RankingsTable: View {
    let statistics: [StatisticsService.TeamStatistics]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(statistics.enumerated()), id: \.element.id) { index, stat in
                RankingRow(
                    rank: index + 1,
                    statistics: stat
                )
                
                if index < statistics.count - 1 {
                    Divider()
                        .background(DesignSystem.Colors.border)
                }
            }
        }
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

struct RankingRow: View {
    let rank: Int
    let statistics: StatisticsService.TeamStatistics
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 40)
            
            // Team Number
            Text("Team \(statistics.teamNumber)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            // Statistics
            HStack(spacing: DesignSystem.Spacing.lg) {
                if let opr = statistics.opr {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("OPR")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(String(format: "%.1f", opr))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
                
                if let ccwm = statistics.ccwm {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("CCWM")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(String(format: "%.1f", ccwm))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
                
                if let winRate = statistics.winRate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Win %")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(String(format: "%.0f%%", winRate * 100))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
    }
}

// MARK: - Event Picker View

struct EventPickerView: View {
    @Binding var selectedEventName: String?
    @Binding var selectedSeasonYear: Int?
    let onSelect: (String?, Int?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventName: String = ""
    @State private var seasonYear: Int = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Information") {
                    TextField("Event Name", text: $eventName)
                    
                    Picker("Season Year", selection: $seasonYear) {
                        ForEach(Array((2020...2030).reversed()), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                }
            }
            .navigationTitle("Select Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedEventName = eventName.isEmpty ? nil : eventName
                        selectedSeasonYear = seasonYear
                        onSelect(selectedEventName, selectedSeasonYear)
                        dismiss()
                    }
                    .disabled(eventName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    StatisticsView()
}
