//
//  ScoutingReportsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct ScoutingReportsView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scheduleService: ScheduleService
    var scoutingSelectedTab: Binding<Int> = .constant(2)
    var isEmbeddedInScoutingHub: Bool = false
    
    @StateObject private var summaryService = TeamSummaryService()
    @State private var showingTemplatePicker = false
    @State private var selectedTemplate: ScoutingTemplate?
    @State private var templateToUse: ScoutingTemplate?
    @State private var showingCreateReport = false
    @State private var shouldUseTemplate = false
    @State private var pendingTemplateSelection: ScoutingTemplate? = nil
    @State private var shouldProceedToForm = false
    @State private var showingQuickScout = false
    @State private var showingGenerateSummary = false
    @State private var searchText = ""

    var filteredReports: [ScoutingReport] {
        var reports = scoutingService.scoutingReports

        if !searchText.isEmpty {
            reports = reports.filter { report in
                report.scoutedTeamNumber.localizedCaseInsensitiveContains(searchText) ||
                report.eventName?.localizedCaseInsensitiveContains(searchText) == true ||
                report.matchNumber?.localizedCaseInsensitiveContains(searchText) == true ||
                report.reportData["Strategy Focus"]?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return reports
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                ScoutingSearchBar(
                    text: $searchText,
                    placeholder: "Search reports...",
                    isEmbeddedInScoutingHub: isEmbeddedInScoutingHub
                )
                
                if scoutingService.isLoading {
                    ProgressView("Loading Reports...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if scoutingService.currentTeamId == nil {
                    ContentUnavailableView {
                        Label("No Team Connected", systemImage: "person.3.sequence")
                    } description: {
                        Text("Join or create a team in the Team tab to start collecting and reviewing scouting data.")
                    }
                } else if let errorMessage = scoutingService.errorMessage {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.error)
                        
                        Text("Error Loading Reports")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if filteredReports.isEmpty {
                    EnhancedEmptyStateView.noReports {
                        showingTemplatePicker = true
                    }
                } else {
                    LazyVStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(filteredReports) { report in
                            NavigationLink(destination: ScoutingReportDetailView(report: report)) {
                                ScoutingReportCard(report: report)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(isEmbeddedInScoutingHub ? "" : "Reports")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    Menu {
                        Button {
                            showingQuickScout = true
                        } label: {
                            Label("Quick Scout", systemImage: "bolt.fill")
                        }
                        if !scoutingService.scoutingReports.isEmpty {
                            Button {
                                showingGenerateSummary = true
                            } label: {
                                Label("Generate Summary", systemImage: "sparkles")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    Button(action: {
                        showingTemplatePicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTemplatePicker) {
            ScoutingTemplatePickerView(
                selectedTemplate: $selectedTemplate,
                onTemplateSelected: { template in
                    // Store the pending selection and mark that we should proceed
                    pendingTemplateSelection = template
                    shouldProceedToForm = true
                    // Dismiss the template picker
                    showingTemplatePicker = false
                },
                onCancel: {
                    // User cancelled - reset all state, don't proceed
                    pendingTemplateSelection = nil
                    shouldProceedToForm = false
                    templateToUse = nil
                    selectedTemplate = nil
                    shouldUseTemplate = false
                    showingTemplatePicker = false
                }
            )
            .environmentObject(scoutingService)
            .onDisappear {
                // When picker dismisses, process the pending selection only if we should proceed
                guard shouldProceedToForm else { return }
                
                if let template = pendingTemplateSelection {
                    // Template was selected
                    templateToUse = template
                    selectedTemplate = template
                    shouldUseTemplate = true
                } else {
                    // Explicitly nil means "Create Without Template"
                    templateToUse = nil
                    selectedTemplate = nil
                    shouldUseTemplate = false
                }
                
                // Clear pending state
                pendingTemplateSelection = nil
                shouldProceedToForm = false
                
                // Show the create report form after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showingCreateReport = true
                }
            }
        }
        .sheet(isPresented: $showingCreateReport) {
            Group {
                if shouldUseTemplate, let template = templateToUse {
                    // Show dynamic form with selected template
                    DynamicScoutingFormView(template: template)
                        .environmentObject(scoutingService)
                        .onDisappear {
                            // Reset state when form is dismissed
                            templateToUse = nil
                            selectedTemplate = nil
                            shouldUseTemplate = false
                        }
                } else {
                    // Show generic form (no template selected)
                    CreateScoutingReportView()
                        .environmentObject(scoutingService)
                        .onDisappear {
                            // Reset state when form is dismissed
                            templateToUse = nil
                            selectedTemplate = nil
                            shouldUseTemplate = false
                        }
                }
            }
        }
        .sheet(isPresented: $showingQuickScout) {
            QuickScoutView()
                .environmentObject(scoutingService)
        }
        .sheet(isPresented: $showingGenerateSummary) {
            GenerateSummaryView()
                .environmentObject(scoutingService)
                .environmentObject(summaryService)
        }
        .task {
            await scoutingService.loadScoutingData()
        }
        .refreshable {
            await scoutingService.loadScoutingData()
        }
    }
}


struct ScoutingReportCard: View {
    let report: ScoutingReport

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Header with team info and rating
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                Text("Team \(report.scoutedTeamNumber)")
                            .font(.title3.weight(.bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                    if let allianceColor = report.stringValue("Alliance Color") {
                        Text(allianceColor)
                                .font(.caption2.weight(.semibold))
                            .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                            .background(allianceColor == "Red" ? Color.red : Color.blue)
                                .cornerRadius(4)
                        }
                    }

                    if let matchNumber = report.matchNumber {
                        Text("Match \(matchNumber)")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }

            Spacer()

            if let ratingValue = report.doubleValue("Overall Quality") {
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= Int(ratingValue.rounded(.down)) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 10))
                            }
                        }
                        Text(String(format: "%.1f", ratingValue))
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            // Key metrics in a compact grid
            if let autoClassified = report.stringValue("Auto Classified Artifacts"),
               let teleopClassified = report.stringValue("Teleop Classified Artifacts") {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ReportMetricBadge(icon: "bolt.fill", label: "Auto", value: autoClassified, color: .blue)
                    ReportMetricBadge(icon: "timer", label: "Teleop", value: teleopClassified, color: .green)
                    if let driveBase = report.stringValue("Drive Base") {
                        ReportMetricBadge(icon: "gearshape.fill", label: "Drive", value: driveBase, color: DesignSystem.Colors.primary)
                    }
                }
            }
            
            // Tags row
            if let phase = report.phase {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    PhaseBadge(phase: phase)
                    if let strategy = report.stringValue("Strategy Focus") {
                        Text(strategy)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Footer with timestamp
            Text(report.createdAt, style: .relative)
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

private struct ReportMetricBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Text(value)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(6)
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.primary)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

private struct StatLine: View {
    let label: String
    let value: String?

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value ?? "–")
                .font(.caption.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

private struct CapabilityChip: View {
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DesignSystem.Colors.tertiaryBackground)
        .foregroundColor(DesignSystem.Colors.textPrimary)
        .clipShape(Capsule())
    }
}

private struct RPBadge: View {
    let title: String
    let achieved: Bool
    let detail: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.xs) {
                Image(systemName: achieved ? "checkmark.seal.fill" : "xmark.seal")
                    .foregroundColor(achieved ? .green : .gray)
                    .font(.system(size: 14, weight: .semibold))
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
            }
            Text(detail)
                .font(.caption2)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}


private struct StarRatingView: View {
    let score: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= Int(score.rounded(.down)) ? "star.fill" : (Double(index) - 0.5 <= score ? "star.leadinghalf.filled" : "star"))
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }
}

private extension ScoutingReport {
    func stringValue(_ key: String) -> String? {
        guard let value = reportData[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }

    func doubleValue(_ key: String) -> Double? {
        guard let text = stringValue(key) else { return nil }
        return Double(text)
    }

    func boolValue(_ key: String) -> Bool? {
        guard let text = stringValue(key)?.lowercased() else { return nil }
        switch text {
        case "true", "yes", "y", "1": return true
        case "false", "no", "n", "0": return false
        default: return nil
        }
    }
}

private extension NumberFormatter {
    static func percentString(from value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "–"
    }
}

struct PhaseBadge: View {
    let phase: MatchPhase
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: phase.icon)
                .font(.caption)
            Text(phase.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(phaseColor.opacity(0.2))
        .foregroundColor(phaseColor)
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
    
    private var phaseColor: Color {
        switch phase {
        case .auto: return .blue
        case .teleop: return .green
        case .endgame: return .orange
        }
    }
}

#Preview {
    NavigationView {
        ScoutingReportsView()
            .environmentObject(ScoutingService())
            .environmentObject(AuthService())
    }
}
