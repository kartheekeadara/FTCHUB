//
//  ScoutingReportsAnalyticsView.swift
//  FTCHUB
//
//  Phase 1: Detailed scouting reports analytics
//  Moved from ScoutingAnalyticsView to separate concerns
//

import SwiftUI
import Charts

struct ScoutingReportsAnalyticsView: View {
    enum Segment: String, CaseIterable, Identifiable {
        case overview
        case trends
        case insights
        
        var id: String { rawValue }
        var title: String {
            switch self {
            case .overview: return "Overview"
            case .trends: return "Trends"
            case .insights: return "Insights"
            }
        }
    }
    
    @EnvironmentObject var scoutingService: ScoutingService
    
    @State private var segment: Segment = .overview
    @State private var showingOverflowSheet = false
    @State private var showRankingCard = true
    @State private var showStrategyCard = true
    @State private var showingCopyConfirmation = false
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: DesignSystem.Spacing.lg),
        GridItem(.flexible(), spacing: DesignSystem.Spacing.lg)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                header
                
                SegmentPicker(selection: $segment)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                switch segment {
                case .overview:
                    overviewContent
                case .trends:
                    trendsContent
                case .insights:
                    insightsContent
                }
            }
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Report Analytics")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingOverflowSheet) {
            AnalyticsOverflowSheet(showRanking: $showRankingCard, showStrategy: $showStrategyCard)
        }
        .alert("Analytics Exported", isPresented: $showingCopyConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Analytics CSV copied to the clipboard.")
        }
    }
    
    private var header: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 56))
                .foregroundStyle(DesignSystem.Gradients.primary)
                .padding(.top, DesignSystem.Spacing.xl)
                
            Text("Report Analytics")
                .font(.title2.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Monitor report volume, scoring trends, and ranking point progress across your scouting data.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.lg)
        }
    }
    
    private var overviewContent: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            overviewGrid
            
            if !scoutingService.scoutingReports.isEmpty {
                topTeamsCard
                
                if showRankingCard {
                    rankingCard
                }
                
                if showStrategyCard {
                    strategyCard
                }
                
                performanceSummaryCard
            } else {
                EmptyAnalyticsState()
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    private var overviewGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: DesignSystem.Spacing.lg) {
            AnalyticsCard(
                title: "Total Reports",
                value: "\(scoutingService.scoutingReports.count)",
                icon: "doc.text.fill",
                color: DesignSystem.Colors.primary,
                detail: {
                    guard let latest = scoutingService.scoutingReports.first else { return nil }
                    return "Last: \(formattedDate(latest.createdAt))"
                }()
            )
            
            AnalyticsCard(
                title: "Teams Scouted",
                value: "\(scoutingService.uniqueTeamsScoutedCount)",
                icon: "person.3.fill",
                color: DesignSystem.Colors.accent,
                detail: scoutingService.scoutingReports.isEmpty ? nil : "Avg \(formattedAveragePerTeam()) per team"
            )
            
            AnalyticsCard(
                title: "Avg Quality",
                value: formattedAverage(scoutingService.averageOverallQuality),
                icon: "star.circle.fill",
                color: DesignSystem.Colors.success,
                detail: {
                    let alliance = formattedAverage(scoutingService.averageAllianceSelectionRating)
                    return alliance == "—" ? nil : "Alliance: \(alliance)"
                }()
            )
            
            AnalyticsCard(
                title: "Auto Reliability",
                value: formattedAverage(scoutingService.averageAutonomousReliability),
                icon: "brain.head.profile",
                color: DesignSystem.Colors.secondary,
                detail: {
                    let teleop = formattedAverage(scoutingService.averageTeleopClassifiedArtifacts)
                    return teleop == "—" ? nil : "Teleop: \(teleop)"
                }()
            )
        }
    }
    
    private var topTeamsCard: some View {
        let topTeams = scoutingService.getTopTeams(limit: 5)
        
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(DesignSystem.Colors.accent)
                    .font(.system(size: 18, weight: .semibold))
                Text("Most Scouted Teams")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            
            if topTeams.isEmpty {
                Text("No team data yet")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.top, DesignSystem.Spacing.xs)
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(topTeams.enumerated()), id: \.offset) { index, team in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(index < 3 ? DesignSystem.Colors.accent.opacity(0.2) : DesignSystem.Colors.tertiaryBackground)
                                    .frame(width: 32, height: 32)
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(index < 3 ? DesignSystem.Colors.accent : DesignSystem.Colors.textSecondary)
                            }
                            
                            Text("Team \(team.0)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text.fill")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Text("\(team.1)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        
                        if index < topTeams.count - 1 {
                            Divider()
                                .background(DesignSystem.Colors.border.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var performanceSummaryCard: some View {
        let reports = scoutingService.scoutingReports
        let reportsWithQuality = reports.compactMap { report -> (report: ScoutingReport, quality: Double)? in
            guard let quality = report.numericValue(for: "Overall Quality"),
                  quality.isFinite,
                  !quality.isNaN,
                  quality >= 0,
                  quality <= 5 else { return nil }
            return (report, quality)
        }
        
        let highPerformers = reportsWithQuality.filter { $0.quality >= 4.0 }.count
        let mediumPerformers = reportsWithQuality.filter { $0.quality >= 3.0 && $0.quality < 4.0 }.count
        let lowPerformers = reportsWithQuality.filter { $0.quality < 3.0 }.count
        
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(.system(size: 18, weight: .semibold))
                Text("Performance Distribution")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            
            if reportsWithQuality.isEmpty {
                Text("No quality ratings available yet")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.top, DesignSystem.Spacing.xs)
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    performanceRow(label: "High Performers (4.0+)", count: highPerformers, total: reportsWithQuality.count, color: DesignSystem.Colors.success)
                    performanceRow(label: "Medium (3.0-3.9)", count: mediumPerformers, total: reportsWithQuality.count, color: DesignSystem.Colors.warning)
                    performanceRow(label: "Low (<3.0)", count: lowPerformers, total: reportsWithQuality.count, color: DesignSystem.Colors.error)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func performanceRow(label: String, count: Int, total: Int, color: Color) -> some View {
        let percentage = total > 0 ? Double(count) / Double(total) : 0.0
        
        return VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                Text("(\(Int(percentage * 100))%)")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var rankingCard: some View {
        RankingProgressCard(
            movement: scoutingService.movementRPCompletion,
            goal: scoutingService.goalRPCompletion,
            pattern: scoutingService.patternRPCompletion
        )
    }
    
    private var strategyCard: some View {
        StrategyBreakdownCard(items: scoutingService.topStrategyFocuses)
    }
    
    private var trendsContent: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            let trendData = scoutingService.reportsPerDay.map { DailyReportCount(date: $0.date, count: $0.count) }
            if trendData.isEmpty {
                EmptyTrendState(title: "No trend data yet", subtitle: "Log more reports to unlock match flow analytics.")
                    .padding(.horizontal, DesignSystem.Spacing.md)
            } else {
                ReportsTrendCard(data: trendData)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                if trendData.count > 1 {
                    let totalReports = trendData.reduce(0) { $0 + $1.count }
                    let averagePerDay = trendData.count > 0 ? Double(totalReports) / Double(trendData.count) : 0.0
                    let maxDay = trendData.max(by: { $0.count < $1.count })
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(DesignSystem.Colors.secondary)
                                .font(.system(size: 18, weight: .semibold))
                            Text("Activity Summary")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Avg per Day")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Text(averagePerDay.formatted(.number.precision(.fractionLength(1))))
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            
                            if let maxDay = maxDay {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Peak Day")
                                        .font(.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    Text("\(maxDay.count) reports")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(DesignSystem.Colors.success)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            
            TrendMetricCard(
                title: "Ranking Point Progress",
                metrics: [
                    MetricComparison(name: "Movement", value: scoutingService.movementRPCompletion),
                    MetricComparison(name: "Goal", value: scoutingService.goalRPCompletion),
                    MetricComparison(name: "Pattern", value: scoutingService.patternRPCompletion)
                ]
            )
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
    
    private var insightsContent: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if scoutingService.scoutingReports.isEmpty {
                EmptyTrendState(title: "No insights yet", subtitle: "Scout a few matches to unlock breakdowns by starting position, drive base, and strategy focus.")
                    .padding(.horizontal, DesignSystem.Spacing.md)
            } else {
                eventBreakdownCard
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                BreakdownCard(
                    title: "Starting Positions",
                    systemImage: "squares.leading.rectangle",
                    items: scoutingService.startingPositionBreakdown,
                    tint: DesignSystem.Colors.primary
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                BreakdownCard(
                    title: "Drive Base Mix",
                    systemImage: "gearshape.2",
                    items: scoutingService.driveBaseBreakdown,
                    tint: DesignSystem.Colors.accent
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                BreakdownCard(
                    title: "Preload Artifacts",
                    systemImage: "cube.transparent",
                    items: scoutingService.preloadArtifactBreakdown,
                    tint: DesignSystem.Colors.secondary
                )
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }
    
    private var eventBreakdownCard: some View {
        let eventGroups = Dictionary(grouping: scoutingService.scoutingReports) { $0.eventName ?? "Unknown" }
        let eventBreakdown = eventGroups
            .map { (label: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
        
        return BreakdownCard(
            title: "Reports by Event",
            systemImage: "calendar.badge.clock",
            items: eventBreakdown,
            tint: DesignSystem.Colors.primary
        )
    }
    
    private func formattedAverage(_ value: Double?) -> String {
        guard let value, value.isFinite, !value.isNaN else { return "—" }
        return value.formatted(.number.precision(.fractionLength(1)))
    }
    
    private func formattedAveragePerTeam() -> String {
        let total = scoutingService.scoutingReports.count
        guard total > 0 else { return "0.0" }
        let teams = max(scoutingService.uniqueTeamsScoutedCount, 1)
        let avg = Double(total) / Double(teams)
        guard avg.isFinite, !avg.isNaN else { return "0.0" }
        return avg.formatted(.number.precision(.fractionLength(1)))
    }
}

// MARK: - Supporting Views (moved from ScoutingAnalyticsView)

private struct SegmentPicker: View {
    @Binding var selection: ScoutingReportsAnalyticsView.Segment
    
    var body: some View {
        Picker("Analytics Segment", selection: $selection) {
            ForEach(ScoutingReportsAnalyticsView.Segment.allCases) { segment in
                Text(segment.title).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let detail: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let detail = detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct ReportsTrendCard: View {
    let data: [DailyReportCount]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Reports Logged")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Chart(data) { item in
                LineMark(
                    x: .value("Day", item.date),
                    y: .value("Reports", item.count)
                )
                .lineStyle(.init(lineWidth: 3))
                .foregroundStyle(DesignSystem.Colors.primary)
                
                AreaMark(
                    x: .value("Day", item.date),
                    y: .value("Reports", item.count)
                )
                .foregroundStyle(DesignSystem.Colors.primary.opacity(0.2))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                }
            }
            .frame(height: 180)
            
            if let latest = data.last?.count, let first = data.first?.count, data.count > 1 {
                let delta = latest - first
                let deltaText = delta >= 0 ? "+\(delta)" : "\(delta)"
                Text("Change since first logged day: \(deltaText)")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct TrendMetricCard: View {
    let title: String
    let metrics: [MetricComparison]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(title)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(metrics) { metric in
                HStack {
                    Text(metric.name)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Text(metric.formattedValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                ProgressView(value: metric.value)
                    .tint(DesignSystem.Colors.primary)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct EmptyTrendState: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "sparkle")
                .font(.system(size: 44))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text(title)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct BreakdownCard: View {
    let title: String
    let systemImage: String
    let items: [(label: String, count: Int)]
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            
            if items.isEmpty {
                Text("No data yet")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                ForEach(items, id: \.label) { item in
                    HStack {
                        Text(item.label)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        Spacer()
                        Capsule()
                            .fill(tint.opacity(0.15))
                            .frame(width: 160, height: 8)
                            .overlay(
                                Capsule()
                                    .fill(tint)
                                    .frame(width: max(24, CGFloat(item.count) * 16), height: 8)
                            )
                        Text("\(item.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(tint)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct MetricComparison: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    
    var formattedValue: String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }
}

private struct DailyReportCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

private struct AnalyticsOverflowSheet: View {
    @Binding var showRanking: Bool
    @Binding var showStrategy: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Show Ranking Progress", isOn: $showRanking)
                    Toggle("Show Strategy Breakdown", isOn: $showStrategy)
                }
                Section("Tips") {
                    Label("Explore reports to unlock additional analytics.", systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background)
            .navigationTitle("Analytics Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        DesignSystem.Haptics.selection()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct RankingProgressCard: View {
    let movement: Double
    let goal: Double
    let pattern: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(.system(size: 18, weight: .semibold))
                Text("Ranking Point Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                progressRow(title: "Movement RP", value: movement, icon: "figure.walk", color: DesignSystem.Colors.primary)
                progressRow(title: "Goal RP", value: goal, icon: "target", color: DesignSystem.Colors.accent)
                progressRow(title: "Pattern RP", value: pattern, icon: "square.grid.2x2", color: DesignSystem.Colors.secondary)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func progressRow(title: String, value: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                Spacer()
                Text(value.formatted(.percent.precision(.fractionLength(0))))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.tertiaryBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(min(max(value, 0), 1)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

private struct StrategyBreakdownCard: View {
    let items: [(label: String, count: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(DesignSystem.Colors.accent)
                    .font(.system(size: 18, weight: .semibold))
                Text("Top Strategy Focus")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            if items.isEmpty {
                Text("Log more scouting reports to unlock strategy insights.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.top, DesignSystem.Spacing.xs)
            } else {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(items, id: \.label) { item in
                        HStack {
                            Text(item.label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Spacer()
                            Text("\(item.count)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(DesignSystem.Colors.accent)
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        if item.label != items.last?.label {
                            Divider()
                                .background(DesignSystem.Colors.border.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct EmptyAnalyticsState: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Text("No scouting reports yet")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("Capture your first report to unlock trend insights, ranking point progress, and strategy breakdowns.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        ScoutingReportsAnalyticsView()
            .environmentObject(ScoutingService())
    }
}
