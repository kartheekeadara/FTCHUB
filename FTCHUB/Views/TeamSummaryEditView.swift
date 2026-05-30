//
//  TeamSummaryEditView.swift
//  FTCHUB
//
//  Created on 11/16/25.
//

import SwiftUI

struct TeamSummaryEditView: View {
    @EnvironmentObject var summaryService: TeamSummaryService
    @Environment(\.dismiss) private var dismiss
    
    @State private var summary: TeamScoutingSummary
    @State private var isSaving = false
    
    init(summary: TeamScoutingSummary) {
        _summary = State(initialValue: summary)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Strengths
                Section {
                    ForEach(Array(summary.strengths.enumerated()), id: \.offset) { index, _ in
                        TextField("Strength \(index + 1)", text: Binding(
                            get: { summary.strengths[index] },
                            set: { summary.strengths[index] = $0 }
                        ))
                    }
                    .onDelete { indexSet in
                        summary.strengths.remove(atOffsets: indexSet)
                    }
                    
                    if summary.strengths.count < 4 {
                        Button {
                            summary.strengths.append("")
                        } label: {
                            Label("Add Strength", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("Strengths (max 4)")
                }
                
                // Weaknesses
                Section {
                    ForEach(Array(summary.weaknesses.enumerated()), id: \.offset) { index, _ in
                        TextField("Weakness \(index + 1)", text: Binding(
                            get: { summary.weaknesses[index] },
                            set: { summary.weaknesses[index] = $0 }
                        ))
                    }
                    .onDelete { indexSet in
                        summary.weaknesses.remove(atOffsets: indexSet)
                    }
                    
                    if summary.weaknesses.count < 4 {
                        Button {
                            summary.weaknesses.append("")
                        } label: {
                            Label("Add Weakness", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("Weaknesses (max 4)")
                }
                
                // Role Recommendation
                Section("Role Recommendation") {
                    Picker("Primary Role", selection: Binding(
                        get: { summary.primaryRole },
                        set: { summary.primaryRole = $0 }
                    )) {
                        ForEach(ScoutingRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(role.displayName)
                        }
                    }
                    
                    Picker("Secondary Role", selection: Binding(
                        get: { summary.secondaryRole },
                        set: { summary.secondaryRole = $0 }
                    )) {
                        ForEach(ScoutingRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(role.displayName)
                        }
                    }
                }
                
                // Match Tactics
                Section("Match Tactics") {
                    TextField("Autonomous", text: Binding(
                        get: { summary.matchTactics.autonomous },
                        set: { summary.matchTactics.autonomous = $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    
                    TextField("Teleop", text: Binding(
                        get: { summary.matchTactics.teleop },
                        set: { summary.matchTactics.teleop = $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    
                    TextField("Defense", text: Binding(
                        get: { summary.matchTactics.defense },
                        set: { summary.matchTactics.defense = $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    
                    TextField("Endgame", text: Binding(
                        get: { summary.matchTactics.endgame },
                        set: { summary.matchTactics.endgame = $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                }
                
                // Alliance Fit
                Section("Alliance Fit") {
                    TextField("Ideal Partners", text: Binding(
                        get: { summary.allianceFit.idealPartners },
                        set: { summary.allianceFit.idealPartners = $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Pick Priority: \(summary.allianceFit.pickPriority)")
                            .font(.subheadline)
                        
                        Slider(value: Binding(
                            get: { Double(summary.allianceFit.pickPriority) },
                            set: { summary.allianceFit.pickPriority = Int($0) }
                        ), in: 1...5, step: 1)
                        
                        HStack {
                            Text("1 = Must-pick")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Spacer()
                            Text("5 = Avoid")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    TextField("Priority Reason", text: Binding(
                        get: { summary.allianceFit.priorityReason },
                        set: { summary.allianceFit.priorityReason = $0 }
                    ), axis: .vertical)
                    .lineLimit(1...2)
                }
                
                // Exploitation / Countermeasures
                Section("Exploitation / Countermeasures") {
                    TextField("To Exploit", text: Binding(
                        get: { summary.exploitationNotes },
                        set: { summary.exploitationNotes = $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    
                    TextField("To Neutralize", text: Binding(
                        get: { summary.countermeasures },
                        set: { summary.countermeasures = $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                }
                
                // Pit Notes
                Section("Pit Notes") {
                    Picker("Battery Health", selection: Binding(
                        get: { summary.pitNotes.batteryHealth },
                        set: { summary.pitNotes.batteryHealth = $0 }
                    )) {
                        Text("Good").tag("Good")
                        Text("Marginal").tag("Marginal")
                        Text("Poor").tag("Poor")
                        Text("Unknown").tag("Unknown")
                    }
                    
                    ForEach(Array(summary.pitNotes.knownFailureModes.enumerated()), id: \.offset) { index, _ in
                        TextField("Failure Mode \(index + 1)", text: Binding(
                            get: { summary.pitNotes.knownFailureModes[index] },
                            set: { summary.pitNotes.knownFailureModes[index] = $0 }
                        ))
                    }
                    .onDelete { indexSet in
                        summary.pitNotes.knownFailureModes.remove(atOffsets: indexSet)
                    }
                    
                    Button {
                        summary.pitNotes.knownFailureModes.append("")
                    } label: {
                        Label("Add Failure Mode", systemImage: "plus.circle")
                    }
                    
                    TextField("Human Factors", text: Binding(
                        get: { summary.pitNotes.humanFactors },
                        set: { summary.pitNotes.humanFactors = $0 }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                }
                
                // Quick Action Items
                Section {
                    ForEach(Array(summary.quickActionItems.enumerated()), id: \.offset) { index, _ in
                        TextField("Action Item \(index + 1)", text: Binding(
                            get: { summary.quickActionItems[index] },
                            set: { summary.quickActionItems[index] = $0 }
                        ))
                    }
                    .onDelete { indexSet in
                        summary.quickActionItems.remove(atOffsets: indexSet)
                    }
                    
                    if summary.quickActionItems.count < 3 {
                        Button {
                            summary.quickActionItems.append("")
                        } label: {
                            Label("Add Action Item", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("Quick Action Items (max 3)")
                }
            }
            .navigationTitle("Edit Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveSummary()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }
    
    private func saveSummary() async {
        isSaving = true
        defer { isSaving = false }
        
        // Filter out empty strings
        summary.strengths = summary.strengths.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        summary.weaknesses = summary.weaknesses.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        summary.pitNotes.knownFailureModes = summary.pitNotes.knownFailureModes.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        summary.quickActionItems = summary.quickActionItems.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        do {
            try await summaryService.saveSummary(summary)
            dismiss()
        } catch {
            // Error handling - could show alert
        }
    }
}

#Preview {
    TeamSummaryEditView(summary: TeamScoutingSummary.sample)
        .environmentObject(TeamSummaryService())
}

