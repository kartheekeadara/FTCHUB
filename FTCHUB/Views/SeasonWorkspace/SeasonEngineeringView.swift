//
//  SeasonEngineeringView.swift
//  FTCHUB
//
//  Season workspace destination: Engineering notebook and run log with FTC-aligned guidance.
//

import SwiftUI
import UIKit

struct SeasonEngineeringView: View {
    var embedsNavigationStack: Bool = true
    
    @EnvironmentObject var session: SeasonWorkspaceSession
    @EnvironmentObject var teamService: TeamService
    @State private var selectedTab = 0
    @State private var notebookSearchText = ""
    @State private var showRubricSheet = false
    @State private var showTOCSheet = false
    @State private var shareExportPayload: ShareExportPayload?
    @State private var exportErrorMessage: String?
    
    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack {
                    engineeringContent
                }
            } else {
                engineeringContent
            }
        }
    }
    
    private var engineeringContent: some View {
        engineeringRoot
            .background(NotebookPalette.background.ignoresSafeArea())
            .ftchubRootNavHeader(title: "Engineering Notebook")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if selectedTab == 0 {
                        Menu {
                            Button {
                                TelemetryService.shared.logEvent("engineering_notebook_toc_opened")
                                showTOCSheet = true
                            } label: {
                                Label("Table of contents", systemImage: "list.bullet")
                            }
                            Button {
                                TelemetryService.shared.logEvent("engineering_notebook_rubric_opened")
                                showRubricSheet = true
                            } label: {
                                Label("Rubric self-check", systemImage: "checklist")
                            }
                            Divider()
                            Button {
                                exportNotebookPDF()
                            } label: {
                                Label("Export PDF", systemImage: "doc.richtext")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showRubricSheet) {
                EngineeringRubricSheet(store: session.notebookStore)
            }
            .sheet(isPresented: $showTOCSheet) {
                EngineeringTOCSheet(store: session.notebookStore)
            }
            .sheet(item: $shareExportPayload) { payload in
                ActivityView(activityItems: payload.items)
            }
            .alert("Export failed", isPresented: Binding(
                get: { exportErrorMessage != nil },
                set: { if !$0 { exportErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { exportErrorMessage = nil }
            } message: {
                Text(exportErrorMessage ?? "Unable to create export file.")
            }
    }
    
    private func exportNotebookPDF() {
        guard let data = EngineeringNotebookExport.pdfData(
            teamNumber: teamService.currentTeam?.number,
            notes: session.notebookStore.notes,
            runs: session.notebookStore.runs
        ) else {
            exportErrorMessage = "Could not generate PDF. Please try again."
            return
        }

        let rawTeamNumber = teamService.currentTeam?.number ?? ""
        let teamSlug = rawTeamNumber
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
        let safeTeamSlug = teamSlug.isEmpty ? "team" : teamSlug
        let dateStamp = Date().formatted(.dateTime.year().month().day())
        let fileName = "FTCHUB-\(safeTeamSlug)-engineering-notebook-\(dateStamp).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            TelemetryService.shared.logEvent("engineering_notebook_export_pdf")
            shareExportPayload = ShareExportPayload(items: [url])
        } catch {
            TelemetryService.shared.logError(error, context: ["where": "engineering_notebook_pdf"])
            exportErrorMessage = error.localizedDescription
        }
    }
    
    private var engineeringRoot: some View {
        Group {
            if selectedTab == 0 {
                EngineeringNotebookTab(
                    store: session.notebookStore,
                    selectedTab: $selectedTab,
                    searchText: $notebookSearchText
                )
            } else {
                EngineeringRunLogScrollTab(
                    store: session.notebookStore,
                    selectedTab: $selectedTab
                )
            }
        }
    }
}

// MARK: - Palette

enum NotebookPalette {
    static let background = Color.black
    static let cardSurface = Color(red: 0.11, green: 0.11, blue: 0.12)   // #1C1C1E
    static let chipInactive = Color(red: 0.17, green: 0.17, blue: 0.18) // #2C2C2E
    static let stroke = Color(red: 0.23, green: 0.23, blue: 0.24)       // #3A3A3C
    static let textSecondary = Color(red: 0.56, green: 0.56, blue: 0.58)
    static let textTertiary = Color(red: 0.45, green: 0.45, blue: 0.45)
    static let accent = Color(red: 0.91, green: 0.64, blue: 0.35)       // #E8A45A
    static let pass = Color(red: 0.19, green: 0.82, blue: 0.35)         // #30D158
    static let fail = Color(red: 1.0, green: 0.27, blue: 0.23)          // #FF453A
    
    static func color(for kind: EngineeringNoteKind) -> Color {
        switch kind {
        case .designDecision: return Color(red: 0.91, green: 0.64, blue: 0.35) // #E8A45A
        case .testSession:    return Color(red: 0.36, green: 0.61, blue: 0.84) // #5B9BD5
        case .bug:            return Color(red: 0.88, green: 0.36, blue: 0.36) // #E05C5C
        case .meeting:        return Color(red: 0.61, green: 0.45, blue: 0.82) // #9B72D0
        case .other:          return Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
        }
    }
}

// MARK: - Sticky header components

private struct NotebookSegmentControl: View {
    @Binding var selected: Int
    
    var body: some View {
        HStack(spacing: 4) {
            segment(title: "Notebook", index: 0)
            segment(title: "Run log", index: 1)
        }
        .padding(4)
        .background(NotebookPalette.chipInactive)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func segment(title: String, index: Int) -> some View {
        let active = selected == index
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selected = index
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(active ? .white : NotebookPalette.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(active ? NotebookPalette.accent : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct NotebookSearchField: View {
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(NotebookPalette.textSecondary)
            TextField("Search notes…", text: $text)
                .foregroundColor(.white)
                .textInputAutocapitalization(.sentences)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(NotebookPalette.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(NotebookPalette.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct EngineeringRunLogScrollTab: View {
    @ObservedObject var store: EngineeringNotebookStore
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                NotebookSegmentControl(selected: $selectedTab)
                
                RunLogTab(store: store)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
    }
}

// MARK: - Notebook tab

private struct EngineeringNotebookTab: View {
    @ObservedObject var store: EngineeringNotebookStore
    @Binding var selectedTab: Int
    @Binding var searchText: String
    @State private var showAddSheet = false
    @State private var showPlaybook = false
    
    private var filteredNotes: [EngineeringNote] {
        var notes = store.notes
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            notes = notes.filter {
                $0.title.lowercased().contains(query) ||
                $0.body.lowercased().contains(query) ||
                ($0.subsystem ?? "").lowercased().contains(query) ||
                ($0.authorStudent ?? "").lowercased().contains(query) ||
                ($0.attachmentsNote ?? "").lowercased().contains(query) ||
                ($0.designPhase?.displayName ?? "").lowercased().contains(query)
            }
        }
        return notes
    }
    
    private var highlightNotes: [EngineeringNote] {
        Array(filteredNotes.sorted { $0.createdAt > $1.createdAt }.prefix(3))
    }
    
    private var dayGroups: [(day: Date, notes: [EngineeringNote])] {
        let cal = Calendar.current
        var buckets: [Date: [EngineeringNote]] = [:]
        for note in filteredNotes {
            let d = cal.startOfDay(for: note.createdAt)
            buckets[d, default: []].append(note)
        }
        return buckets.keys.sorted(by: >).map { day in
            let sorted = (buckets[day] ?? []).sorted { $0.createdAt > $1.createdAt }
            return (day, sorted)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                NotebookSegmentControl(selected: $selectedTab)
                
                NotebookSearchField(text: $searchText)
                
                NotebookDashboardHeroCard()
                
                NotebookHighlightsCard(notes: highlightNotes, store: store)
                
                NotebookNewEntryButton(showAddSheet: $showAddSheet)
                
                notebookEntriesCard
                
                playbookSection
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.xl)
        }
        .sheet(isPresented: $showAddSheet) {
            AddEngineeringNoteSheet(store: store, initialKind: .designDecision)
        }
    }
    
    private var notebookEntriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("All Entries")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
                Text("\(filteredNotes.count) shown")
                    .font(.system(size: 13))
                    .foregroundColor(NotebookPalette.textSecondary)
            }
            
            if filteredNotes.isEmpty {
                Group {
                    if store.notes.isEmpty {
                        notebookEmptyNoNotesView
                    } else {
                        notebookEmptyNoMatchView
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.lg)
                .background(NotebookPalette.cardSurface)
                .cornerRadius(12)
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(dayGroups.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(daySectionTitle(group.day))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(NotebookPalette.textSecondary)
                                .textCase(.uppercase)
                                .tracking(0.4)
                                .padding(.top, 8)
                            
                            ForEach(group.notes) { note in
                                NavigationLink {
                                    EngineeringNoteDetailView(note: note, store: store)
                                } label: {
                                    NotebookEntryCard(note: note)
                                }
                                .buttonStyle(.plain)
                                
                                if note.id != group.notes.last?.id {
                                    Divider()
                                        .background(NotebookPalette.stroke.opacity(0.5))
                                        .padding(.leading, 52)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func daySectionTitle(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var notebookEmptyNoNotesView: some View {
        VStack(spacing: 12) {
            Text("No entries yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("Tap New Entry to log your first note.")
                .font(.system(size: 13))
                .foregroundColor(NotebookPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.lg)
    }
    
    private var notebookEmptyNoMatchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(NotebookPalette.stroke)
            Text("No entries match")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text("Clear search or add a new entry.")
                .font(.system(size: 13))
                .foregroundColor(NotebookPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.lg)
    }
    
    private var playbookSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showPlaybook.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(NotebookPalette.accent)
                    Text("What Judges Look For")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: showPlaybook ? "chevron.up" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(NotebookPalette.textSecondary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            if showPlaybook {
                VStack(alignment: .leading, spacing: 12) {
                    playbookItem(
                        title: "Full design cycle",
                        detail: "Problem → brainstorm → select → build → test → iterate. Document all stages."
                    )
                    playbookItem(
                        title: "Failures and pivots",
                        detail: "What didn't work is as valuable as what did. Note why you changed direction."
                    )
                    playbookItem(
                        title: "Student-written entries",
                        detail: "Judges look for student voice. Mentors guide but students document."
                    )
                    playbookItem(
                        title: "Testable hypotheses",
                        detail: "\"If we lower intake speed by 20%, we expect fewer jams.\""
                    )
                    
                    Divider().background(NotebookPalette.stroke).padding(.vertical, 4)
                    
                    HStack(spacing: 16) {
                        Link(destination: URL(string: "https://www.firstinspires.org/sites/default/files/uploads/resource_library/ftc/eng-notebook-self-assessment.pdf")!) {
                            Label("FIRST notebook guide", systemImage: "doc.text")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Link(destination: URL(string: "https://www.firstinspires.org/robotics/ftc/game-and-season")!) {
                            Label("Game manual", systemImage: "book")
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(NotebookPalette.cardSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(showPlaybook ? NotebookPalette.accent : Color.clear, lineWidth: showPlaybook ? 1 : 0)
        )
    }
    
    private func playbookItem(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.82, green: 0.82, blue: 0.84))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.82, green: 0.82, blue: 0.84))
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.82, green: 0.82, blue: 0.84))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Radial hero

private struct EngineeringNotebookHeroImage: View {
    var maxHeight: CGFloat = 180
    
    var body: some View {
        Image("EngineeringNotebookHero")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: maxHeight)
            .accessibilityHidden(true)
    }
}

private struct NotebookDashboardHeroCard: View {
    var body: some View {
        EngineeringNotebookHeroImage(maxHeight: 220)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Ranked highlights

private struct NotebookHighlightsCard: View {
    let notes: [EngineeringNote]
    @ObservedObject var store: EngineeringNotebookStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notebook Highlights")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(NotebookPalette.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    if index < notes.count {
                        NavigationLink {
                            EngineeringNoteDetailView(note: notes[index], store: store)
                        } label: {
                            NotebookHighlightRow(rank: index + 1, note: notes[index])
                        }
                        .buttonStyle(.plain)
                    } else {
                        NotebookHighlightEmptyRow(rank: index + 1, isFirst: index == 0 && notes.isEmpty)
                    }
                    
                    if index < 2 {
                        Divider()
                            .background(NotebookPalette.chipInactive)
                            .padding(.leading, 16)
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .background(NotebookPalette.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct NotebookHighlightRow: View {
    let rank: Int
    let note: EngineeringNote
    
    private var initials: String {
        let s = (note.authorStudent ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return "" }
        let parts = s.split(separator: " ")
        if parts.count >= 2 {
            let a = parts[0].first.map(String.init) ?? ""
            let b = parts[1].first.map(String.init) ?? ""
            return (a + b).uppercased()
        }
        return String(s.prefix(2)).uppercased()
    }
    
    private var relativeTime: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: note.createdAt, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NotebookPalette.textTertiary)
                .frame(width: 28, alignment: .leading)
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(NotebookPalette.color(for: note.entryKind).opacity(0.18))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: note.entryKind.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(note.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(note.entryKind.shortName) · \(relativeTime)")
                    .font(.system(size: 13))
                    .foregroundColor(NotebookPalette.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            if !initials.isEmpty {
                Text(initials)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(NotebookPalette.stroke))
            } else {
                Text("—")
                    .font(.system(size: 13))
                    .foregroundColor(NotebookPalette.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

private struct NotebookHighlightEmptyRow: View {
    let rank: Int
    let isFirst: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NotebookPalette.textTertiary)
                .frame(width: 28, alignment: .leading)
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    NotebookPalette.stroke,
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
                .frame(width: 56, height: 56)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(isFirst ? "Add your first entry" : "·····")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isFirst ? Color(red: 0.82, green: 0.82, blue: 0.84) : NotebookPalette.textTertiary)
                    .lineLimit(1)
                Text(isFirst ? "Tap + New Entry below" : "·····")
                    .font(.system(size: 13))
                    .foregroundColor(NotebookPalette.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            Text("—")
                .font(.system(size: 13))
                .foregroundColor(NotebookPalette.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Entry card

private struct NotebookEntryCard: View {
    let note: EngineeringNote
    
    private var initials: String {
        let s = (note.authorStudent ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return "?" }
        let parts = s.split(separator: " ")
        if parts.count >= 2 {
            let a = parts[0].first.map(String.init) ?? ""
            let b = parts[1].first.map(String.init) ?? ""
            return (a + b).uppercased()
        }
        return String(s.prefix(2)).uppercased()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(NotebookPalette.color(for: note.entryKind).opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: note.entryKind.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(NotebookPalette.color(for: note.entryKind))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(note.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(note.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(NotebookPalette.textTertiary)
                }
                
                HStack(spacing: 8) {
                    Text(note.entryKind.shortName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(NotebookPalette.color(for: note.entryKind))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(NotebookPalette.color(for: note.entryKind).opacity(0.15))
                        )
                    
                    if let a = note.authorStudent, !a.isEmpty {
                        Text(initials)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(NotebookPalette.stroke))
                    }
                }
                
                if !note.body.isEmpty {
                    Text(note.body)
                        .font(.system(size: 13))
                        .foregroundColor(NotebookPalette.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .padding(.leading, 3)
        .background(
            HStack(spacing: 0) {
                Rectangle()
                    .fill(NotebookPalette.color(for: note.entryKind))
                    .frame(width: 3)
                NotebookPalette.cardSurface
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - New Entry button

private struct NotebookNewEntryButton: View {
    @Binding var showAddSheet: Bool
    
    var body: some View {
        Button {
            showAddSheet = true
        } label: {
            Text("New Entry")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(NotebookPalette.accent)
                )
        }
        .buttonStyle(NotebookSpringyButtonStyle())
        .accessibilityLabel("New entry")
    }
}

private struct NotebookSpringyButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Legacy palette used by other modules — delegate to NotebookPalette.
private enum EngineeringNotebookKindPalette {
    static func color(for kind: EngineeringNoteKind) -> Color {
        NotebookPalette.color(for: kind)
    }
}

// MARK: - Run log tab

private struct RunLogTab: View {
    @ObservedObject var store: EngineeringNotebookStore
    @State private var showAddSheet = false
    
    private var passCount: Int { store.runs.filter { $0.passFail == true }.count }
    private var failCount: Int { store.runs.filter { $0.passFail == false }.count }
    private var totalRuns: Int { store.runs.count }
    private var passRatePct: Int {
        guard totalRuns > 0 else { return 0 }
        let rated = passCount + failCount
        guard rated > 0 else { return 0 }
        return Int((Double(passCount) / Double(rated)) * 100.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            heroCard
            
            Button {
                showAddSheet = true
            } label: {
                Text("＋ Log a Test Run")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(NotebookPalette.accent)
                    )
            }
            .buttonStyle(NotebookSpringyButtonStyle())
            
            Text("Short entries beat long essays — what changed between attempts?")
                .font(.system(size: 13))
                .foregroundColor(NotebookPalette.textSecondary)
                .padding(.bottom, 4)
            
            if store.runs.isEmpty {
                runLogEmptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(store.runs.enumerated()), id: \.element.id) { index, run in
                        RunLogRow(
                            run: run,
                            index: store.runs.count - index,
                            onDelete: { store.removeRun(id: run.id) }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddRunLogSheet(store: store)
        }
    }
    
    private var heroCard: some View {
        VStack(spacing: 18) {
            RunLogDonutRing(
                passCount: passCount,
                failCount: failCount,
                total: totalRuns
            )
            .frame(width: 160, height: 160)
            
            VStack(spacing: 4) {
                Text("RUN LOG")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(NotebookPalette.textTertiary)
                    .tracking(1.4)
                Text("\(totalRuns) runs · \(passRatePct)% pass rate")
                    .font(.system(size: 14))
                    .foregroundColor(NotebookPalette.textSecondary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: totalRuns)
            }
            
            HStack(spacing: 16) {
                runLegend(color: NotebookPalette.pass, label: "Pass", count: passCount)
                runLegend(color: NotebookPalette.fail, label: "Fail", count: failCount)
                runLegend(color: NotebookPalette.chipInactive, label: "Untested", count: max(totalRuns - passCount - failCount, 0))
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(NotebookPalette.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(NotebookPalette.stroke, lineWidth: 1)
        )
    }
    
    private func runLegend(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(NotebookPalette.textSecondary)
        }
    }
    
    private var runLogEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flask")
                .font(.system(size: 44))
                .foregroundColor(NotebookPalette.stroke)
            Text("No test runs yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Text("Log your first run above — judges want to see your iteration, not just the final result.")
                .font(.system(size: 14))
                .foregroundColor(NotebookPalette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(NotebookPalette.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct RunLogDonutRing: View {
    let passCount: Int
    let failCount: Int
    let total: Int
    
    private var passFraction: Double {
        guard total > 0 else { return 0 }
        return Double(passCount) / Double(total)
    }
    private var failFraction: Double {
        guard total > 0 else { return 0 }
        return Double(failCount) / Double(total)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(NotebookPalette.chipInactive, lineWidth: 14)
            
            Circle()
                .trim(from: 0, to: passFraction)
                .stroke(NotebookPalette.pass, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: passFraction)
            
            Circle()
                .trim(from: passFraction, to: passFraction + failFraction)
                .stroke(NotebookPalette.fail, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: failFraction)
            
            VStack(spacing: 2) {
                Text("\(total)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: total)
                Text(total == 1 ? "RUN" : "RUNS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(NotebookPalette.textTertiary)
                    .tracking(1.2)
            }
        }
    }
}

// MARK: - Run log row

private struct RunLogRow: View {
    let run: RunLogEntry
    let index: Int
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Run #\(index)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(NotebookPalette.accent)
                Spacer()
                Text(run.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(NotebookPalette.textTertiary)
            }
            
            HStack(alignment: .top, spacing: 6) {
                Text("Hypothesis:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(NotebookPalette.textSecondary)
                Text(run.hypothesis)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            HStack(spacing: 8) {
                if let pass = run.passFail {
                    resultChip(pass: pass)
                }
                Text(run.result)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(NotebookPalette.textTertiary)
            }
            
            if let setup = run.setup, !setup.isEmpty {
                Text(setup)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(NotebookPalette.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(NotebookPalette.chipInactive))
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NotebookPalette.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Run", systemImage: "trash")
            }
        }
    }
    
    private func resultChip(pass: Bool) -> some View {
        Text(pass ? "PASS" : "FAIL")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(pass ? NotebookPalette.pass : NotebookPalette.fail)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .overlay(
                Capsule()
                    .strokeBorder(pass ? NotebookPalette.pass : NotebookPalette.fail, lineWidth: 1)
            )
    }
}

// MARK: - Note detail view

private struct EngineeringNoteDetailView: View {
    let note: EngineeringNote
    @ObservedObject var store: EngineeringNotebookStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: note.entryKind.icon)
                            .font(.title3)
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text(note.entryKind.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    Text(note.title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    if let subsystem = note.subsystem, !subsystem.isEmpty {
                        Text("Subsystem: \(subsystem)")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    if let author = note.authorStudent, !author.isEmpty {
                        Text("Student author(s): \(author)")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    if let phase = note.designPhase {
                        Text("Design phase: \(phase.displayName)")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    Text(note.createdAt.formatted(date: .complete, time: .shortened))
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                
                Divider()
                
                if !note.body.isEmpty {
                    Text(note.body)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                if let att = note.attachmentsNote, !att.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photos / CAD / links (summary)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(att)
                            .font(.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.tertiaryBackground.opacity(0.5))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                
                if let rid = note.linkedRunLogId,
                   let run = store.runs.first(where: { $0.id == rid }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Linked test run", systemImage: "link")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.focus)
                        Text(run.hypothesis)
                            .font(.subheadline.weight(.medium))
                        Text(run.result)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(run.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.focus.opacity(0.08))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                
                if let nextStep = note.nextStep, !nextStep.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Next step", systemImage: "arrow.right.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text(nextStep)
                            .font(.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.primary.opacity(0.08))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .background(DesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    store.removeNote(id: note.id)
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

// MARK: - Add note sheet

private struct AddEngineeringNoteSheet: View {
    @ObservedObject var store: EngineeringNotebookStore
    let initialKind: EngineeringNoteKind
    @Environment(\.dismiss) private var dismiss
    
    @State private var kind: EngineeringNoteKind
    @State private var title = ""
    @State private var details = ""
    @State private var subsystem = ""
    @State private var nextStep = ""
    @State private var authorStudent = ""
    @State private var designPhase: EngineeringDesignPhase?
    @State private var attachmentsNote = ""
    @State private var linkedRunLogId: UUID?
    
    init(store: EngineeringNotebookStore, initialKind: EngineeringNoteKind) {
        self.store = store
        self.initialKind = initialKind
        _kind = State(initialValue: initialKind)
        _title = State(initialValue: initialKind.templateTitle)
    }
    
    private var runsChrono: [RunLogEntry] {
        store.runs.sorted { $0.createdAt < $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Entry type", selection: $kind) {
                    ForEach(EngineeringNoteKind.allCases) { k in
                        Label(k.displayName, systemImage: k.icon).tag(k)
                    }
                }
                .onChange(of: kind) { _, newKind in
                    if title == initialKind.templateTitle || title.isEmpty {
                        title = newKind.templateTitle
                    }
                }
                
                SwiftUI.Section {
                    TextField("Title", text: $title)
                    TextField("Student author(s) (optional)", text: $authorStudent)
                    TextField("Subsystem (optional)", text: $subsystem)
                    Picker("Design phase (optional)", selection: $designPhase) {
                        Text("Not set").tag(nil as EngineeringDesignPhase?)
                        ForEach(EngineeringDesignPhase.allCases) { p in
                            Text(p.displayName).tag(Optional(p))
                        }
                    }
                    TextField("Details", text: $details, axis: .vertical)
                        .lineLimit(4...12)
                    TextField("Photos / CAD summary (optional)", text: $attachmentsNote, axis: .vertical)
                        .lineLimit(2...6)
                } header: {
                    Text("Details")
                } footer: {
                    Text(kind.entryGuidance)
                        .font(.caption)
                }
                
                if !runsChrono.isEmpty {
                    Section("Link to test run") {
                        Picker("Linked run (optional)", selection: $linkedRunLogId) {
                            Text("None").tag(nil as UUID?)
                            ForEach(runsChrono) { run in
                                Text(run.hypothesis)
                                    .lineLimit(1)
                                    .tag(Optional(run.id))
                            }
                        }
                    }
                }
                
                Section {
                    TextField("Next step (optional)", text: $nextStep)
                } footer: {
                    Text("What should happen after this entry?")
                }
            }
            .navigationTitle("New entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let note = EngineeringNote(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            body: details.trimmingCharacters(in: .whitespacesAndNewlines),
                            entryKind: kind,
                            subsystem: subsystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : subsystem.trimmingCharacters(in: .whitespacesAndNewlines),
                            nextStep: nextStep.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : nextStep.trimmingCharacters(in: .whitespacesAndNewlines),
                            authorStudent: authorStudent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : authorStudent.trimmingCharacters(in: .whitespacesAndNewlines),
                            designPhase: designPhase,
                            attachmentsNote: attachmentsNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : attachmentsNote.trimmingCharacters(in: .whitespacesAndNewlines),
                            linkedRunLogId: linkedRunLogId
                        )
                        store.addNote(note)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Add run log sheet

private struct AddRunLogSheet: View {
    @ObservedObject var store: EngineeringNotebookStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var hypothesis = ""
    @State private var result = ""
    @State private var setup = ""
    @State private var passFail: Bool?
    @State private var nextAction = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Test setup") {
                    TextField("Hypothesis or what you're testing", text: $hypothesis)
                    TextField("Setup / configuration (optional)", text: $setup)
                }
                
                Section("Result") {
                    TextField("What happened?", text: $result, axis: .vertical)
                        .lineLimit(2...6)
                    
                    Picker("Pass/Fail", selection: $passFail) {
                        Text("Not set").tag(nil as Bool?)
                        Text("Pass").tag(true as Bool?)
                        Text("Fail").tag(false as Bool?)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    TextField("Next action (optional)", text: $nextAction)
                } footer: {
                    Text("What's the next iteration based on this run?")
                }
            }
            .navigationTitle("Log test run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let run = RunLogEntry(
                            hypothesis: hypothesis.trimmingCharacters(in: .whitespacesAndNewlines),
                            result: result.trimmingCharacters(in: .whitespacesAndNewlines),
                            setup: setup.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : setup.trimmingCharacters(in: .whitespacesAndNewlines),
                            passFail: passFail,
                            nextAction: nextAction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : nextAction.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        store.addRun(run)
                        dismiss()
                    }
                    .disabled(
                        hypothesis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
    }
}

// MARK: - Rubric self-check sheet

private struct EngineeringRubricSheet: View {
    @ObservedObject var store: EngineeringNotebookStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Problem / goal is clear", isOn: rubricBinding(\.problemClear))
                    Toggle("Alternatives considered", isOn: rubricBinding(\.alternativesConsidered))
                    Toggle("Tests and evidence documented", isOn: rubricBinding(\.testEvidenceDocumented))
                    Toggle("Failures and pivots recorded", isOn: rubricBinding(\.failuresAndPivots))
                    Toggle("Student voice evident", isOn: rubricBinding(\.studentVoice))
                    Toggle("Iteration / design cycle visible", isOn: rubricBinding(\.iterationVisible))
                } footer: {
                    Text("This checklist is for your team only—not official judging. See FIRST's engineering notebook self-assessment for full guidance.")
                        .font(.caption)
                }
            }
            .navigationTitle("Rubric self-check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func rubricBinding(_ keyPath: WritableKeyPath<EngineeringRubricChecklist, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.rubricChecklist[keyPath: keyPath] },
            set: { newVal in
                var c = store.rubricChecklist
                c[keyPath: keyPath] = newVal
                store.setRubricChecklist(c)
            }
        )
    }
}

// MARK: - Table of contents sheet

private struct EngineeringTOCSheet: View {
    @ObservedObject var store: EngineeringNotebookStore
    @Environment(\.dismiss) private var dismiss
    
    private var sortedChrono: [EngineeringNote] {
        store.notes.sorted { $0.createdAt < $1.createdAt }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if sortedChrono.isEmpty {
                    ContentUnavailableView(
                        "No entries yet",
                        systemImage: "doc.text",
                        description: Text("Add notebook entries to build a chronological table of contents.")
                    )
                } else {
                    List {
                        ForEach(Array(sortedChrono.enumerated()), id: \.element.id) { index, note in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(index + 1). \(note.title)")
                                    .font(.subheadline.weight(.semibold))
                                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Table of contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Share export

private struct ShareExportPayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
