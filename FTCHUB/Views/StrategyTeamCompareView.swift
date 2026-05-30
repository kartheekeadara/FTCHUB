//
//  StrategyTeamCompareView.swift
//  FTCHUB
//
//  Side-by-side summaries from your scouting reports (up to 3 teams).
//

import SwiftUI

struct StrategyTeamCompareView: View {
    let seedTeamNumbers: [String]
    @EnvironmentObject var scoutingService: ScoutingService
    
    @State private var teamFields: [String] = ["", "", ""]
    
    private var activeTeams: [String] {
        let seeds = seedTeamNumbers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if !seeds.isEmpty { return Array(seeds.prefix(3)) }
        return teamFields.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Text("Compare teams using averages from your scouting reports only.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                if seedTeamNumbers.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Enter up to three team numbers")
                                .font(.subheadline.weight(.semibold))
                            ForEach(0..<3, id: \.self) { i in
                                TextField("Team \(i + 1)", text: $teamFields[i])
                                    .keyboardType(.asciiCapableNumberPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
                
                if activeTeams.isEmpty {
                    Text("Add at least one team number.")
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                            ForEach(activeTeams, id: \.self) { num in
                                teamColumn(teamNumber: num)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            for (i, t) in seedTeamNumbers.prefix(3).enumerated() where i < 3 {
                teamFields[i] = t
            }
        }
    }
    
    @ViewBuilder
    private func teamColumn(teamNumber: String) -> some View {
        let s = scoutingService.strategyScoutSummary(for: teamNumber)
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(teamNumber)
                .font(.title3.weight(.bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let s {
                metricRow("Reports", "\(s.reportCount)")
                metricRow("Avg quality", s.avgOverallFormatted)
                metricRow("Avg auto reliability", s.avgAutoFormatted)
                metricRow("Avg alliance pick", s.avgAllianceFormatted)
                if let last = s.lastReportDate {
                    metricRow("Last report", last.formatted(date: .abbreviated, time: .omitted))
                }
            } else {
                Text("No reports for this team.")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.warning)
            }
        }
        .frame(minWidth: 160, alignment: .leading)
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func metricRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.textTertiary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}
