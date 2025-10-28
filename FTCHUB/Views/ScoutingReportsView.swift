//
//  ScoutingReportsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct ScoutingReportsView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @State private var showingCreateReport = false
    @State private var showingQuickScout = false
    @State private var searchText = ""
    @State private var selectedPhase: MatchPhase? = nil
    @State private var showingFilters = false
    @State private var selectedAlliance: String? = nil
    @State private var minRating: Double = 0
    @State private var hasNotes: Bool? = nil
    
    var filteredReports: [ScoutingReport] {
        var reports = scoutingService.scoutingReports
        
        if !searchText.isEmpty {
            reports = reports.filter { report in
                report.scoutedTeamNumber.localizedCaseInsensitiveContains(searchText) ||
                report.eventName?.localizedCaseInsensitiveContains(searchText) == true ||
                report.matchNumber?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        if let phase = selectedPhase {
            reports = reports.filter { $0.phase == phase }
        }
        
        if let alliance = selectedAlliance {
            reports = reports.filter { $0.reportData["Alliance Color"] == alliance }
        }
        
        if minRating > 0 {
            reports = reports.filter { report in
                if let rating = Double(report.reportData["Overall Quality"] ?? "0") {
                    return rating >= minRating
                }
                return false
            }
        }
        
        if let hasNotesValue = hasNotes {
            if hasNotesValue {
                reports = reports.filter { !($0.notes?.isEmpty ?? true) || !$0.reportData.isEmpty }
            }
        }
        
        return reports
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    TextField("Search reports...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
                
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            FilterPill(
                                title: "All",
                                isSelected: selectedPhase == nil
                            ) {
                                selectedPhase = nil
                            }
                            
                            ForEach(MatchPhase.allCases, id: \.self) { phase in
                                FilterPill(
                                    title: phase.displayName,
                                    isSelected: selectedPhase == phase
                                ) {
                                    selectedPhase = phase
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    
                    // Filter button
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding(.trailing, DesignSystem.Spacing.sm)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.sm)
            
            if scoutingService.isLoading {
                ProgressView("Loading Reports...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredReports.isEmpty {
                ContentUnavailableView {
                    Label("No Scouting Reports", systemImage: "chart.bar.doc.horizontal")
                } description: {
                    Text("Start scouting matches to collect data about other teams.")
                } actions: {
                    Button("Create Report") {
                        showingCreateReport = true
                    }
                    .primaryButtonStyle()
                }
            } else {
                EnhancedListView(
                    items: filteredReports,
                    onDelete: { report in
                        Task {
                            try await scoutingService.deleteScoutingReport(report: report)
                        }
                    },
                    onEdit: { report in
                        // TODO: Implement edit functionality
                    }
                ) { report in
                    NavigationLink(destination: ScoutingReportDetailView(report: report)) {
                        ScoutingReportCard(report: report)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .navigationTitle("Reports")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingQuickScout = true
                    } label: {
                        Label("Quick Scout", systemImage: "bolt.fill")
                    }
                    
                    Button {
                        showingCreateReport = true
                    } label: {
                        Label("Full Scout", systemImage: "doc.text.fill")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(DesignSystem.Gradients.primary)
                }
            }
        }
        .sheet(isPresented: $showingCreateReport) {
            CreateScoutingReportView()
                .environmentObject(scoutingService)
        }
        .sheet(isPresented: $showingQuickScout) {
            QuickScoutView()
                .environmentObject(scoutingService)
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(
                selectedAlliance: $selectedAlliance,
                minRating: $minRating,
                hasNotes: $hasNotes,
                isPresented: $showingFilters
            )
        }
        .onAppear {
            Task {
                await scoutingService.loadScoutingData()
            }
        }
        .refreshable {
            await scoutingService.loadScoutingData()
        }
    }
}

struct ScoutingReportCard: View {
    let report: ScoutingReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Team \(report.scoutedTeamNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if let allianceColor = report.reportData["Alliance Color"] {
                            Text(allianceColor)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(allianceColor == "Red" ? .white : .white)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, 4)
                                .background(allianceColor == "Red" ? Color.red : Color.blue)
                                .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                        
                        if let matchNumber = report.matchNumber {
                            Text("• \(matchNumber)")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    if let eventName = report.eventName {
                        Text(eventName)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Rating badge
                if let rating = report.reportData["Overall Quality"], let ratingValue = Double(rating) {
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= Int(ratingValue) ? "star.fill" : "star")
                                    .foregroundColor(index <= Int(ratingValue) ? .yellow : .gray)
                                    .font(.caption)
                            }
                        }
                        Text(String(format: "%.1f", ratingValue))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // Quick stats
            VStack(spacing: DesignSystem.Spacing.xs) {
                // Auto stats
                HStack(spacing: DesignSystem.Spacing.md) {
                    if let autoGreen = report.reportData["Auto Green Artifacts"] {
                        ReportStatItem(icon: "circle.fill", color: .green, label: "Auto G:", value: autoGreen)
                    }
                    if let autoPurple = report.reportData["Auto Purple Artifacts"] {
                        ReportStatItem(icon: "circle.fill", color: .purple, label: "Auto P:", value: autoPurple)
                    }
                }
                
                // Teleop stats
                HStack(spacing: DesignSystem.Spacing.md) {
                    if let teleopGreen = report.reportData["Teleop Green Artifacts"] {
                        ReportStatItem(icon: "circle.fill", color: .green, label: "Teleop G:", value: teleopGreen)
                    }
                    if let teleopPurple = report.reportData["Teleop Purple Artifacts"] {
                        ReportStatItem(icon: "circle.fill", color: .purple, label: "Teleop P:", value: teleopPurple)
                    }
                }
            }
            
            // Footer
            HStack {
                Text(report.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                if let notes = report.notes, !notes.isEmpty {
                    Label("Has notes", systemImage: "note.text")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow, radius: 5, x: 0, y: 2)
    }
}

struct ReportStatItem: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption2)
            Text(label)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
    }
}

struct FilterSheet: View {
    @Binding var selectedAlliance: String?
    @Binding var minRating: Double
    @Binding var hasNotes: Bool?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section("Alliance Color") {
                    Picker("Alliance", selection: $selectedAlliance) {
                        Text("All").tag(nil as String?)
                        Text("Red").tag("Red" as String?)
                        Text("Blue").tag("Blue" as String?)
                    }
                }
                
                Section("Minimum Rating") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("\(Int(minRating))")
                                .font(.headline)
                            Spacer()
                            Text("/ 5 stars")
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        Slider(value: $minRating, in: 0...5, step: 1)
                    }
                }
                
                Section("Notes") {
                    Picker("Has Notes", selection: $hasNotes) {
                        Text("All").tag(nil as Bool?)
                        Text("Yes").tag(true as Bool?)
                        Text("No").tag(false as Bool?)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedAlliance = nil
                        minRating = 0
                        hasNotes = nil
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
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

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(isSelected ? AnyView(DesignSystem.Gradients.primary) : AnyView(Color(.systemGray6)))
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .cornerRadius(DesignSystem.CornerRadius.sm)
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
