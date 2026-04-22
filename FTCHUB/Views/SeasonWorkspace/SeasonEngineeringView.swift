//
//  SeasonEngineeringView.swift
//  FTCHUB
//
//  Season workspace destination: Engineering notebook and run log with FTC-aligned guidance.
//

import SwiftUI
import UIKit

struct SeasonEngineeringView: View {
    @EnvironmentObject var session: SeasonWorkspaceSession
    @EnvironmentObject var teamService: TeamService
    @State private var selectedTab = 0
    @State private var notebookSearchText = ""
    @State private var showRubricSheet = false
    @State private var showTOCSheet = false
    @State private var shareExportPayload: ShareExportPayload?
    
    init() {
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
        appearance.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.systemGray], for: .normal)
    }
    
    var body: some View {
        engineeringRoot
            .background(DesignSystem.Colors.background.ignoresSafeArea())
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
                                exportNotebookMarkdown()
                            } label: {
                                Label("Export Markdown", systemImage: "doc.text")
                            }
                            Button {
                                exportNotebookPDF()
                            } label: {
                                Label("Export PDF", systemImage: "doc.text.fill")
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
    }
    
    private func exportNotebookMarkdown() {
        let md = EngineeringNotebookExport.markdown(
            teamNumber: teamService.currentTeam?.number,
            notes: session.notebookStore.notes,
            runs: session.notebookStore.runs,
            rubric: session.notebookStore.rubricChecklist
        )
        TelemetryService.shared.logEvent("engineering_notebook_export_markdown")
        shareExportPayload = ShareExportPayload(items: [md])
    }
    
    private func exportNotebookPDF() {
        guard let data = EngineeringNotebookExport.pdfData(
            teamNumber: teamService.currentTeam?.number,
            notes: session.notebookStore.notes,
            runs: session.notebookStore.runs,
            rubric: session.notebookStore.rubricChecklist
        ) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("FTCHUB-notebook-\(UUID().uuidString).pdf")
        do {
            try data.write(to: url)
            TelemetryService.shared.logEvent("engineering_notebook_export_pdf")
            shareExportPayload = ShareExportPayload(items: [url])
        } catch {
            TelemetryService.shared.logError(error, context: ["where": "engineering_notebook_pdf"])
        }
    }
    
    private var engineeringRoot: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Notebook").tag(0)
                Text("Run log").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.sm)
            .padding(.bottom, DesignSystem.Spacing.xs)
            
            if selectedTab == 0 {
                EngineeringNotebookTab(
                    store: session.notebookStore,
                    searchText: $notebookSearchText
                )
            } else {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        RunLogTab(store: session.notebookStore)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
        }
    }
}

// MARK: - Notebook tab

private struct EngineeringNotebookTab: View {
    @ObservedObject var store: EngineeringNotebookStore
    @Binding var searchText: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showAddSheet = false
    @State private var selectedKind: EngineeringNoteKind = .designDecision
    @State private var filterKind: EngineeringNoteKind?
    /// 0 = all design phases; 1...n map to `EngineeringDesignPhase.allCases`.
    @State private var phaseCarouselIndex: Int = 0
    @State private var lastLoggedPhaseIndex: Int = 0
    
    private var effectivePhaseFilter: EngineeringDesignPhase? {
        guard phaseCarouselIndex > 0 else { return nil }
        let phases = EngineeringDesignPhase.allCases
        let i = phaseCarouselIndex - 1
        guard phases.indices.contains(i) else { return nil }
        return phases[i]
    }
    
    private var filteredNotes: [EngineeringNote] {
        var notes = store.notes
        if let filter = filterKind {
            notes = notes.filter { $0.entryKind == filter }
        }
        if let phase = effectivePhaseFilter {
            notes = notes.filter { $0.designPhase == phase }
        }
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
    
    private var notesWithAuthorCount: Int {
        filteredNotes.filter { !($0.authorStudent ?? "").isEmpty }.count
    }
    
    private var notesWithLinkedRunCount: Int {
        filteredNotes.filter { $0.linkedRunLogId != nil }.count
    }
    
    private var highlightNotes: [EngineeringNote] {
        Array(filteredNotes.sorted { $0.createdAt > $1.createdAt }.prefix(3))
    }
    
    /// Newest days first; notes within a day newest-first.
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
    
    @State private var showPlaybook = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Sticky header
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(red: 0.39, green: 0.39, blue: 0.40))
                    TextField("Search notes…", text: $searchText)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.11, green: 0.11, blue: 0.12))
                .cornerRadius(10)
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                NotebookKindFilterChips(filterKind: $filterKind)
                
                NotebookAddKindStrip(selectedKind: $selectedKind, showAddSheet: $showAddSheet)
            }
            .padding(.bottom, DesignSystem.Spacing.md)
            
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    NotebookDashboardHeroCard(
                        store: store,
                        phaseCarouselIndex: $phaseCarouselIndex,
                        selectedPhase: effectivePhaseFilter
                    )
                    
                    NotebookHighlightsCard(notes: highlightNotes, store: store)
                    notebookEntriesCard
                    
                    playbookSection
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
        }
        .onChange(of: phaseCarouselIndex) { _, newVal in
            guard newVal != lastLoggedPhaseIndex else { return }
            lastLoggedPhaseIndex = newVal
            let key: String
            if newVal == 0 { key = "all" }
            else {
                let phases = EngineeringDesignPhase.allCases
                let i = newVal - 1
                key = phases.indices.contains(i) ? phases[i].rawValue : "all"
            }
            TelemetryService.shared.logEvent("engineering_notebook_phase_filter", parameters: ["phase": key])
        }
        .sheet(isPresented: $showAddSheet) {
            AddEngineeringNoteSheet(store: store, initialKind: selectedKind)
        }
    }
    
    private var notebookEntriesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("All Entries")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
                Text("\(filteredNotes.count) shown")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
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
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(dayGroups.enumerated()), id: \.offset) { _, group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(daySectionTitle(group.day))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
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
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "doc.text")
                .font(.largeTitle)
                .foregroundColor(DesignSystem.Colors.textTertiary)
            Text("No notes yet")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text("Use the New entry strip above to add design decisions, tests, and bugs as they happen.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
    }
    
    private var notebookEmptyNoMatchView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.largeTitle)
                .foregroundColor(DesignSystem.Colors.textTertiary)
            Text("No notes match")
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text("Try another phase or entry type, clear search, or add a new entry.")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
    }
    
    // MARK: - Playbook guidance strip
    
    private var playbookSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showPlaybook.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("What Judges Look For")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: showPlaybook ? "chevron.up" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            if showPlaybook {
                VStack(alignment: .leading, spacing: 12) {
                    playbookItem(
                        title: "Full design cycle",
                        detail: "Problem → brainstorm → select → build → test → iterate. Document all stages, not just the final robot.",
                        link: nil
                    )
                    playbookItem(
                        title: "Failures and pivots",
                        detail: "What didn't work is as valuable as what did. Note why you changed direction.",
                        link: nil
                    )
                    playbookItem(
                        title: "Student-written entries",
                        detail: "Judges look for student voice. Mentors guide but students document.",
                        link: nil
                    )
                    playbookItem(
                        title: "Testable hypotheses",
                        detail: "\"If we lower intake speed by 20%, we expect fewer jams.\" Run log proves iteration.",
                        link: nil
                    )
                    
                    Divider()
                        .background(Color(red: 0.23, green: 0.23, blue: 0.24))
                        .padding(.vertical, 4)
                    
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
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(showPlaybook ? DesignSystem.Colors.primary : Color.clear, lineWidth: showPlaybook ? 1 : 0)
        )
        .overlay(
            HStack {
                if showPlaybook {
                    Rectangle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 3)
                    Spacer()
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func playbookItem(title: String, detail: String, link: URL?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
            if let link {
                Link("Learn more", destination: link)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.leading, 16)
            }
        }
    }
}

// MARK: - Notebook mockup-aligned components

private struct NotebookKindFilterChips: View {
    @Binding var filterKind: EngineeringNoteKind?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", selected: filterKind == nil) {
                    filterKind = nil
                }
                ForEach(EngineeringNoteKind.allCases) { kind in
                    filterChip(title: kind.shortName, selected: filterKind == kind) {
                        filterKind = kind
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .mask(
            HStack(spacing: 0) {
                Color.black
                LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                    .frame(width: 24)
            }
        )
    }
    
    private func filterChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selected ? .white : DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background(
                    Capsule()
                        .fill(selected ? DesignSystem.Colors.primary : Color(red: 0.17, green: 0.17, blue: 0.18))
                )
        }
        .buttonStyle(NotebookSpringyButtonStyle())
        .accessibilityLabel("Filter: \(title)")
    }
}

private struct NotebookDashboardHeroCard: View {
    @ObservedObject var store: EngineeringNotebookStore
    @Binding var phaseCarouselIndex: Int
    let selectedPhase: EngineeringDesignPhase?
    
    private var designCount: Int {
        store.notes.filter { $0.entryKind == .designDecision }.count
    }
    
    private var testCount: Int {
        store.notes.filter { $0.entryKind == .testSession }.count
    }
    
    private var buildCount: Int {
        store.notes.filter { $0.designPhase == .createBuild }.count
    }
    
    private var authorsCount: Int {
        store.notes.filter { !($0.authorStudent ?? "").isEmpty }.count
    }
    
    private var linkedRunsCount: Int {
        store.notes.filter { $0.linkedRunLogId != nil }.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Top row
            HStack {
                Text("ENGINEERING NOTEBOOK")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                    .tracking(1.2)
                
                Spacer()
                
                Menu {
                    Button("All phases") { phaseCarouselIndex = 0 }
                    ForEach(Array(EngineeringDesignPhase.allCases.enumerated()), id: \.element.id) { offset, phase in
                        Button(phase.displayName) { phaseCarouselIndex = offset + 1 }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPhase?.displayName ?? "All Phases")
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .strokeBorder(DesignSystem.Colors.primary.opacity(0.5), lineWidth: 1)
                    )
                }
            }
            
            // Middle stats row
            HStack(spacing: 0) {
                statColumn(icon: "lightbulb.fill", label: "Design", count: designCount)
                Divider()
                    .background(Color(red: 0.23, green: 0.23, blue: 0.24))
                    .padding(.vertical, 4)
                statColumn(icon: "flask.fill", label: "Test", count: testCount)
                Divider()
                    .background(Color(red: 0.23, green: 0.23, blue: 0.24))
                    .padding(.vertical, 4)
                statColumn(icon: "wrench.and.screwdriver.fill", label: "Build", count: buildCount)
            }
            
            // Bottom metadata row
            VStack(spacing: 6) {
                Text("\(store.notes.count) entries · \(authorsCount) authors · \(linkedRunsCount) test links")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                
                Text("Every entry judges see builds your case.")
                    .font(.system(size: 12))
                    .italic()
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
            }
        }
        .padding(20)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(red: 0.23, green: 0.23, blue: 0.24), lineWidth: 1)
        )
    }
    
    private func statColumn(icon: String, label: String, count: Int) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(DesignSystem.Colors.primary)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: count)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct NotebookHighlightsCard: View {
    let notes: [EngineeringNote]
    @ObservedObject var store: EngineeringNotebookStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notebook Highlights")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            if notes.isEmpty {
                Text("Add 3+ entries to see your top highlights here.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(Array(notes.enumerated()), id: \.1.id) { pair in
                    NavigationLink {
                        EngineeringNoteDetailView(note: pair.1, store: store)
                    } label: {
                        NotebookHighlightRow(rank: pair.0 + 1, note: pair.1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(12)
    }
}

private struct NotebookHighlightRow: View {
    let rank: Int
    let note: EngineeringNote
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                .frame(width: 24, alignment: .leading)
            
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.91, green: 0.64, blue: 0.35).opacity(0.08))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: note.entryKind.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.91, green: 0.64, blue: 0.35))
                )
            
            Text(note.title)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer(minLength: 8)
            
            Text(note.entryKind.shortName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(EngineeringNotebookKindPalette.color(for: note.entryKind))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(EngineeringNotebookKindPalette.color(for: note.entryKind).opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

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
        HStack(spacing: 0) {
            // Left accent strip
            Rectangle()
                .fill(EngineeringNotebookKindPalette.color(for: note.entryKind))
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title row
                HStack(alignment: .top) {
                    Text(note.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(note.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                }
                
                // Second row: type chip + author initials
                HStack(spacing: 8) {
                    Text(note.entryKind.shortName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(EngineeringNotebookKindPalette.color(for: note.entryKind))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(EngineeringNotebookKindPalette.color(for: note.entryKind).opacity(0.12))
                        .clipShape(Capsule())
                    
                    if note.authorStudent != nil && !note.authorStudent!.isEmpty {
                        Text(initials)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.23, green: 0.23, blue: 0.24))
                            .clipShape(Capsule())
                    }
                }
                
                // Third row: one-line preview
                Text(note.body)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                    .lineLimit(1)
            }
            .padding(12)
        }
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(12)
    }
}

private struct NotebookAddKindStrip: View {
    @Binding var selectedKind: EngineeringNoteKind
    @Binding var showAddSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEW ENTRY")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .tracking(1.2)
                .padding(.horizontal, 16)
            
            Button {
                selectedKind = .designDecision
                showAddSheet = true
            } label: {
                Text("＋ New Entry")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(DesignSystem.Colors.primary)
                    .cornerRadius(16)
            }
            .buttonStyle(NotebookSpringyButtonStyle())
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EngineeringNoteKind.allCases) { kind in
                        Button {
                            selectedKind = kind
                            showAddSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: kind.icon)
                                    .foregroundColor(EngineeringNotebookKindPalette.color(for: kind))
                                Text(kind.shortName)
                                    .foregroundColor(.white)
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(Color(red: 0.17, green: 0.17, blue: 0.18))
                            .cornerRadius(20)
                        }
                        .buttonStyle(NotebookSpringyButtonStyle())
                        .accessibilityLabel("Add \(kind.displayName) entry")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
            .mask(
                HStack(spacing: 0) {
                    Color.black
                    LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: 24)
                }
            )
        }
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

private enum EngineeringNotebookKindPalette {
    static func color(for kind: EngineeringNoteKind) -> Color {
        switch kind {
        case .designDecision: return Color(red: 0.91, green: 0.64, blue: 0.35) // #E8A45A
        case .testSession: return Color(red: 0.39, green: 0.63, blue: 0.91) // #64A0E8
        case .bug: return Color(red: 1.0, green: 0.42, blue: 0.42) // #FF6B6B
        case .meeting: return Color(red: 0.65, green: 0.55, blue: 0.98) // #A78BFA
        case .other: return Color(red: 0.56, green: 0.56, blue: 0.58) // #8E8E93
        }
    }
}

private func notebookPhaseExplorerHint(_ phase: EngineeringDesignPhase?) -> String {
    guard let phase else {
        return "Every phase matters for judges—use filters above or browse everything below."
    }
    switch phase {
    case .identifyPlan:
        return "Goals, constraints, and options your team weighed."
    case .createBuild:
        return "Build choices, CAD summaries, and integration notes."
    case .testEvaluate:
        return "Hypotheses, setups, results, and honest outcomes."
    case .iterateCommunicate:
        return "What changed next—and how you told the story."
    }
}

private func notebookPhaseCardSubtitle(_ phase: EngineeringDesignPhase) -> String {
    switch phase {
    case .identifyPlan: return "Define & plan"
    case .createBuild: return "Create & build"
    case .testEvaluate: return "Test & evaluate"
    case .iterateCommunicate: return "Iterate & share"
    }
}

private func notebookPhaseSystemImage(_ phase: EngineeringDesignPhase) -> String {
    switch phase {
    case .identifyPlan: return "scope"
    case .createBuild: return "hammer.fill"
    case .testEvaluate: return "checkmark.seal.fill"
    case .iterateCommunicate: return "arrow.triangle.2.circlepath"
    }
}

private func notebookPhaseTint(_ phase: EngineeringDesignPhase) -> Color {
    switch phase {
    case .identifyPlan: return DesignSystem.Colors.focus
    case .createBuild: return DesignSystem.Colors.primary
    case .testEvaluate: return DesignSystem.Colors.success
    case .iterateCommunicate: return DesignSystem.Colors.accent
    }
}

// MARK: - Run log tab

private struct RunLogTab: View {
    @ObservedObject var store: EngineeringNotebookStore
    @State private var showAddSheet = false
    
    private var passCount: Int {
        store.runs.filter { $0.passFail == true }.count
    }
    
    private var failCount: Int {
        store.runs.filter { $0.passFail == false }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Hero Card
            heroCard
            
            // Primary CTA
            Button {
                showAddSheet = true
            } label: {
                Text("＋ Log a Test Run")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
            }
            .buttonStyle(NotebookSpringyButtonStyle())
            
            Text("Short entries beat long essays — what changed between attempts?")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                .padding(.bottom, 8)
            
            // Runs List
            if store.runs.isEmpty {
                runLogEmptyState
            } else {
                VStack(spacing: 8) {
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
        VStack(spacing: 24) {
            HStack {
                Text("RUN LOG")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                    .tracking(1.2)
                Spacer()
                Menu {
                    Button("All time") {}
                } label: {
                    HStack(spacing: 4) {
                        Text("All time")
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .strokeBorder(DesignSystem.Colors.primary.opacity(0.5), lineWidth: 1)
                    )
                }
            }
            
            HStack(spacing: 0) {
                statColumn(label: "Runs", count: store.runs.count)
                Divider()
                    .background(Color(red: 0.23, green: 0.23, blue: 0.24))
                    .padding(.vertical, 4)
                statColumn(label: "Pass", count: passCount)
                Divider()
                    .background(Color(red: 0.23, green: 0.23, blue: 0.24))
                    .padding(.vertical, 4)
                statColumn(label: "Fail", count: failCount)
            }
            
            Text("Document hypothesis → result pairs to build iteration evidence judges look for.")
                .font(.system(size: 12))
                .italic()
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(red: 0.23, green: 0.23, blue: 0.24), lineWidth: 1)
        )
    }
    
    private func statColumn(label: String, count: Int) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: count)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var runLogEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flask")
                .font(.system(size: 44))
                .foregroundColor(Color(red: 0.23, green: 0.23, blue: 0.24))
            Text("No test runs yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Text("Log your first run above — judges want to see your iteration process, not just the final result.")
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(12)
    }
}

// MARK: - Note row

private struct EngineeringNoteRow: View {
    let note: EngineeringNote
    var showDivider: Bool = true
    
    private var kindTint: Color {
        switch note.entryKind {
        case .designDecision: return DesignSystem.Colors.primary
        case .testSession: return DesignSystem.Colors.focus
        case .bug: return DesignSystem.Colors.error
        case .meeting: return DesignSystem.Colors.secondary
        case .other: return DesignSystem.Colors.textTertiary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(kindTint)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: note.entryKind.icon)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(kindTint)
                        Text(note.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 4)
                        Text(note.createdAt.formatted(date: .omitted, time: .shortened))
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    
                    if !note.body.isEmpty {
                        Text(note.body)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(spacing: 6) {
                        Text(note.entryKind.shortName)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(kindTint.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(kindTint.opacity(0.12))
                            .clipShape(Capsule())
                        if let author = note.authorStudent, !author.isEmpty {
                            Text(author)
                                .font(.caption2)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                                .lineLimit(1)
                        }
                        if let subsystem = note.subsystem, !subsystem.isEmpty {
                            Text(subsystem)
                                .font(.caption2)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .lineLimit(1)
                        }
                        if let next = note.nextStep, !next.isEmpty {
                            Label("Next step", systemImage: "arrow.turn.down.right")
                                .font(.caption2)
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.sm + 2)
                .padding(.trailing, DesignSystem.Spacing.md)
                .padding(.leading, DesignSystem.Spacing.sm)
            }
            
            if showDivider {
                Divider()
                    .padding(.leading, 4 + DesignSystem.Spacing.sm)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Run #\(index)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
                Spacer()
                Text(run.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
            }
            
            HStack(alignment: .top, spacing: 8) {
                Text("Hypothesis:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                Text(run.hypothesis)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            HStack(alignment: .center, spacing: 8) {
                Text("Result:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                
                if let pass = run.passFail {
                    Text(pass ? "PASS" : "FAIL")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(pass ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color(red: 1.0, green: 0.27, blue: 0.23))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(
                            Capsule()
                                .strokeBorder(pass ? Color(red: 0.19, green: 0.82, blue: 0.35) : Color(red: 1.0, green: 0.27, blue: 0.23), lineWidth: 1)
                        )
                }
                
                Text(run.result)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                if let setup = run.setup, !setup.isEmpty {
                    Text(setup)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.17, green: 0.17, blue: 0.18))
                        .clipShape(Capsule())
                        .lineLimit(1)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
            }
        }
        .padding(16)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
        .cornerRadius(12)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Run", systemImage: "trash")
            }
        }
    }
}

// MARK: - Note detail view

private struct EngineeringNoteDetailView: View {
    let note: EngineeringNote
    @ObservedObject var store: EngineeringNotebookStore
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
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
                
                // Body
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
                
                // Next step
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
                    Text("This checklist is for your team only—not official judging. See FIRST’s engineering notebook self-assessment for full guidance.")
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
