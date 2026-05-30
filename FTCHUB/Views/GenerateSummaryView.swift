//
//  GenerateSummaryView.swift
//  FTCHUB
//
//  Created on 11/16/25.
//

import SwiftUI

struct GenerateSummaryView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var summaryService: TeamSummaryService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTeamNumber: String = ""
    @State private var selectedEventName: String? = nil
    @State private var scoutName: String = ""
    @State private var isGenerating = false
    @State private var generatedSummary: TeamScoutingSummary?
    @State private var showingSummary = false
    @State private var errorMessage: String?
    
    private var availableTeams: [String] {
        scoutingService.getUniqueTeamNumbers()
    }
    
    private var availableEvents: [String] {
        scoutingService.getUniqueEventNames()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Team Selection") {
                    Picker("Team Number", selection: $selectedTeamNumber) {
                        Text("Select Team").tag("")
                        ForEach(availableTeams, id: \.self) { team in
                            Text("Team \(team)").tag(team)
                        }
                    }
                    
                    if !availableEvents.isEmpty {
                        Picker("Event (Optional)", selection: Binding(
                            get: { selectedEventName ?? "" },
                            set: { selectedEventName = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("All Events").tag("")
                            ForEach(availableEvents, id: \.self) { event in
                                Text(event).tag(event)
                            }
                        }
                    }
                }
                
                Section("Scout Information") {
                    TextField("Scout Name (Optional)", text: $scoutName)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await generateSummary()
                        }
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView()
                            } else {
                                Image(systemName: "doc.text.magnifyingglass")
                            }
                            Text(isGenerating ? "Generating..." : "Generate Summary")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(selectedTeamNumber.isEmpty || isGenerating)
                }
                
                if let summary = generatedSummary {
                    Section {
                        NavigationLink {
                            TeamScoutingSummaryView(summary: summary)
                                .environmentObject(summaryService)
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("View Generated Summary")
                            }
                        }
                        
                        Button {
                            Task {
                                await saveSummary(summary)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save Summary")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Generate Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateSummary() async {
        guard !selectedTeamNumber.isEmpty else { return }
        guard let teamId = scoutingService.currentTeamId else {
            errorMessage = "Join or create a team before generating summaries."
            return
        }
        
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }
        
        let reports = scoutingService.getReports(for: selectedTeamNumber, eventName: selectedEventName)
        
        guard !reports.isEmpty else {
            errorMessage = "No reports found for Team \(selectedTeamNumber)\(selectedEventName != nil ? " in \(selectedEventName!)" : "")."
            return
        }
        
        let summary = summaryService.generateSummary(
            for: selectedTeamNumber,
            reports: reports,
            eventName: selectedEventName,
            scoutName: scoutName.isEmpty ? nil : scoutName,
            teamId: teamId
        )
        
        generatedSummary = summary
    }
    
    private func saveSummary(_ summary: TeamScoutingSummary) async {
        do {
            try await summaryService.saveSummary(summary)
            dismiss()
        } catch {
            errorMessage = "Failed to save summary: \(error.localizedDescription)"
        }
    }
}

#Preview {
    GenerateSummaryView()
        .environmentObject(ScoutingService())
        .environmentObject(TeamSummaryService())
}


