//
//  AdvancedAnalyticsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI
import Charts

struct AdvancedAnalyticsView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @StateObject private var analyticsService = AnalyticsService.shared
    @State private var selectedTimeRange: TimeRange = .season
    @State private var selectedMetric: AnalyticsMetric = .matchPerformance
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Key Metrics Overview
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Win Rate",
                            value: "\(Int(analyticsService.winRate * 100))%",
                            subtitle: "Last \(selectedTimeRange.displayCount) matches",
                            icon: "trophy.fill",
                            color: .green,
                            trend: .up(5.2)
                        )
                        
                        StatCard(
                            title: "Avg Score",
                            value: String(format: "%.0f", analyticsService.averageScore),
                            subtitle: "Points per match",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .blue,
                            trend: .up(8.5)
                        )
                        
                        StatCard(
                            title: "Total Matches",
                            value: "\(analyticsService.totalMatches)",
                            subtitle: "Played this season",
                            icon: "sportscourt.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Rank",
                            value: "#\(analyticsService.currentRank)",
                            subtitle: "Of \(analyticsService.totalTeams) teams",
                            icon: "star.fill",
                            color: .purple,
                            trend: .up(3)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Match Performance Chart
                    ChartCard(title: "Match Performance", subtitle: "Score trends over time") {
                        if analyticsService.matchHistory.isEmpty {
                            EmptyChartPlaceholder(message: "No match data available")
                        } else {
                            Chart(analyticsService.matchHistory) { match in
                                LineMark(
                                    x: .value("Match", match.matchNumber),
                                    y: .value("Score", match.score)
                                )
                                .foregroundStyle(.blue)
                                .interpolationMethod(.catmullRom)
                                
                                PointMark(
                                    x: .value("Match", match.matchNumber),
                                    y: .value("Score", match.score)
                                )
                                .foregroundStyle(.blue)
                            }
                            .frame(height: 200)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Performance Breakdown
                    ChartCard(title: "Performance Breakdown", subtitle: "Key metrics") {
                        VStack(spacing: 12) {
                            PercentageBar(
                                label: "Auto Success Rate",
                                percentage: analyticsService.autoSuccessRate * 100,
                                color: .green
                            )
                            
                            PercentageBar(
                                label: "TeleOp Efficiency",
                                percentage: analyticsService.teleopEfficiency * 100,
                                color: .blue
                            )
                            
                            PercentageBar(
                                label: "Endgame Success",
                                percentage: analyticsService.endgameSuccess * 100,
                                color: .purple
                            )
                            
                            PercentageBar(
                                label: "Defense Rating",
                                percentage: analyticsService.defenseRating * 100,
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Scoring Distribution
                    ChartCard(title: "Scoring Distribution", subtitle: "Points by phase") {
                        if analyticsService.scoringBreakdown.isEmpty {
                            EmptyChartPlaceholder(message: "No scoring data available")
                        } else {
                            Chart(analyticsService.scoringBreakdown, id: \.phase) { item in
                                SectorMark(
                                    angle: .value("Score", item.points),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Phase", item.phase))
                                .cornerRadius(5)
                            }
                            .frame(height: 200)
                            .chartLegend(position: .bottom, alignment: .center, spacing: 12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Team Comparison
                    ChartCard(title: "Team Comparison", subtitle: "vs. Top 5 teams") {
                        if analyticsService.teamComparison.isEmpty {
                            EmptyChartPlaceholder(message: "No comparison data available")
                        } else {
                            Chart {
                                ForEach(analyticsService.teamComparison) { team in
                                    BarMark(
                                        x: .value("Team", team.teamNumber),
                                        y: .value("Avg Score", team.averageScore)
                                    )
                                    .foregroundStyle(team.isOurTeam ? Color.blue : Color.gray.opacity(0.5))
                                    .cornerRadius(4)
                                }
                            }
                            .frame(height: 200)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Strengths & Weaknesses
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Strengths", systemImage: "hand.thumbsup.fill")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            ForEach(analyticsService.strengths, id: \.self) { strength in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(strength)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Areas to Improve", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.orange)
                            
                            ForEach(analyticsService.weaknesses, id: \.self) { weakness in
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                    Text(weakness)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Detailed Metrics
                    ChartCard(title: "Detailed Metrics", subtitle: "Performance indicators") {
                        VStack(spacing: 8) {
                            MetricRow(label: "Consistency Score", value: String(format: "%.1f/10", analyticsService.consistencyScore), icon: "chart.line.flattrend.xyaxis", color: .blue)
                            Divider()
                            MetricRow(label: "Recovery Time", value: "\(analyticsService.averageRecoveryTime)s", icon: "clock.fill", color: .orange)
                            Divider()
                            MetricRow(label: "Alliance Contribution", value: "\(Int(analyticsService.allianceContribution * 100))%", icon: "person.3.fill", color: .purple)
                            Divider()
                            MetricRow(label: "Penalty Rate", value: String(format: "%.2f/match", analyticsService.penaltyRate), icon: "exclamationmark.triangle.fill", color: .red)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Export Options
                    VStack(spacing: 12) {
                        Button(action: {
                            analyticsService.exportAnalytics()
                        }) {
                            Label("Export Analytics Report", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {
                            analyticsService.shareInsights()
                        }) {
                            Label("Share Key Insights", systemImage: "square.and.arrow.up.on.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Metric", selection: $selectedMetric) {
                            ForEach(AnalyticsMetric.allCases) { metric in
                                Label(metric.rawValue, systemImage: metric.icon).tag(metric)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            Task {
                                await analyticsService.refreshData()
                            }
                        }) {
                            Label("Refresh Data", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types
enum TimeRange: String, CaseIterable, Identifiable {
    case lastWeek = "Week"
    case lastMonth = "Month"
    case season = "Season"
    case allTime = "All Time"
    
    var id: String { rawValue }
    
    var displayCount: String {
        switch self {
        case .lastWeek: return "7"
        case .lastMonth: return "30"
        case .season: return "season's"
        case .allTime: return "all"
        }
    }
}

enum AnalyticsMetric: String, CaseIterable, Identifiable {
    case matchPerformance = "Match Performance"
    case scoringTrends = "Scoring Trends"
    case efficiency = "Efficiency"
    case reliability = "Reliability"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .matchPerformance: return "chart.bar.fill"
        case .scoringTrends: return "chart.line.uptrend.xyaxis"
        case .efficiency: return "speedometer"
        case .reliability: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Empty Chart Placeholder
struct EmptyChartPlaceholder: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AdvancedAnalyticsView()
        .environmentObject(ScoutingService())
}

