//
//  ScoutingReportDetailView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct ScoutingReportDetailView: View {
    let report: ScoutingReport
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var scoutingService: ScoutingService
    @State private var showingShareSheet = false
    @State private var showingEdit = false
    @State private var selectedPhoto: UIImage?
    @State private var showingReportContent = false
    @State private var showingDeleteConfirmation = false
    @StateObject private var moderationService = ContentModerationService.shared
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if geometry.size.width > geometry.size.height {
                // Landscape layout - two columns
                HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Header Card
                        headerCard
                        
                        // Quick Stats
                        ReportQuickStatsCard(report: report)
                        
                        // Autonomous Section
                        autonomousSectionCard
                        
                        // Endgame Section
                        endgameSectionCard
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Teleop Section
                        teleopSectionCard
                        
                        // Notes Sections
                        notesSections
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(DesignSystem.Spacing.md)
            } else {
                // Portrait layout - single column
                VStack(spacing: DesignSystem.Spacing.lg) {
                    headerCard
                    ReportQuickStatsCard(report: report)
                    autonomousSectionCard
                    teleopSectionCard
                    endgameSectionCard
                    notesSections
                }
                .padding(DesignSystem.Spacing.md)
                }
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Report Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
                .minimalButtonStyle()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        showingShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingReportContent = true
                    } label: {
                        Label("Report Content", systemImage: "exclamationmark.triangle")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationView {
                EditScoutingReportView(report: report)
                    .environmentObject(scoutingService)
            }
        }
        .sheet(isPresented: $showingReportContent) {
            ReportContentView(
                contentType: .scoutingReport,
                contentId: report.id,
                contentTitle: "Scouting Report - Team \(report.scoutedTeamNumber)"
            )
            .environmentObject(moderationService)
        }
        .alert("Delete Report", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await scoutingService.deleteScoutingReport(report: report)
                        dismiss()
                    } catch {
                        DebugLog.log("Failed to delete report: \(error)")
                        // Error is already set in scoutingService.errorMessage
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this scouting report? This action cannot be undone and the report will be permanently deleted.")
        }
        .alert("Error", isPresented: Binding(get: { scoutingService.errorMessage != nil }, set: { _ in scoutingService.errorMessage = nil })) {
            Button("OK") { }
        } message: {
            Text(scoutingService.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    // MARK: - Section Views
    private var headerCard: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("TEAM \(report.scoutedTeamNumber)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let matchNumber = report.matchNumber {
                        Text(matchNumber)
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    if let eventName = report.eventName {
                        Text(eventName)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    if let allianceColor = report.reportData["Alliance Color"] {
                        Text(allianceColor + " Alliance")
                            .font(.subheadline)
                            .foregroundColor(allianceColor == "Red" ? .red : .blue)
                            .fontWeight(.medium)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if report.scoutId != nil {
                            Text("Scouted by: Scout")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Text(report.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Overall rating
                if let rating = report.reportData["Overall Quality"] {
                    RatingStars(rating: Int(Double(rating) ?? 0), maxRating: 5, size: .large)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Gradients.primary.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    private var autonomousSectionCard: some View {
        ReportSectionCard(title: "Autonomous (30 sec)", icon: "play.circle.fill") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                ReportStatRow(label: "Green Artifacts", value: report.reportData["Auto Green Artifacts"] ?? "0", icon: "circle.fill", color: .green)
                ReportStatRow(label: "Purple Artifacts", value: report.reportData["Auto Purple Artifacts"] ?? "0", icon: "circle.fill", color: .purple)
                
                if let reliability = report.reportData["Auto Reliability"] {
                    HStack {
                        Text("Reliability:")
                            .font(.subheadline)
                        RatingStars(rating: Int(Double(reliability) ?? 0), maxRating: 5, size: .medium)
                    }
                }
            }
        }
    }
    
    private var teleopSectionCard: some View {
        ReportSectionCard(title: "Teleop (120 sec)", icon: "person.circle.fill") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                ReportStatRow(label: "Green Artifacts", value: report.reportData["Teleop Green Artifacts"] ?? "0", icon: "circle.fill", color: .green)
                ReportStatRow(label: "Purple Artifacts", value: report.reportData["Teleop Purple Artifacts"] ?? "0", icon: "circle.fill", color: .purple)
                
                if let driving = report.reportData["Driving Quality"] {
                    ReportStatRow(label: "Driving Quality", value: "\(driving)/5", icon: "hand.thumbsup")
                }
                
                if let speed = report.reportData["Robot Speed"] {
                    ReportStatRow(label: "Robot Speed", value: "\(speed)/5", icon: "speedometer")
                }
                
                if let strategy = report.reportData["Primary Strategy"] {
                    ReportStatRow(label: "Strategy", value: strategy, icon: "brain.head.profile")
                }
                
                if let defends = report.reportData["Defends Well"] {
                    HStack {
                        Image(systemName: "shield.checkered")
                        Text("Defends Well: \(defends == "true" ? "Yes" : "No")")
                    }
                    .font(.subheadline)
                }
                
                if let penalties = report.reportData["Penalties"] {
                    ReportStatRow(label: "Penalties", value: penalties, icon: "exclamationmark.triangle")
                }
                
                if let coordination = report.reportData["Alliance Coordination"] {
                    HStack {
                        Image(systemName: "person.2")
                        Text("Alliance Coordination: \(coordination == "true" ? "Yes" : "No")")
                    }
                    .font(.subheadline)
                }
            }
        }
    }
    
    private var endgameSectionCard: some View {
        ReportSectionCard(title: "Endgame (30 sec)", icon: "flag.circle.fill") {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                ReportStatRow(label: "Green Artifacts", value: report.reportData["Endgame Green Artifacts"] ?? "0", icon: "circle.fill", color: .green)
                ReportStatRow(label: "Purple Artifacts", value: report.reportData["Endgame Purple Artifacts"] ?? "0", icon: "circle.fill", color: .purple)
                
                if let parked = report.reportData["Parked in Zone"] {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Parked: \(parked == "true" ? "Yes" : "No")")
                    }
                    .font(.subheadline)
                }
                
                if let execution = report.reportData["Endgame Execution"] {
                    HStack {
                        Text("Execution:")
                            .font(.subheadline)
                        RatingStars(rating: Int(Double(execution) ?? 0), maxRating: 5, size: .medium)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var notesSections: some View {
        if let notes = report.notes, !notes.isEmpty {
            ReportSectionCard(title: "Notes", icon: "note.text") {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        
        if let artifactNotes = report.reportData["Artifact Strategy Notes"], !artifactNotes.isEmpty {
            ReportSectionCard(title: "Artifact Strategy", icon: "lightbulb") {
                Text(artifactNotes)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        
        if let generalNotes = report.reportData["General Notes"], !generalNotes.isEmpty {
            ReportSectionCard(title: "General Notes", icon: "doc.text") {
                Text(generalNotes)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        
        if let allianceNotes = report.reportData["Alliance Selection Notes"], !allianceNotes.isEmpty {
            ReportSectionCard(title: "Alliance Selection", icon: "person.3") {
                Text(allianceNotes)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Supporting Views

struct ReportQuickStatsCard: View {
    let report: ScoutingReport
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.xl) {
                ReportQuickStatItem(
                    icon: "star.fill",
                    value: report.reportData["Overall Quality"] ?? "0",
                    label: "Overall"
                )
                
                Divider()
                    .frame(height: 40)
                
                ReportQuickStatItem(
                    icon: "play.circle",
                    value: report.reportData["Auto Green Artifacts"] ?? "0",
                    label: "Auto Green"
                )
                
                Divider()
                    .frame(height: 40)
                
                ReportQuickStatItem(
                    icon: "person.circle",
                    value: report.reportData["Teleop Green Artifacts"] ?? "0",
                    label: "Teleop"
                )
            }
            
            if let parked = report.reportData["Parked in Zone"], parked == "true" {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.success)
                    Text("Parked in Endgame")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
    }
}

struct ReportQuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(DesignSystem.Gradients.primary)
                .font(.title3)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct ReportSectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(DesignSystem.Gradients.primary)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            content
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
    }
}

struct ReportStatRow: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = DesignSystem.Colors.primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

struct RatingStars: View {
    let rating: Int
    let maxRating: Int
    var size: StarSize = .medium
    
    enum StarSize {
        case small, medium, large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 24
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(index <= rating ? .yellow : .gray)
                    .font(.system(size: size.fontSize))
            }
        }
    }
}

#Preview {
    NavigationView {
        ScoutingReportDetailView(report: ScoutingReport.sample)
    }
}
