//
//  StrategyAlliancePicklistView.swift
//  FTCHUB
//
//  Ranked alliance shortlist with share export.
//

import SwiftUI

struct StrategyAlliancePicklistView: View {
    @ObservedObject var store: AlliancePicklistStore
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scoutingService: ScoutingService
    
    @State private var newTeamNumber = ""
    @State private var sharePayload: SharePicklistPayload?
    @State private var editMode = EditMode.inactive
    
    private var sortedEntries: [AlliancePicklistEntry] {
        store.entries.sorted(by: { $0.sortIndex < $1.sortIndex })
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Team #", text: $newTeamNumber)
                        .keyboardType(.asciiCapableNumberPad)
                    Button("Add") {
                        store.add(teamNumber: newTeamNumber)
                        newTeamNumber = ""
                    }
                    .disabled(newTeamNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Add to shortlist")
            } footer: {
                Text("Build a ranked list for alliance selection. Red flag marks teams you want to double-check.")
            }
            
            if store.entries.isEmpty {
                Section {
                    Text("No teams yet. Add numbers you are considering as partners.")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            } else {
                Section {
                    ForEach(sortedEntries) { entry in
                        picklistRow(entry)
                    }
                    .onDelete { indexSet in
                        for idx in indexSet {
                            store.remove(id: sortedEntries[idx].id)
                        }
                    }
                    .onMove { source, dest in
                        var ids = sortedEntries.map(\.id)
                        ids.move(fromOffsets: source, toOffset: dest)
                        store.applyOrder(ids: ids)
                    }
                } header: {
                    Text("Ranked list (drag to reorder)")
                }
            }
            
            if !store.entries.isEmpty {
                Section {
                    NavigationLink {
                        StrategyTeamCompareView(
                            seedTeamNumbers: Array(sortedEntries.prefix(3).map(\.teamNumber))
                        )
                        .environmentObject(scoutingService)
                    } label: {
                        Label("Compare first \(min(3, sortedEntries.count)) in list", systemImage: "rectangle.split.3x1")
                    }
                }
            }
        }
        .navigationTitle("Alliance pick list")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            TelemetryService.shared.logEvent("strategy_alliance_picklist_opened")
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        sharePayload = SharePicklistPayload(
                            text: store.exportPlainText(teamNumber: teamService.currentTeam?.number),
                            suggestedName: "alliance-picklist.txt"
                        )
                    } label: {
                        Label("Share as text", systemImage: "doc.text")
                    }
                    Button {
                        sharePayload = SharePicklistPayload(
                            text: store.exportCSV(),
                            suggestedName: "alliance-picklist.csv"
                        )
                    } label: {
                        Label("Share CSV", systemImage: "tablecells")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(store.entries.isEmpty)
            }
        }
        .sheet(item: $sharePayload) { payload in
            ActivityView(activityItems: [payload.text])
        }
    }
    
    @ViewBuilder
    private func picklistRow(_ entry: AlliancePicklistEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.teamNumber)
                    .font(.headline.weight(.semibold))
                if entry.isRedFlag {
                    Image(systemName: "flag.fill")
                        .foregroundColor(DesignSystem.Colors.error)
                        .font(.caption)
                }
                Spacer()
                NavigationLink {
                    StrategyTeamCompareView(seedTeamNumbers: [entry.teamNumber])
                        .environmentObject(scoutingService)
                } label: {
                    Image(systemName: "rectangle.split.3x1")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                .buttonStyle(.borderless)
                Button {
                    var u = entry
                    u.isRedFlag.toggle()
                    store.update(u)
                } label: {
                    Image(systemName: entry.isRedFlag ? "flag.slash" : "flag")
                }
                .buttonStyle(.borderless)
            }
            if scoutingService.hasReports(for: entry.teamNumber) {
                Text("\(scoutingService.getTeamPerformance(teamNumber: entry.teamNumber).count) scout reports")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            } else {
                Text("No scout reports yet")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.warning)
            }
            TextField("Notes", text: Binding(
                get: { entry.notes },
                set: { newVal in
                    var u = entry
                    u.notes = newVal
                    store.update(u)
                }
            ))
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

private struct SharePicklistPayload: Identifiable {
    let id = UUID()
    let text: String
    let suggestedName: String
}

#if canImport(UIKit)
import UIKit

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
private struct ActivityView: View {
    let activityItems: [Any]
    var body: some View { EmptyView() }
}
#endif
