//
//  MatchScheduleView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
import UniformTypeIdentifiers
import Charts

#if canImport(UIKit)
import UIKit
#endif

struct MatchScheduleView: View {
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var teamService: TeamService
    
    @State private var searchText = ""
    @State private var showingNewMatchSheet = false
    @State private var showingScheduleScanner = false
    @State private var matchBeingEdited: Match?
    @State private var alertInfo: AlertMessage?
    @State private var layoutMode: ScheduleLayoutMode = .grouped
    @State private var density: ScheduleDensity = .comfort
    @State private var quickNoteTarget: Match?
    @State private var showingDeleteAllConfirmation = false
    @State private var isSelectionMode = false
    @State private var selectedMatches: Set<UUID> = []
    @State private var showingDeleteSelectedConfirmation = false
    @State private var groupByEvent = false
    @State private var showingAddMatchOptions = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.width > geometry.size.height {
                    ScrollView {
                        contentSectionContent
                            .padding(DesignSystem.Spacing.md)
                    }
                } else {
                    List {
                        contentSection
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Match Schedule")
            .searchable(text: $searchText, prompt: "Search matches, teams, fields")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingNewMatchSheet = true
                        } label: {
                            Label("Add Match Manually", systemImage: "plus")
                        }
                        .disabled(!scheduleService.hasTeamContext)
                        
                        Button {
                            showingScheduleScanner = true
                        } label: {
                            Label("Scan Schedule", systemImage: "camera.fill")
                        }
                        .disabled(!scheduleService.hasTeamContext)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!scheduleService.hasTeamContext)
                    .accessibilityLabel("Add Match")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isSelectionMode && !scheduleService.matches.isEmpty {
                        Menu {
                            Button {
                                isSelectionMode = true
                            } label: {
                                Label("Select Matches", systemImage: "checkmark.circle")
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteAllConfirmation = true
                            } label: {
                                Label("Delete All Matches", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Button("Cancel") {
                            isSelectionMode = false
                            selectedMatches.removeAll()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSelectionMode {
                        if !selectedMatches.isEmpty {
                            Button(role: .destructive) {
                                showingDeleteSelectedConfirmation = true
                            } label: {
                                Label("Delete (\(selectedMatches.count))", systemImage: "trash")
                            }
                        } else {
                            Button("Done") {
                                isSelectionMode = false
                                selectedMatches.removeAll()
                            }
                        }
                    }
                }
            }
            .refreshable {
                await scheduleService.loadMatches()
            }
            .sheet(isPresented: $showingNewMatchSheet) {
                MatchEditorView(mode: .create(defaultDate: nil))
                    .environmentObject(scheduleService)
                    .environmentObject(teamService)
            }
            .sheet(isPresented: $showingScheduleScanner) {
                ScheduleScannerView()
                    .environmentObject(ScheduleScanService.shared)
                    .environmentObject(scheduleService)
                    .environmentObject(teamService)
            }
            .sheet(item: $matchBeingEdited) { match in
                MatchEditorView(mode: .edit(match))
                    .environmentObject(scheduleService)
                    .environmentObject(teamService)
            }
            .sheet(item: $quickNoteTarget) { match in
                QuickNoteComposer(match: match)
                    .environmentObject(scheduleService)
            }
            .alert(item: $alertInfo) { info in
                Alert(
                    title: Text(info.title),
                    message: Text(info.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Delete All Matches", isPresented: $showingDeleteAllConfirmation) {
                Button("Delete All", role: .destructive) {
                    Task {
                        for match in scheduleService.matches {
                            do {
                                try await scheduleService.deleteMatch(match)
                            } catch {
                                alertInfo = AlertMessage(title: "Error", message: error.localizedDescription)
                                break
                            }
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete all \(scheduleService.matches.count) matches? This action cannot be undone.")
            }
            .alert("Delete Selected Matches", isPresented: $showingDeleteSelectedConfirmation) {
                Button("Delete", role: .destructive) {
                    Task {
                        let matchesToDelete = scheduleService.matches.filter { selectedMatches.contains($0.id) }
                        for match in matchesToDelete {
                            do {
                                try await scheduleService.deleteMatch(match)
                            } catch {
                                alertInfo = AlertMessage(title: "Error", message: error.localizedDescription)
                                break
                            }
                        }
                        selectedMatches.removeAll()
                        isSelectionMode = false
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(selectedMatches.count) selected match(es)? This action cannot be undone.")
            }
            .task {
                if scheduleService.matches.isEmpty,
                   scheduleService.hasTeamContext,
                   !scheduleService.isLoading {
                    await scheduleService.loadMatches()
                }
            }
            .task(id: scheduleService.errorMessage) {
                guard let message = scheduleService.errorMessage else { return }
                alertInfo = AlertMessage(title: "Error", message: message)
                scheduleService.errorMessage = nil
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var contentSection: some View {
        if scheduleService.isLoading {
            Section {
                HStack {
                    Spacer()
                    ProgressView("Loading matches…")
                        .padding(.vertical, DesignSystem.Spacing.lg)
                    Spacer()
                }
            }
        } else if !scheduleService.hasTeamContext {
            Section {
                ContentUnavailableView {
                    Label("No Team Connected", systemImage: "person.3.sequence")
                } description: {
                    Text("Join or create a team in the Team tab to manage your match schedule.")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
        } else if groupedMatches.isEmpty {
            Section {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    Spacer()
                        .frame(height: 40)
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.primary.opacity(0.15),
                                        DesignSystem.Colors.primary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                    }
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("No Matches Scheduled")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Add matches manually to keep the team in sync.")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    Button(action: {
                        showingAddMatchOptions = true
                    }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Add Match")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(DesignSystem.Gradients.primary)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 4)
                    }
                    .confirmationDialog("Add Match", isPresented: $showingAddMatchOptions, titleVisibility: .visible) {
                        Button {
                            showingNewMatchSheet = true
                        } label: {
                            Label("Add Match Manually", systemImage: "pencil")
                        }
                        
                        Button {
                            showingScheduleScanner = true
                        } label: {
                            Label("Scan Schedule", systemImage: "camera.fill")
                        }
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.xl)
            }
        } else {
            let nextMatchId = scheduleService.upcomingMatch()?.id
            switch layoutMode {
            case .grouped:
                groupedMatchList(nextMatchId: nextMatchId)
            case .timeline:
                timelineMatchList(nextMatchId: nextMatchId)
            }
        }
    }
    
    @ViewBuilder
    private var contentSectionContent: some View {
        if scheduleService.isLoading {
            HStack {
                Spacer()
                ProgressView("Loading matches…")
                    .padding(.vertical, DesignSystem.Spacing.lg)
                Spacer()
            }
        } else if !scheduleService.hasTeamContext {
            ContentUnavailableView {
                Label("No Team Connected", systemImage: "person.3.sequence")
            } description: {
                Text("Join or create a team in the Team tab to manage your match schedule.")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.lg)
        } else if groupedMatches.isEmpty {
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()
                    .frame(height: 40)
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.primary.opacity(0.15),
                                    DesignSystem.Colors.primary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(DesignSystem.Gradients.primary)
                }
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text("No Matches Scheduled")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Add matches manually to keep the team in sync.")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                
                Button(action: {
                    showingAddMatchOptions = true
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Match")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Gradients.primary)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 4)
                }
                .confirmationDialog("Add Match", isPresented: $showingAddMatchOptions, titleVisibility: .visible) {
                    Button {
                        showingNewMatchSheet = true
                    } label: {
                        Label("Add Match Manually", systemImage: "pencil")
                    }
                    
                    Button {
                        showingScheduleScanner = true
                    } label: {
                        Label("Scan Schedule", systemImage: "camera.fill")
                    }
                }
                
                Spacer()
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.xl)
        } else {
            let nextMatchId = scheduleService.upcomingMatch()?.id
            // Check if we should group by event (either toggle is on or matches have event names)
            let shouldGroupByEvent = groupByEvent || (filteredMatches.contains { $0.eventName != nil && !$0.eventName!.isEmpty })
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                if shouldGroupByEvent {
                    ForEach(groupedMatchesByEvent, id: \.eventName) { eventGroup in
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(DesignSystem.Colors.primary)
                                Text(eventGroup.eventName)
                                    .font(.headline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            
                            ForEach(eventGroup.matches) { match in
                                if isSelectionMode {
                                    HStack {
                                        Button {
                                            if selectedMatches.contains(match.id) {
                                                selectedMatches.remove(match.id)
                                            } else {
                                                selectedMatches.insert(match.id)
                                            }
                                        } label: {
                                            Image(systemName: selectedMatches.contains(match.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedMatches.contains(match.id) ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                                                .font(.title3)
                                        }
                                        
                                        MatchRowView(
                                            match: match,
                                            isNextUp: match.id == nextMatchId,
                                            noteCount: scheduleService.noteCount(for: match)
                                        )
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                } else {
                                    MatchRowView(
                                        match: match,
                                        isNextUp: match.id == nextMatchId,
                                        noteCount: scheduleService.noteCount(for: match)
                                    )
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                }
                            }
                        }
                    }
                } else {
                    ForEach(groupedMatches, id: \.date) { entry in
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                            
                            ForEach(entry.matches) { match in
                                if isSelectionMode {
                                    HStack {
                                        Button {
                                            if selectedMatches.contains(match.id) {
                                                selectedMatches.remove(match.id)
                                            } else {
                                                selectedMatches.insert(match.id)
                                            }
                                        } label: {
                                            Image(systemName: selectedMatches.contains(match.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedMatches.contains(match.id) ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                                                .font(.title3)
                                        }
                                        
                                        MatchRowView(
                                            match: match,
                                            isNextUp: match.id == nextMatchId,
                                            noteCount: scheduleService.noteCount(for: match)
                                        )
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                } else {
                                    MatchRowView(
                                        match: match,
                                        isNextUp: match.id == nextMatchId,
                                        noteCount: scheduleService.noteCount(for: match)
                                    )
                                    .padding(.horizontal, DesignSystem.Spacing.sm)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func groupedMatchList(nextMatchId: UUID?) -> some View {
        if groupByEvent || (filteredMatches.contains { $0.eventName != nil && !$0.eventName!.isEmpty }) {
            ForEach(groupedMatchesByEvent, id: \.eventName) { eventGroup in
                Section(header: HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text(eventGroup.eventName)
                        .font(.headline)
                }) {
                    ForEach(eventGroup.matches) { match in
                        matchRowView(match: match, nextMatchId: nextMatchId)
                    }
                }
            }
        } else {
            ForEach(groupedMatches, id: \.date) { entry in
                Section(header: Text(entry.date.formatted(date: .abbreviated, time: .omitted))) {
                    ForEach(entry.matches) { match in
                        matchRowView(match: match, nextMatchId: nextMatchId)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func matchRowView(match: Match, nextMatchId: UUID?) -> some View {
        if isSelectionMode {
            HStack {
                Button {
                    if selectedMatches.contains(match.id) {
                        selectedMatches.remove(match.id)
                    } else {
                        selectedMatches.insert(match.id)
                    }
                } label: {
                    Image(systemName: selectedMatches.contains(match.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedMatches.contains(match.id) ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                        .font(.title3)
                }
                
                MatchRowView(
                    match: match,
                    isNextUp: match.id == nextMatchId,
                    noteCount: scheduleService.noteCount(for: match)
                )
            }
            .listRowBackground(Color.clear)
        } else {
            MatchRowView(
                match: match,
                isNextUp: match.id == nextMatchId,
                noteCount: scheduleService.noteCount(for: match)
            )
            .listRowBackground(Color.clear)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                statusSwipe(for: match)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                addNoteSwipe(for: match)
                editSwipe(for: match)
                deleteSwipe(for: match)
            }
        }
    }
    
    @ViewBuilder
    private func timelineMatchList(nextMatchId: UUID?) -> some View {
        if groupByEvent || (filteredMatches.contains { $0.eventName != nil && !$0.eventName!.isEmpty }) {
            ForEach(groupedMatchesByEvent, id: \.eventName) { eventGroup in
                Section(header: HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text(eventGroup.eventName)
                        .font(.subheadline.weight(.semibold))
                }) {
                    ForEach(eventGroup.matches) { match in
                        timelineMatchRow(match: match, nextMatchId: nextMatchId)
                    }
                }
            }
        } else {
            ForEach(groupedMatches, id: \.date) { entry in
                Section(header: timelineHeader(for: entry.date)) {
                    ForEach(entry.matches) { match in
                        timelineMatchRow(match: match, nextMatchId: nextMatchId)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func timelineMatchRow(match: Match, nextMatchId: UUID?) -> some View {
        if isSelectionMode {
            HStack {
                Button {
                    if selectedMatches.contains(match.id) {
                        selectedMatches.remove(match.id)
                    } else {
                        selectedMatches.insert(match.id)
                    }
                } label: {
                    Image(systemName: selectedMatches.contains(match.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedMatches.contains(match.id) ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                        .font(.title3)
                }
                
                TimelineMatchRow(
                    match: match,
                    isNextUp: match.id == nextMatchId,
                    noteCount: scheduleService.noteCount(for: match),
                    density: density
                )
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        } else {
            TimelineMatchRow(
                match: match,
                isNextUp: match.id == nextMatchId,
                noteCount: scheduleService.noteCount(for: match),
                density: density
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                statusSwipe(for: match)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                addNoteSwipe(for: match)
                editSwipe(for: match)
                deleteSwipe(for: match)
            }
        }
    }
    
    // MARK: - Swipe Helpers
    
    private func statusSwipe(for match: Match) -> some View {
        Group {
            if match.status != .completed {
                Button {
                    Task {
                        do {
                            try await scheduleService.setStatus(.completed, for: match)
                        } catch {
                            alertInfo = AlertMessage(title: "Error", message: error.localizedDescription)
                        }
                    }
                } label: {
                    Label("Mark Complete", systemImage: "checkmark")
                }
                .tint(DesignSystem.Colors.success)
            } else {
                Button {
                    Task {
                        do {
                            try await scheduleService.setStatus(.scheduled, for: match)
                        } catch {
                            alertInfo = AlertMessage(title: "Error", message: error.localizedDescription)
                        }
                    }
                } label: {
                    Label("Reset Status", systemImage: "arrow.uturn.backward")
                }
                .tint(DesignSystem.Colors.warning)
            }
        }
    }
    
    private func editSwipe(for match: Match) -> some View {
        Button {
            matchBeingEdited = match
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(DesignSystem.Colors.accent)
    }
    
    private func addNoteSwipe(for match: Match) -> some View {
        Button {
            quickNoteTarget = match
        } label: {
            Label("Quick Note", systemImage: "note.text.badge.plus")
        }
        .tint(DesignSystem.Colors.primary)
    }
    
    private func deleteSwipe(for match: Match) -> some View {
        Button(role: .destructive) {
            Task {
                do {
                    try await scheduleService.deleteMatch(match)
                } catch {
                    alertInfo = AlertMessage(title: "Error", message: error.localizedDescription)
                }
            }
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Helpers
    
    private var filteredMatches: [Match] {
        var filtered = scheduleService.matches
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { match in
                if match.matchNumber.lowercased().contains(query) { return true }
                if let location = match.location?.lowercased(), location.contains(query) { return true }
                let teamNumbers = [
                    match.alliancePartner1,
                    match.alliancePartner2,
                    match.opponent1,
                    match.opponent2
                ]
                .compactMap { $0 }
                .map { String($0) }
                return teamNumbers.contains(where: { $0.contains(query) })
            }
        }
        
        return filtered.sorted { $0.scheduledTime < $1.scheduledTime }
    }
    
    private var groupedMatches: [(date: Date, matches: [Match])] {
        // Check if any matches have event names - if so, automatically group by event
        let hasEventNames = filteredMatches.contains { $0.eventName != nil && !$0.eventName!.isEmpty }
        let shouldGroupByEvent = groupByEvent || hasEventNames
        
        if shouldGroupByEvent {
            // Group by event name first, then by date within each event
            let eventGroups = Dictionary(grouping: filteredMatches) { match in
                match.eventName ?? "Unnamed Event"
            }
            
            var result: [(date: Date, matches: [Match])] = []
            
            for (eventName, matches) in eventGroups.sorted(by: { $0.key < $1.key }) {
                // Group matches within this event by date
                let dateGroups = Dictionary(grouping: matches) { match in
                    calendar.startOfDay(for: match.scheduledTime)
                }
                
                // Add event header (using first match's date as key)
                let sortedDates = dateGroups.keys.sorted()
                for date in sortedDates {
                    let eventMatches = dateGroups[date]?.sorted { $0.scheduledTime < $1.scheduledTime } ?? []
                    result.append((date: date, matches: eventMatches))
                }
            }
            
            return result.sorted { $0.date < $1.date }
        } else {
            // Original grouping by date only
            let groups = Dictionary(grouping: filteredMatches) { match in
                calendar.startOfDay(for: match.scheduledTime)
            }
            
            return groups
                .map { (date: $0.key, matches: $0.value.sorted { $0.scheduledTime < $1.scheduledTime }) }
                .sorted { $0.date < $1.date }
        }
    }
    
    private var groupedMatchesByEvent: [(eventName: String, matches: [Match])] {
        let groups = Dictionary(grouping: filteredMatches) { match in
            match.eventName ?? "Unnamed Event"
        }
        
        return groups
            .map { (eventName: $0.key, matches: $0.value.sorted { $0.scheduledTime < $1.scheduledTime }) }
            .sorted { $0.eventName < $1.eventName }
    }
    
    private func timelineHeader(for date: Date) -> some View {
        HStack {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
            Text(relativeDayString(for: date))
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
    
    private func relativeDayString(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }
    
}

// MARK: - Supporting Types & Views

private struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}


enum ScheduleLayoutMode: String, CaseIterable, Identifiable {
    case grouped
    case timeline
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .grouped: return "List"
        case .timeline: return "Timeline"
        }
    }
}

enum ScheduleDensity: String, CaseIterable, Identifiable {
    case compact
    case comfort
    case detail
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .compact: return "Compact"
        case .comfort: return "Cozy"
        case .detail: return "Detailed"
        }
    }
    
    var cardSpacing: CGFloat {
        switch self {
        case .compact: return DesignSystem.Spacing.sm
        case .comfort: return DesignSystem.Spacing.md
        case .detail: return DesignSystem.Spacing.md
        }
    }
    
    var cardPadding: CGFloat {
        switch self {
        case .compact: return DesignSystem.Spacing.md
        case .comfort: return DesignSystem.Spacing.md
        case .detail: return DesignSystem.Spacing.lg
        }
    }
    
    var showsAllianceDetail: Bool {
        self != .compact
    }
    
    var showsScoreSummary: Bool {
        self == .detail
    }
}

private struct InfoBanner: View {
    let icon: String
    let tint: Color
    let title: String
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(tint)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardElevation(.modal)
        .springyAppear(using: DesignSystem.Motion.standard)
    }
}

struct MatchRowView: View {
    enum Style {
        case list
        case timeline
    }
    
    let match: Match
    let isNextUp: Bool
    let noteCount: Int
    var style: Style = .list
    var density: ScheduleDensity = .detail
    
    private var allianceAccent: Color {
        match.allianceColor == .red ? .red : .blue
    }
    
    private var opponents: [String] {
        [match.opponent1, match.opponent2]
            .compactMap { $0 }
            .map { "Team \($0)" }
    }
    
    private var partners: [String] {
        [match.alliancePartner1, match.alliancePartner2]
            .compactMap { $0 }
            .map { "Team \($0)" }
    }
    
    private var showsAllianceBreakdown: Bool {
        style == .list || density.showsAllianceDetail
    }
    
    private var showsScores: Bool {
        style == .list || density.showsScoreSummary
    }
    
    private var contentSpacing: CGFloat {
        style == .list ? DesignSystem.Spacing.md : density.cardSpacing
    }
    
    private var paddingInsets: CGFloat {
        style == .list ? DesignSystem.Spacing.lg : density.cardPadding
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            header
            
            if showsAllianceBreakdown {
                allianceSection
            }
            
            if showsScores, match.ourScore != nil || match.opponentScore != nil {
                scoreSection
            }
            
            footer
        }
        .padding(paddingInsets)
        .cardElevation(style == .list ? .raised : .surface)
        .springyAppear(using: DesignSystem.Motion.spring(response: 0.55, dampingFraction: 0.82))
    }
    
    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Match \(match.matchNumber)")
                    .font(style == .list ? .headline : .subheadline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .fontWeight(.semibold)
                
                if style == .timeline {
                    Text(match.scheduledTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            StatusBadge(status: match.status)
                .scaleEffect(style == .timeline ? 0.9 : 1)
            
            if isNextUp {
                Label("Next Up", systemImage: "bolt.fill")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.success.opacity(0.15))
                    .foregroundColor(DesignSystem.Colors.success)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            if style == .list {
                Text(match.scheduledTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    private var allianceSection: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
            AllianceColumn(
                title: "\(match.allianceColor.displayName) Alliance",
                teams: partners,
                accent: allianceAccent
            )
            
            Spacer(minLength: DesignSystem.Spacing.md)
            
            AllianceColumn(
                title: "Opponents",
                teams: opponents,
                accent: DesignSystem.Colors.textSecondary
            )
        }
    }
    
    private var scoreSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Divider()
                .padding(.vertical, DesignSystem.Spacing.xs)
            HStack {
                LabeledContent("Our Score") {
                    Text(match.ourScore?.description ?? "—")
                        .font(.title3.monospacedDigit())
                        .fontWeight(.semibold)
                }
                Spacer()
                LabeledContent("Opponent") {
                    Text(match.opponentScore?.description ?? "—")
                        .font(.title3.monospacedDigit())
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var footer: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Label(
                    match.scheduledTime.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                
                if let location = match.location, !location.isEmpty {
                    Label(location, systemImage: "location")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            if noteCount > 0 {
                Label("\(noteCount) quick note\(noteCount == 1 ? "" : "s")", systemImage: "note.text")
                    .font(.caption.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.accent)
                    .transition(.opacity)
            }
        }
    }
}

private struct TimelineMatchRow: View {
    let match: Match
    let isNextUp: Bool
    let noteCount: Int
    let density: ScheduleDensity
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            TimelineAxis(isHighlighted: isNextUp)
                .padding(.top, 4)
            MatchRowView(
                match: match,
                isNextUp: isNextUp,
                noteCount: noteCount,
                style: .timeline,
                density: density
            )
        }
        .padding(.vertical, density == .compact ? DesignSystem.Spacing.xs : DesignSystem.Spacing.sm)
    }
}

private struct TimelineAxis: View {
    let isHighlighted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isHighlighted ? DesignSystem.Colors.accent : DesignSystem.Colors.border)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(DesignSystem.Colors.accent.opacity(isHighlighted ? 0.3 : 0.0), lineWidth: 6)
                )
                .animation(.easeInOut(duration: 0.3), value: isHighlighted)
            Rectangle()
                .fill(DesignSystem.Colors.border.opacity(0.6))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
        .frame(width: 18)
    }
}

private struct QuickNoteComposer: View {
    @EnvironmentObject var scheduleService: ScheduleService
    @Environment(\.dismiss) private var dismiss
    let match: Match
    @State private var text: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Match \(match.matchNumber)").textCase(.none)) {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .frame(minHeight: 140)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                        if text.isEmpty {
                            Text("Capture a quick observation, reminder, or pit note…")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .padding(.top, 8)
                                .padding(.horizontal, 4)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background)
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.actionClose) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        DesignSystem.Haptics.selection()
                        scheduleService.addQuickNote(text, to: match)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            text = ""
        }
    }
}

private struct MatchDaySummary: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let count: Int
}

private struct SummaryChipRow: View {
    let matches: Int
    let format: String
    let warningsCount: Int
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.md) {
                StatChip(icon: "list.number", headline: "\(matches)", detail: "Matches", tint: DesignSystem.Colors.primary)
                StatChip(icon: "doc.text", headline: format, detail: "Format", tint: DesignSystem.Colors.secondary)
                StatChip(icon: warningsCount == 0 ? "checkmark.seal" : "exclamationmark.triangle", headline: warningsCount == 0 ? "Clean" : "\(warningsCount)", detail: warningsCount == 0 ? "No warnings" : "Warnings", tint: warningsCount == 0 ? DesignSystem.Colors.success : DesignSystem.Colors.warning)
            }
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }
}

private struct StatChip: View {
    let icon: String
    let headline: String
    let detail: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
}

private struct WarningChipGroup: View {
    let warnings: [String]
    
    var body: some View {
        if warnings.isEmpty {
            InfoChip(icon: "checkmark.seal.fill", message: L10n.Importer.warningsNone, tint: DesignSystem.Colors.success)
        } else {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                ForEach(warnings, id: \.self) { warning in
                    WarningChip(text: warning)
                }
            }
        }
    }
}

private struct WarningChip: View {
    let text: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold))
            Text(text)
                .font(.caption)
                .multilineTextAlignment(.leading)
        }
        .foregroundColor(DesignSystem.Colors.warning)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.warning.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
}

private struct InfoChip: View {
    let icon: String
    let message: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(message)
                .font(.caption)
        }
        .foregroundColor(tint)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(tint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }
}

private struct SparklineCard: View {
    let data: [MatchDaySummary]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Match Distribution")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Chart(data) { item in
                LineMark(
                    x: .value("Day", item.date),
                    y: .value("Matches", item.count)
                )
                .foregroundStyle(DesignSystem.Colors.primary)
                AreaMark(
                    x: .value("Day", item.date),
                    y: .value("Matches", item.count)
                )
                .foregroundStyle(DesignSystem.Colors.primary.opacity(0.15))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 80)
        }
        .padding(DesignSystem.Spacing.md)
        .cardElevation(.surface)
    }
}

private struct AllianceColumn: View {
    let title: String
    let teams: [String]
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(accent)
            
            if teams.isEmpty {
                Text("Pending")
                    .font(.footnote)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            } else {
                ForEach(teams, id: \.self) { team in
                    Text(team)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StatusBadge: View {
    let status: MatchStatus
    
    private var tint: Color {
        switch status {
        case .scheduled: return DesignSystem.Colors.secondary
        case .inProgress: return DesignSystem.Colors.accent
        case .completed: return DesignSystem.Colors.success
        case .forfeited: return DesignSystem.Colors.error
        }
    }
    
    var body: some View {
        Text(status.displayName.uppercased())
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .foregroundColor(tint)
            .clipShape(Capsule())
    }
}

// MARK: - Match Editor

// MARK: - Match Row Data
struct MatchRowData: Identifiable {
    let id = UUID()
    var matchNumber: String = "" // Auto-generated based on position
    var time: String = ""
    var redTeam1: String = ""
    var redTeam2: String = ""
    var blueTeam1: String = ""
    var blueTeam2: String = ""
}

struct MatchEditorView: View {
    enum Mode {
        case create(defaultDate: Date?)
        case edit(Match)
    }
    
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var teamService: TeamService
    @Environment(\.dismiss) private var dismiss
    
    private let mode: Mode
    
    // Multiple rows support
    @State private var matchRows: [MatchRowData] = [MatchRowData()]
    @State private var defaultDate: Date
    @State private var allianceColor: AllianceColor = .red
    
    @State private var isSaving = false
    
    init(mode: Mode) {
        self.mode = mode
        
        switch mode {
        case .create(let defaultDate):
            _defaultDate = State(initialValue: defaultDate ?? Date())
            _matchRows = State(initialValue: [MatchRowData()])
        case .edit(let match):
            _defaultDate = State(initialValue: match.scheduledTime)
            _allianceColor = State(initialValue: match.allianceColor)
            // Convert single match to row data
            var row = MatchRowData()
            row.matchNumber = match.matchNumber
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            row.time = formatter.string(from: match.scheduledTime)
            if match.allianceColor == .red {
                row.redTeam1 = match.alliancePartner1.map(String.init) ?? ""
                row.redTeam2 = match.alliancePartner2.map(String.init) ?? ""
                row.blueTeam1 = match.opponent1.map(String.init) ?? ""
                row.blueTeam2 = match.opponent2.map(String.init) ?? ""
            } else {
                row.blueTeam1 = match.alliancePartner1.map(String.init) ?? ""
                row.blueTeam2 = match.alliancePartner2.map(String.init) ?? ""
                row.redTeam1 = match.opponent1.map(String.init) ?? ""
                row.redTeam2 = match.opponent2.map(String.init) ?? ""
            }
            _matchRows = State(initialValue: [row])
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Compact Schedule Table
                    VStack(spacing: 0) {
                        // Table Header
                        HStack(spacing: 6) {
                            // Move arrows column header
                            Color.clear
                                .frame(width: 35)
                            
                            Text("Red 1")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                            
                            Text("Red 2")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                            
                            Text("Blue 1")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                            
                            Text("Blue 2")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                            
                            // Delete column header (spacer)
                            Color.clear
                                .frame(width: 25)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        
                        Divider()
                        
                        // Table Rows
                        ForEach(Array(matchRows.enumerated()), id: \.element.id) { index, row in
                            MatchTableRow(
                                row: Binding(
                                    get: { matchRows[index] },
                                    set: { matchRows[index] = $0 }
                                ),
                                matchNumber: "Q\(index + 1)",
                                canMoveUp: index > 0,
                                canMoveDown: index < matchRows.count - 1,
                                onMoveUp: {
                                    guard index > 0 else { return }
                                    matchRows.swapAt(index, index - 1)
                                    updateMatchNumbers()
                                },
                                onMoveDown: {
                                    guard index < matchRows.count - 1 else { return }
                                    matchRows.swapAt(index, index + 1)
                                    updateMatchNumbers()
                                },
                                onDelete: {
                                    if matchRows.count > 1 {
                                        matchRows.removeAll { $0.id == row.id }
                                        updateMatchNumbers()
                                    }
                                }
                            )
                            Divider()
                        }
                    }
                        .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Add Row Button
                            Button {
                        matchRows.append(MatchRowData())
                        updateMatchNumbers()
                            } label: {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text("Add Row")
                                .fontWeight(.semibold)
                            Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                }
                        .font(.system(size: 14))
                        .foregroundColor(DesignSystem.Colors.primary)
                                .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.primary.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                            }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                            
                    // Save All Matches Button
                            Button {
                        saveAllMatches()
                            } label: {
                                HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(mode.title.contains("Edit") ? "Save Match" : "Save All Matches")
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Gradients.primary)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 6, x: 0, y: 3)
                            }
                    .disabled(!hasValidRows || isSaving)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle(mode.title)
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                updateMatchNumbers()
            }
        }
    }
    
    // MARK: - Match Table Row View
    private struct MatchTableRow: View {
        @Binding var row: MatchRowData
        let matchNumber: String
        let canMoveUp: Bool
        let canMoveDown: Bool
        let onMoveUp: () -> Void
        let onMoveDown: () -> Void
        let onDelete: () -> Void
        
        var body: some View {
            HStack(spacing: 6) {
                // Move arrows
                VStack(spacing: 4) {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(canMoveUp ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                            .frame(width: 20, height: 18)
                    }
                    .disabled(!canMoveUp)
                    
                    // Match number display (read-only)
                    Text(matchNumber)
                        .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(width: 25)
                    
                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(canMoveDown ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                            .frame(width: 20, height: 18)
                    }
                    .disabled(!canMoveDown)
                }
                .frame(width: 35)
                
                // Red 1 - larger
                TextField("12345", text: $row.redTeam1)
                                .keyboardType(.numberPad)
                            .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignSystem.Colors.tertiaryBackground.opacity(0.5))
                    .cornerRadius(4)
                
                // Red 2 - larger
                TextField("12345", text: $row.redTeam2)
                                .keyboardType(.numberPad)
                            .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignSystem.Colors.tertiaryBackground.opacity(0.5))
                    .cornerRadius(4)
                
                // Blue 1 - larger
                TextField("12345", text: $row.blueTeam1)
                                    .keyboardType(.numberPad)
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignSystem.Colors.tertiaryBackground.opacity(0.5))
                    .cornerRadius(4)
                
                // Blue 2 - larger
                TextField("12345", text: $row.blueTeam2)
                                    .keyboardType(.numberPad)
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignSystem.Colors.tertiaryBackground.opacity(0.5))
                    .cornerRadius(4)
                
                // Delete Button - closer to edge
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(DesignSystem.Colors.error)
                        .frame(width: 25)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cardBackground)
        }
    }
    
    // Update match numbers based on row positions
    private func updateMatchNumbers() {
        for index in matchRows.indices {
            matchRows[index].matchNumber = "Q\(index + 1)"
        }
    }
    
    private var hasValidRows: Bool {
        matchRows.contains { !$0.matchNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func parseTime(_ timeString: String, baseDate: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: baseDate)
    }
        return nil
    }
    
    private func saveAllMatches() {
        guard hasValidRows else { return }
        
        // Check if team context is available
        guard scheduleService.hasTeamContext else {
            scheduleService.errorMessage = "You must be part of a team to create matches. Please join or create a team first."
            return
        }
        
        isSaving = true
        
        Task {
            defer { isSaving = false }
            
            do {
                // Save all valid rows
                for row in matchRows {
                    let matchNumber = row.matchNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !matchNumber.isEmpty else { continue }
                    
                    // Parse time or use default date
                    let scheduledTime = parseTime(row.time, baseDate: defaultDate) ?? defaultDate
                    
                    // Map table format to partner/opponent format based on alliance color
                    let (partner1Value, partner2Value, opponent1Value, opponent2Value): (Int?, Int?, Int?, Int?)
                    if allianceColor == .red {
                        partner1Value = Int(row.redTeam1)
                        partner2Value = Int(row.redTeam2)
                        opponent1Value = Int(row.blueTeam1)
                        opponent2Value = Int(row.blueTeam2)
                    } else {
                        partner1Value = Int(row.blueTeam1)
                        partner2Value = Int(row.blueTeam2)
                        opponent1Value = Int(row.redTeam1)
                        opponent2Value = Int(row.redTeam2)
                    }
                    
                    let draft = MatchDraft(
                        matchNumber: matchNumber,
                        scheduledTime: scheduledTime,
                        allianceColor: allianceColor,
                        alliancePartner1: partner1Value,
                        alliancePartner2: partner2Value,
                        opponent1: opponent1Value,
                        opponent2: opponent2Value,
                        status: .scheduled,
                        ourScore: nil,
                        opponentScore: nil,
                        location: nil
                    )
                    
                switch mode {
                case .create:
                    try await scheduleService.createMatch(from: draft)
                    case .edit(let existingMatch):
                        // For edit mode, only update the first match, create others
                        if row.id == matchRows.first?.id {
                            try await scheduleService.updateMatch(existingMatch, with: draft)
                        } else {
                            try await scheduleService.createMatch(from: draft)
                        }
                    }
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    let errorMessage: String
                    if let scheduleError = error as? ScheduleError {
                        errorMessage = scheduleError.errorDescription ?? "Failed to save matches. Please try again."
                    } else {
                        errorMessage = "Failed to save matches: \(error.localizedDescription)"
                    }
                    scheduleService.errorMessage = errorMessage
                }
            }
        }
    }
}

private extension MatchEditorView.Mode {
    var title: String {
        switch self {
        case .create:
            return "New Match"
        case .edit:
            return "Edit Match"
        }
    }
}

// MARK: - Import View

struct ImportScheduleView: View {
    @EnvironmentObject var scheduleService: ScheduleService
    @Environment(\.dismiss) private var dismiss
    
    @State private var eventName: String = ""
    @State private var isImporting = false
    @State private var showingFileImporter = false
    @State private var preview: ScheduleService.MatchImportPreview?
    @State private var previewData: Data?
    @State private var previewError: String?
    @State private var showImportConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event") {
                    TextField(L10n.Importer.eventPlaceholder, text: $eventName)
                }
                .listRowBackground(DesignSystem.Colors.cardBackground)
                
                Section("Schedule File") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text(L10n.Importer.supportedFormatsTitle)
                            .font(.headline)
                        
                        Text(L10n.Importer.supportedFormatsSubtitle)
                            .font(.footnote)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Button {
                            showingFileImporter = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text(isImporting ? L10n.Importer.buttonImporting : (previewData == nil ? L10n.Importer.buttonChooseFile : L10n.Importer.buttonChooseDifferent))
                            }
                        }
                        .disabled(isImporting)
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                }
                .listRowBackground(DesignSystem.Colors.cardBackground)
                
                if let preview = preview {
                    Section {
                        SummaryChipRow(matches: preview.drafts.count, format: preview.format.rawValue, warningsCount: preview.warnings.count)
                        if !sparklineData(for: preview).isEmpty {
                            SparklineCard(data: sparklineData(for: preview))
                                .padding(.top, DesignSystem.Spacing.sm)
                        }
                        WarningChipGroup(warnings: preview.warnings)
                    } header: {
                        Text(L10n.Importer.summaryTitle)
                            .textCase(.none)
                    }
                    .listRowBackground(DesignSystem.Colors.cardBackground)
                    
                    Section {
                        let sample = Array(preview.drafts.prefix(10).enumerated())
                        ForEach(sample, id: \.offset) { index, draft in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Match \(draft.matchNumber)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(draft.scheduledTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Alliance: \(draft.allianceColor.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if preview.drafts.count > 10 {
                            Text(String(format: L10n.Importer.previewMoreMatches, preview.drafts.count - 10))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text(L10n.Importer.previewTitle)
                            .textCase(.none)
                    }
                    .listRowBackground(DesignSystem.Colors.cardBackground)
                    
                    Section {
                        if preview.warnings.isEmpty {
                            Label(L10n.Importer.validationReady, systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            ForEach(preview.warnings, id: \.self) { warning in
                                Label("\(L10n.Importer.validationIssue): \(warning)", systemImage: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    } header: {
                        Text(L10n.Importer.validationTitle)
                            .textCase(.none)
                    }
                    .listRowBackground(DesignSystem.Colors.cardBackground)
                }
                
                if let error = previewError {
                    Section {
                        Label(String(format: L10n.Importer.previewFailed, error), systemImage: "xmark.octagon.fill")
                            .foregroundColor(.red)
                    }
                    .listRowBackground(DesignSystem.Colors.cardBackground)
                }
                
                if case .importing = scheduleService.importStatus {
                    Section {
                        HStack {
                            ProgressView()
                            Text(L10n.Importer.statusProgress)
                        }
                    }
                    .listRowBackground(DesignSystem.Colors.cardBackground)
                } else {
                    Section {
                        Button {
                            showImportConfirmation = true
                        } label: {
                            Text(L10n.Importer.importButton)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled(previewData == nil || isImporting)
                    }
                    .listRowBackground(DesignSystem.Colors.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.background)
            .navigationTitle(L10n.Importer.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.actionClose) { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [
                    .json,
                    .commaSeparatedText,
                    .plainText
                ]
            ) { result in
                switch result {
                case .success(let url):
                    Task {
                        do {
                            previewData = try Data(contentsOf: url)
                            preview = try scheduleService.previewSchedule(from: previewData!)
                            previewError = nil
                        } catch {
                            previewData = nil
                            preview = nil
                            previewError = error.localizedDescription
                            scheduleService.errorMessage = error.localizedDescription
                        }
                    }
                case .failure(let error):
                    scheduleService.errorMessage = error.localizedDescription
                }
            }
            .onAppear {
                scheduleService.resetImportStatus()
            }
            .onDisappear {
                scheduleService.resetImportStatus()
            }
            .alert(L10n.Importer.confirmTitle, isPresented: $showImportConfirmation) {
                Button(L10n.Importer.confirmPositive, role: .destructive) {
                    Task {
                        await performImport()
                    }
                }
                Button(L10n.Importer.confirmNegative, role: .cancel) {
                    showImportConfirmation = false
                }
            } message: {
                Text(importSummaryMessage)
            }
        }
    }
    
    private var importSummaryMessage: String {
        guard let preview = preview else {
            return L10n.Importer.noFileSelected
        }
        let count = preview.drafts.count
        let warningCount = preview.warnings.count
        if warningCount > 0 {
            return String(format: L10n.Importer.confirmMessageWithWarnings, count, warningCount)
        } else {
            return String(format: L10n.Importer.confirmMessage, count)
        }
    }
    
    private func performImport() async {
        guard let data = previewData else { return }
        isImporting = true
        await scheduleService.importSchedule(from: data, eventName: eventName)
        isImporting = false
        showImportConfirmation = false
        if case .success = scheduleService.importStatus {
            dismiss()
        }
    }
    
    private func sparklineData(for preview: ScheduleService.MatchImportPreview) -> [MatchDaySummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: preview.drafts) { draft in
            calendar.startOfDay(for: draft.scheduledTime)
        }
        return grouped
            .map { MatchDaySummary(date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }
}

