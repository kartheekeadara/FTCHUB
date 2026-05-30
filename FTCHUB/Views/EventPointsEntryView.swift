//
//  EventPointsEntryView.swift
//  FTCHUB
//
//  Phase 2: Event Points Entry Form
//  Allows manual entry of event results and points
//

import SwiftUI

struct EventPointsEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var advancementService = AdvancementTrackingService.shared
    @EnvironmentObject var teamService: TeamService
    
    @State private var eventName = ""
    @State private var eventType: AdvancementTrackingService.EventType = .qualifier
    @State private var eventDate = Date()
    @State private var seasonYear = Calendar.current.component(.year, from: Date())
    
    @State private var winPoints = 0
    @State private var tiePoints = 0
    @State private var rankingPoints = 0
    @State private var awardPoints = 0
    @State private var finalRanking: Int?
    @State private var totalTeams: Int?
    @State private var awards: [String] = []
    @State private var newAward = ""
    @State private var advancedToNextLevel = false
    @State private var nextLevelEvent = ""
    @State private var notes = ""
    
    @State private var isCalculating = false
    
    var totalQualificationPoints: Int {
        winPoints + tiePoints + rankingPoints + awardPoints
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Information") {
                    TextField("Event Name", text: $eventName)
                    
                    Picker("Event Type", selection: $eventType) {
                        ForEach(AdvancementTrackingService.EventType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)
                    
                    Picker("Season Year", selection: $seasonYear) {
                        ForEach(Array((2020...2030).reversed()), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                }
                
                Section("Qualification Points") {
                    Stepper("Win Points: \(winPoints)", value: $winPoints, in: 0...100)
                        .help("2 points per win")
                    
                    Stepper("Tie Points: \(tiePoints)", value: $tiePoints, in: 0...100)
                        .help("1 point per tie")
                    
                    Stepper("Ranking Points: \(rankingPoints)", value: $rankingPoints, in: 0...100)
                    
                    Stepper("Award Points: \(awardPoints)", value: $awardPoints, in: 0...100)
                    
                    HStack {
                        Text("Total Qualification Points")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(totalQualificationPoints)")
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                
                Section("Ranking") {
                    HStack {
                        Text("Final Ranking")
                        Spacer()
                        TextField("Rank", value: $finalRanking, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Total Teams")
                        Spacer()
                        TextField("Teams", value: $totalTeams, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
                
                Section("Awards") {
                    ForEach(awards, id: \.self) { award in
                        HStack {
                            Text(award)
                            Spacer()
                            Button {
                                awards.removeAll { $0 == award }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add Award", text: $newAward)
                        Button("Add") {
                            if !newAward.isEmpty {
                                awards.append(newAward)
                                newAward = ""
                            }
                        }
                        .disabled(newAward.isEmpty)
                    }
                }
                
                Section("Advancement") {
                    Toggle("Advanced to Next Level", isOn: $advancedToNextLevel)
                    
                    if advancedToNextLevel {
                        TextField("Next Level Event", text: $nextLevelEvent)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button {
                        isCalculating = true
                        Task {
                            await calculateFromMatches()
                            isCalculating = false
                        }
                    } label: {
                        HStack {
                            if isCalculating {
                                ProgressView()
                            }
                            Text("Calculate from Matches")
                        }
                    }
                    .disabled(isCalculating || eventName.isEmpty)
                }
            }
            .navigationTitle("Add Event Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEventPoints()
                    }
                    .disabled(eventName.isEmpty)
                }
            }
        }
    }
    
    private func calculateFromMatches() async {
        guard let teamId = teamService.currentTeam?.id else { return }
        
        do {
            let points = try await advancementService.calculateEventPoints(
                eventName: eventName,
                teamId: teamId,
                seasonYear: seasonYear
            )
            
            winPoints = points.winPoints
            tiePoints = points.tiePoints
            // rankingPoints and awardPoints would need manual entry
        } catch {
            // Handle error
        }
    }
    
    private func saveEventPoints() {
        guard let teamId = teamService.currentTeam?.id else { return }
        
        let points = AdvancementTrackingService.EventPoints(
            id: UUID(),
            teamId: teamId,
            teamNumber: "0000", // Would need actual team number
            eventName: eventName,
            eventType: eventType,
            eventDate: eventDate,
            seasonYear: seasonYear,
            winPoints: winPoints,
            tiePoints: tiePoints,
            rankingPoints: rankingPoints,
            awardPoints: awardPoints,
            totalQualificationPoints: totalQualificationPoints,
            allianceSelectionPoints: 0,
            playoffMatchPoints: 0,
            championshipPoints: 0,
            totalPlayoffPoints: 0,
            finalRanking: finalRanking,
            totalTeams: totalTeams,
            awards: awards,
            advancedToNextLevel: advancedToNextLevel,
            nextLevelEvent: nextLevelEvent.isEmpty ? nil : nextLevelEvent,
            verified: false,
            source: "manual",
            notes: notes.isEmpty ? nil : notes,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        Task {
            try? await advancementService.addEventPoints(points)
            dismiss()
        }
    }
}

#Preview {
    EventPointsEntryView()
}
