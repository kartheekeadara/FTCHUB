//
//  AllianceSelectionView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct AllianceSelectionView: View {
    @StateObject private var allianceService = AllianceSelectionService.shared
    @State private var selectedStrategy: SelectionStrategy = .balanced
    @State private var showingStrategyPicker = false
    @State private var selectedTeam: TeamRankingInfo?
    @State private var selectedAlliance: AlliancePreview?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Strategy Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selection Strategy")
                            .font(.headline)
                        
                        Button(action: { showingStrategyPicker = true }) {
                            HStack {
                                Image(systemName: selectedStrategy.icon)
                                    .foregroundColor(selectedStrategy.color)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedStrategy.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(selectedStrategy.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    // Top Picks
                    ChartCard(title: "Recommended Teams", subtitle: "Based on \(selectedStrategy.rawValue) strategy") {
                        if allianceService.isLoading {
                            ProgressView()
                                .frame(height: 100)
                        } else if allianceService.rankedTeams.isEmpty {
                            EmptyAllianceStateView(
                                icon: "person.3.fill",
                                message: "No team data available",
                                description: "Scout teams to get recommendations"
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(allianceService.rankedTeams.prefix(5).enumerated()), id: \.element.id) { index, team in
                                    TeamRankCard(
                                        rank: index + 1,
                                        team: team,
                                        isSelected: selectedTeam?.id == team.id
                                    )
                                    .onTapGesture {
                                        selectedTeam = team
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Alliance Simulator
                    ChartCard(title: "Alliance Simulator", subtitle: "Test potential alliances") {
                        VStack(spacing: 16) {
                            if let preview = selectedAlliance {
                                AlliancePreviewCard(alliance: preview)
                                
                                Button(action: {
                                    selectedAlliance = nil
                                }) {
                                    Label("Clear Alliance", systemImage: "xmark.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Button(action: {
                                    simulateAlliance()
                                }) {
                                    Label("Simulate Top Alliance", systemImage: "play.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // All Teams List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("All Teams")
                                .font(.headline)
                            Spacer()
                            Text("\(allianceService.rankedTeams.count) teams")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        ForEach(allianceService.rankedTeams) { team in
                            TeamDetailRow(team: team)
                                .padding(.horizontal)
                                .onTapGesture {
                                    selectedTeam = team
                                }
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Alliance Selection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            Task {
                                await allianceService.refreshRankings()
                            }
                        }) {
                            Label("Refresh Rankings", systemImage: "arrow.clockwise")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            allianceService.exportPicks()
                        }) {
                            Label("Export Pick List", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingStrategyPicker) {
                StrategyPickerSheet(selectedStrategy: $selectedStrategy)
            }
            .sheet(item: $selectedTeam) { team in
                TeamDetailSheet(team: team)
            }
        }
    }
    
    private func simulateAlliance() {
        guard allianceService.rankedTeams.count >= 3 else { return }
        
        let topTeams = Array(allianceService.rankedTeams.prefix(3))
        selectedAlliance = AlliancePreview(
            captain: topTeams[0],
            firstPick: topTeams[1],
            secondPick: topTeams[2],
            estimatedScore: calculateAllianceScore(topTeams),
            winProbability: calculateWinProbability(topTeams),
            strengths: identifyAllianceStrengths(topTeams),
            weaknesses: identifyAllianceWeaknesses(topTeams)
        )
    }
    
    private func calculateAllianceScore(_ teams: [TeamRankingInfo]) -> Double {
        teams.reduce(0.0) { $0 + $1.overallScore } / Double(teams.count)
    }
    
    private func calculateWinProbability(_ teams: [TeamRankingInfo]) -> Double {
        let avgScore = calculateAllianceScore(teams)
        return min(0.95, avgScore / 100.0)
    }
    
    private func identifyAllianceStrengths(_ teams: [TeamRankingInfo]) -> [String] {
        var strengths: [String] = []
        
        let avgAuto = teams.reduce(0.0) { $0 + $1.autoScore } / Double(teams.count)
        if avgAuto > 75 { strengths.append("Strong autonomous") }
        
        let avgTeleop = teams.reduce(0.0) { $0 + $1.teleopScore } / Double(teams.count)
        if avgTeleop > 75 { strengths.append("Excellent TeleOp") }
        
        let avgEndgame = teams.reduce(0.0) { $0 + $1.endgameScore } / Double(teams.count)
        if avgEndgame > 75 { strengths.append("Reliable endgame") }
        
        return strengths
    }
    
    private func identifyAllianceWeaknesses(_ teams: [TeamRankingInfo]) -> [String] {
        var weaknesses: [String] = []
        
        let avgDefense = teams.reduce(0.0) { $0 + $1.defenseCapability } / Double(teams.count)
        if avgDefense < 50 { weaknesses.append("Limited defense") }
        
        let avgReliability = teams.reduce(0.0) { $0 + $1.reliability } / Double(teams.count)
        if avgReliability < 70 { weaknesses.append("Consistency concerns") }
        
        return weaknesses
    }
}

// MARK: - Team Rank Card
struct TeamRankCard: View {
    let rank: Int
    let team: TeamRankingInfo
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank Badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                Text("\(rank)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Team Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Team \(team.teamNumber)")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    ScoreLabel(label: "Overall", score: team.overallScore, color: .blue)
                    ScoreLabel(label: "Auto", score: team.autoScore, color: .green)
                    ScoreLabel(label: "TeleOp", score: team.teleopScore, color: .orange)
                }
                .font(.caption)
            }
            
            Spacer()
            
            // Quick Stats
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", team.allianceRating))
                        .font(.caption)
                }
                
                Text("\(team.reportCount) reports")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

// MARK: - Score Label
struct ScoreLabel: View {
    let label: String
    let score: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", score))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Alliance Preview Card
struct AlliancePreviewCard: View {
    let alliance: AlliancePreview
    
    var body: some View {
        VStack(spacing: 16) {
            // Alliance Members
            VStack(spacing: 8) {
                AllianceMemberRow(label: "Captain", team: alliance.captain, icon: "star.fill")
                AllianceMemberRow(label: "First Pick", team: alliance.firstPick, icon: "1.circle.fill")
                AllianceMemberRow(label: "Second Pick", team: alliance.secondPick, icon: "2.circle.fill")
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 20) {
                VStack {
                    Text(String(format: "%.1f", alliance.estimatedScore))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Est. Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(Int(alliance.winProbability * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Win Prob.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !alliance.strengths.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Strengths", systemImage: "hand.thumbsup.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    ForEach(alliance.strengths, id: \.self) { strength in
                        Text("• \(strength)")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if !alliance.weaknesses.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Considerations", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    ForEach(alliance.weaknesses, id: \.self) { weakness in
                        Text("• \(weakness)")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Alliance Member Row
struct AllianceMemberRow: View {
    let label: String
    let team: TeamRankingInfo
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text("Team \(team.teamNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Team Detail Row
struct TeamDetailRow: View {
    let team: TeamRankingInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Team \(team.teamNumber)")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f", team.overallScore))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                MetricBadge(label: "Auto", value: team.autoScore, color: .green)
                MetricBadge(label: "TeleOp", value: team.teleopScore, color: .orange)
                MetricBadge(label: "Endgame", value: team.endgameScore, color: .purple)
            }
            
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                ProgressView(value: team.reliability / 100)
                    .tint(.blue)
                Text("\(Int(team.reliability))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Metric Badge
struct MetricBadge: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(String(format: "%.0f", value))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Strategy Picker Sheet
struct StrategyPickerSheet: View {
    @Binding var selectedStrategy: SelectionStrategy
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SelectionStrategy.allCases) { strategy in
                    Button(action: {
                        selectedStrategy = strategy
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: strategy.icon)
                                .foregroundColor(strategy.color)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(strategy.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(strategy.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedStrategy == strategy {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Selection Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Team Detail Sheet
struct TeamDetailSheet: View {
    let team: TeamRankingInfo
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Team \(team.teamNumber)")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(String(format: "Overall Score: %.1f", team.overallScore))
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    
                    // Detailed Scores
                    VStack(spacing: 12) {
                        DetailScoreRow(label: "Autonomous", score: team.autoScore, icon: "timer", color: .green)
                        DetailScoreRow(label: "TeleOp", score: team.teleopScore, icon: "gamecontroller.fill", color: .orange)
                        DetailScoreRow(label: "Endgame", score: team.endgameScore, icon: "flag.checkered", color: .purple)
                        DetailScoreRow(label: "Alliance Rating", score: team.allianceRating, icon: "person.3.fill", color: .blue)
                        DetailScoreRow(label: "Reliability", score: team.reliability, icon: "checkmark.seal.fill", color: .green)
                        DetailScoreRow(label: "Defense", score: team.defenseCapability, icon: "shield.fill", color: .red)
                        DetailScoreRow(label: "Coordination", score: team.coordinationScore, icon: "arrow.triangle.merge", color: .indigo)
                    }
                    .padding()
                    
                    Text("\(team.reportCount) Scouting Reports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Detail Score Row
struct DetailScoreRow: View {
    let label: String
    let score: Double
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(String(format: "%.1f", score))
                .font(.headline)
                .foregroundColor(color)
        }
        .padding(.horizontal)
    }
}

// MARK: - Empty Alliance State View
struct EmptyAllianceStateView: View {
    let icon: String
    let message: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text(message)
                .font(.headline)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Types
enum SelectionStrategy: String, CaseIterable, Identifiable {
    case balanced = "Balanced"
    case offensive = "Offensive Power"
    case defensive = "Defensive Focus"
    case consistency = "Consistency First"
    case specialist = "Specialist Teams"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .balanced: return "Well-rounded teams across all phases"
        case .offensive: return "Maximize scoring potential"
        case .defensive: return "Strong defense and reliability"
        case .consistency: return "Most reliable performers"
        case .specialist: return "Unique capabilities and skills"
        }
    }
    
    var icon: String {
        switch self {
        case .balanced: return "equal.circle.fill"
        case .offensive: return "bolt.circle.fill"
        case .defensive: return "shield.fill"
        case .consistency: return "checkmark.seal.fill"
        case .specialist: return "star.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .balanced: return .blue
        case .offensive: return .red
        case .defensive: return .green
        case .consistency: return .orange
        case .specialist: return .purple
        }
    }
}

struct AlliancePreview: Identifiable {
    let id = UUID()
    let captain: TeamRankingInfo
    let firstPick: TeamRankingInfo
    let secondPick: TeamRankingInfo
    let estimatedScore: Double
    let winProbability: Double
    let strengths: [String]
    let weaknesses: [String]
}

struct TeamRankingInfo: Identifiable, Equatable {
    let id = UUID()
    let teamNumber: String
    let autoScore: Double
    let teleopScore: Double
    let endgameScore: Double
    let overallScore: Double
    let allianceRating: Double
    let reliability: Double
    let defenseCapability: Double
    let coordinationScore: Double
    let reportCount: Int
    
    static func == (lhs: TeamRankingInfo, rhs: TeamRankingInfo) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    AllianceSelectionView()
}

