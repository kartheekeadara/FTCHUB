//
//  TeamScoutingSummaryView.swift
//  FTCHUB
//
//  Created on 11/16/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TeamScoutingSummaryView: View {
    let summary: TeamScoutingSummary
    @EnvironmentObject var summaryService: TeamSummaryService
    @State private var showingEditView = false
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header Card
                SummaryHeaderCard(summary: summary)
                
                // Quick Stats Grid
                QuickStatsGrid(summary: summary)
                
                // Strengths
                SummarySectionCard(
                    title: "Strengths",
                    icon: "checkmark.circle.fill",
                    color: .green
                ) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        ForEach(summary.strengths, id: \.self) { strength in
                            HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                                Text("•")
                                    .foregroundColor(.green)
                                Text(strength)
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                        }
                    }
                }
                
                // Weaknesses
                SummarySectionCard(
                    title: "Weaknesses",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                ) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        ForEach(summary.weaknesses, id: \.self) { weakness in
                            HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                                Text("•")
                                    .foregroundColor(.orange)
                                Text(weakness)
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                        }
                    }
                }
                
                // Role Recommendation
                RoleRecommendationCard(summary: summary)
                
                // Match Tactics
                MatchTacticsCard(tactics: summary.matchTactics)
                
                // Alliance Fit
                AllianceFitCard(allianceFit: summary.allianceFit)
                
                // Exploitation / Countermeasures
                ExploitationCard(
                    exploitationNotes: summary.exploitationNotes,
                    countermeasures: summary.countermeasures
                )
                
                // Pit Notes
                PitNotesCard(pitNotes: summary.pitNotes)
                
                // Quick Action Items
                ActionItemsCard(items: summary.quickActionItems)
                
                // Raw Data Links
                RawDataLinksCard(links: summary.rawDataLinks)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Team \(summary.scoutedTeamNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditView = true
                    } label: {
                        Label("Edit Summary", systemImage: "pencil")
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            TeamSummaryEditView(summary: summary)
                .environmentObject(summaryService)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [generateShareText()])
        }
    }
    
    private func generateShareText() -> String {
        var text = "Team \(summary.scoutedTeamNumber) Scouting Summary\n"
        text += "Event: \(summary.eventName ?? "N/A")\n"
        text += "Matches Sampled: \(summary.matchesSampled)\n\n"
        text += "Quick Stats:\n"
        text += "• Avg Auto: \(String(format: "%.1f", summary.avgAutoArtifacts))\n"
        text += "• Auto Success: \(String(format: "%.0f", summary.autoSuccessRate))%\n"
        text += "• Avg Teleop: \(String(format: "%.1f", summary.avgTeleopArtifacts))\n"
        text += "• Endgame Success: \(String(format: "%.0f", summary.avgEndgameSuccess))%\n"
        text += "• Reliability: \(String(format: "%.0f", summary.reliability))%\n\n"
        text += "Strengths:\n"
        for strength in summary.strengths {
            text += "• \(strength)\n"
        }
        text += "\nWeaknesses:\n"
        for weakness in summary.weaknesses {
            text += "• \(weakness)\n"
        }
        return text
    }
}

// MARK: - Supporting Views

struct SummaryHeaderCard: View {
    let summary: TeamScoutingSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Team \(summary.scoutedTeamNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let eventName = summary.eventName {
                        Text(eventName)
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Label("\(summary.matchesSampled) matches", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        if let scoutName = summary.scoutName {
                            Label(scoutName, systemImage: "person")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(summary.lastUpdated, style: .relative)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Gradients.primary.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
}

struct QuickStatsGrid: View {
    let summary: TeamScoutingSummary
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.md) {
            SummaryStatCard(title: "Matches", value: "\(summary.matchesSampled)", icon: "doc.text.fill", color: .blue)
            SummaryStatCard(title: "Avg Auto", value: String(format: "%.1f", summary.avgAutoArtifacts), icon: "play.circle.fill", color: .blue)
            SummaryStatCard(title: "Auto Success", value: String(format: "%.0f%%", summary.autoSuccessRate), icon: "checkmark.circle.fill", color: .green)
            SummaryStatCard(title: "Avg Teleop", value: String(format: "%.1f", summary.avgTeleopArtifacts), icon: "person.circle.fill", color: .purple)
            SummaryStatCard(title: "Endgame %", value: String(format: "%.0f%%", summary.avgEndgameSuccess), icon: "flag.circle.fill", color: .orange)
            SummaryStatCard(title: "Reliability", value: String(format: "%.0f%%", summary.reliability), icon: "gearshape.fill", color: .green)
            SummaryStatCard(title: "Penalties", value: String(format: "%.1f", summary.avgPenalties), icon: "exclamationmark.triangle.fill", color: .red)
            SummaryStatCard(title: "Consistency", value: String(format: "±%.1f", summary.consistency), icon: "chart.bar.fill", color: .blue)
        }
    }
}

struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct SummarySectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            content
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
    }
}

struct RoleRecommendationCard: View {
    let summary: TeamScoutingSummary
    
    var body: some View {
        SummarySectionCard(
            title: "Role Recommendation",
            icon: "person.2.fill",
            color: DesignSystem.Colors.primary
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("Primary:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(summary.primaryRole)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                HStack {
                    Text("Secondary:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(summary.secondaryRole)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
    }
}

struct MatchTacticsCard: View {
    let tactics: MatchTactics
    
    @State private var isExpanded = false
    
    var body: some View {
        SummarySectionCard(
            title: "Match Tactics",
            icon: "brain.head.profile",
            color: DesignSystem.Colors.accent
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                TacticRow(phase: "Autonomous", tactic: tactics.autonomous, icon: "play.circle.fill")
                TacticRow(phase: "Teleop", tactic: tactics.teleop, icon: "person.circle.fill")
                TacticRow(phase: "Defense", tactic: tactics.defense, icon: "shield.fill")
                TacticRow(phase: "Endgame", tactic: tactics.endgame, icon: "flag.circle.fill")
            }
        }
    }
}

struct TacticRow: View {
    let phase: String
    let tactic: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(DesignSystem.Colors.primary)
                Text(phase)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Text(tactic)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

struct AllianceFitCard: View {
    let allianceFit: AllianceFit
    
    var body: some View {
        SummarySectionCard(
            title: "Alliance Fit & Pick Priority",
            icon: "person.3.fill",
            color: DesignSystem.Colors.success
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Ideal Partners:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(allianceFit.idealPartners)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Pick Priority:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        HStack {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= allianceFit.pickPriority ? "star.fill" : "star")
                                    .foregroundColor(index <= allianceFit.pickPriority ? .yellow : .gray)
                            }
                            Text("(\(allianceFit.pickPriority)/5)")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Text(allianceFit.priorityReason)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .italic()
            }
        }
    }
}

struct ExploitationCard: View {
    let exploitationNotes: String
    let countermeasures: String
    
    var body: some View {
        SummarySectionCard(
            title: "Exploitation / Countermeasures",
            icon: "target",
            color: .red
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                if !exploitationNotes.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("To Exploit:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(exploitationNotes)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                if !countermeasures.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("To Neutralize:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(countermeasures)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                if exploitationNotes.isEmpty && countermeasures.isEmpty {
                    Text("No exploitation notes yet")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .italic()
                }
            }
        }
    }
}

struct PitNotesCard: View {
    let pitNotes: PitNotes
    
    var body: some View {
        SummarySectionCard(
            title: "Pit Notes",
            icon: "wrench.and.screwdriver.fill",
            color: DesignSystem.Colors.secondary
        ) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    Text("Battery Health:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    Text(pitNotes.batteryHealth)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                if !pitNotes.knownFailureModes.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Known Failures:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        ForEach(pitNotes.knownFailureModes, id: \.self) { failure in
                            Text("• \(failure)")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                    }
                }
                
                if !pitNotes.humanFactors.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Human Factors:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(pitNotes.humanFactors)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                }
            }
        }
    }
}

struct ActionItemsCard: View {
    let items: [String]
    
    var body: some View {
        SummarySectionCard(
            title: "Quick Action Items",
            icon: "list.bullet",
            color: DesignSystem.Colors.primary
        ) {
            if items.isEmpty {
                Text("No action items yet")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                    }
                }
            }
        }
    }
}

struct RawDataLinksCard: View {
    let links: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(DesignSystem.Colors.primary)
                Text("Raw Data Links")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Text(links)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
    }
}

// MARK: - Share Sheet

#if canImport(UIKit)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    NavigationView {
        TeamScoutingSummaryView(summary: TeamScoutingSummary.sample)
            .environmentObject(TeamSummaryService())
    }
}

