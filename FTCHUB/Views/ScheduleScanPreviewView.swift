//
//  ScheduleScanPreviewView.swift
//  FTCHUB
//
//  Created for Schedule Scanning Feature - Phase 2
//  Preview and edit view for scanned match schedules
//

import SwiftUI

struct ScheduleScanPreviewView: View {
    @EnvironmentObject var scanService: ScheduleScanService
    @EnvironmentObject var scheduleService: ScheduleService
    @EnvironmentObject var teamService: TeamService
    @StateObject private var toastManager = ToastManager()
    @Environment(\.dismiss) private var dismiss
    @Binding var shouldDismissScanner: Bool
    
    let scanResult: ScheduleScanResult
    let extractedMatches: [ExtractedMatchData]
    
    @State private var matchDrafts: [MatchDraft] = []
    @State private var editableMatches: [EditableMatchData] = []
    @State private var eventName: String = ""
    @State private var scheduleDate: Date = Date()
    @State private var seasonYear: Int = Calendar.current.component(.year, from: Date())
    @State private var allianceColor: AllianceColor = .red
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingConfirmation = false
    @State private var duplicateMatches: [String] = []
    @State private var importProgress: Double = 0.0
    
    init(scanResult: ScheduleScanResult, extractedMatches: [ExtractedMatchData], shouldDismissScanner: Binding<Bool> = .constant(false)) {
        self.scanResult = scanResult
        self.extractedMatches = extractedMatches
        self._shouldDismissScanner = shouldDismissScanner
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Summary Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("\(extractedMatches.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.primary)
                            Text("Matches Found")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if !duplicateMatches.isEmpty {
                            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                                Text("\(duplicateMatches.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.Colors.warning)
                                Text("Duplicates")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                    }
                    
                    if !duplicateMatches.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Duplicate matches detected:")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            Text(duplicateMatches.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                    }
                } header: {
                    Text("Scan Summary")
                }
                
                // Additional Information Section
                Section {
                    TextField("Event Name", text: $eventName)
                    
                    DatePicker("Schedule Date", selection: $scheduleDate, displayedComponents: [.date])
                    
                    Picker("Season Year", selection: $seasonYear) {
                        ForEach(2015..<2030) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                } header: {
                    Text("Additional Information")
                }
                
                // Matches Section
                Section {
                    if editableMatches.isEmpty {
                        Text("No matches found")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    } else {
                        ForEach(editableMatches.indices, id: \.self) { index in
                            MatchPreviewRow(
                                match: $editableMatches[index],
                                confidence: extractedMatches[index].confidence,
                                warnings: extractedMatches[index].warnings
                            )
                        }
                    }
                } header: {
                    Text("Extracted Matches")
                } footer: {
                    if !editableMatches.isEmpty {
                        Text("Review and edit the extracted match data before importing.")
                    }
                }
            }
            .navigationTitle("Review Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        checkForDuplicatesAndConfirm()
                    }
                    .disabled(editableMatches.isEmpty || isImporting)
                }
            }
            .onAppear {
                setupEditableMatches()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Confirm Import", isPresented: $showingConfirmation) {
                Button("Import", role: .none) {
                    importMatches()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You are about to import \(editableMatches.count) match(es).")
                    
                    if !duplicateMatches.isEmpty {
                        Text("\nWarning: \(duplicateMatches.count) duplicate match(es) detected. They will be imported anyway.")
                            .foregroundColor(.orange)
                    }
                    
                    if !eventName.isEmpty {
                        Text("\nEvent: \(eventName)")
                    }
                }
            }
            .onAppear {
                checkForDuplicates()
            }
        }
    }
    
    private func setupEditableMatches() {
        // Convert extracted matches to editable format
        editableMatches = extractedMatches.map { extracted in
            var editable = EditableMatchData(from: extracted)
            // Parse time if available
            if let timeString = extracted.scheduledTime {
                if let parsedTime = ScheduleDataMapper.parseTimeString(timeString, baseDate: scheduleDate) {
                    editable.scheduledTime = parsedTime
                }
            }
            return editable
        }
        
        // Convert to MatchDrafts for import (will be updated when importing)
        matchDrafts = scanService.convertToMatchDrafts(
            from: extractedMatches,
            baseDate: scheduleDate,
            defaultAllianceColor: allianceColor
        )
    }
    
    private func checkForDuplicates() {
        guard scheduleService.hasTeamContext else { return }
        
        let existingMatchNumbers = Set(scheduleService.matches.map { $0.matchNumber })
        duplicateMatches = editableMatches
            .map { $0.matchNumber }
            .filter { existingMatchNumbers.contains($0) }
    }
    
    private func checkForDuplicatesAndConfirm() {
        checkForDuplicates()
        showingConfirmation = true
    }
    
    private func importMatches() {
        guard scheduleService.hasTeamContext else {
            errorMessage = "You must be part of a team to import matches."
            showingError = true
            return
        }
        
        isImporting = true
        importProgress = 0.0
        errorMessage = nil
        
        Task {
            do {
                // Build match drafts from editable matches
                var draftsToImport: [MatchDraft] = []
                let totalMatches = editableMatches.count
                
                for (index, editable) in editableMatches.enumerated() {
                    guard !editable.matchNumber.isEmpty else { continue }
                    
                    let red1 = Int(editable.redTeam1)
                    let red2 = Int(editable.redTeam2)
                    let blue1 = Int(editable.blueTeam1)
                    let blue2 = Int(editable.blueTeam2)
                    
                    let (partner1, partner2, opponent1, opponent2): (Int?, Int?, Int?, Int?)
                    if allianceColor == .red {
                        partner1 = red1
                        partner2 = red2
                        opponent1 = blue1
                        opponent2 = blue2
                    } else {
                        partner1 = blue1
                        partner2 = blue2
                        opponent1 = red1
                        opponent2 = red2
                    }
                    
                    // Create draft with event name and season year
                    let draft = MatchDraft(
                        matchNumber: editable.matchNumber,
                        scheduledTime: editable.scheduledTime,
                        allianceColor: allianceColor,
                        alliancePartner1: partner1,
                        alliancePartner2: partner2,
                        opponent1: opponent1,
                        opponent2: opponent2,
                        status: .scheduled
                    )
                    // Note: MatchDraft doesn't have eventName/seasonYear fields
                    // These will need to be set on the Match after creation
                    draftsToImport.append(draft)
                    
                    // Update progress
                    await MainActor.run {
                        importProgress = Double(index + 1) / Double(totalMatches) * 0.8 // 80% for building drafts
                    }
                }
                
                // Import matches with progress updates
                var successCount = 0
                var failureCount = 0
                var lastError: Error?
                
                for (index, draft) in draftsToImport.enumerated() {
                    do {
                        // Create match using createMatch which handles the database insert
                        try await scheduleService.createMatch(from: draft)
                        
                        // Update the match with event name and season year if provided
                        // We need to find the newly created match and update it
                        await scheduleService.loadMatches()
                        
                        // Find the match we just created (by match number and scheduled time)
                        if let createdMatch = scheduleService.matches.first(where: { 
                            $0.matchNumber == draft.matchNumber && 
                            abs($0.scheduledTime.timeIntervalSince(draft.scheduledTime)) < 60 // Within 1 minute
                        }) {
                            // Update with event name and season year if provided
                            if !eventName.isEmpty || seasonYear != Calendar.current.component(.year, from: Date()) {
                                var matchToUpdate = createdMatch
                                matchToUpdate.eventName = eventName.isEmpty ? nil : eventName
                                matchToUpdate.seasonYear = seasonYear
                                
                                // Update red/blue team fields based on allianceColor
                                if matchToUpdate.allianceColor == .red {
                                    matchToUpdate.redTeam1 = draft.alliancePartner1.map(String.init)
                                    matchToUpdate.redTeam2 = draft.alliancePartner2.map(String.init)
                                    matchToUpdate.blueTeam1 = draft.opponent1.map(String.init)
                                    matchToUpdate.blueTeam2 = draft.opponent2.map(String.init)
                                } else {
                                    matchToUpdate.blueTeam1 = draft.alliancePartner1.map(String.init)
                                    matchToUpdate.blueTeam2 = draft.alliancePartner2.map(String.init)
                                    matchToUpdate.redTeam1 = draft.opponent1.map(String.init)
                                    matchToUpdate.redTeam2 = draft.opponent2.map(String.init)
                                }
                                
                                let updateDraft = MatchDraft(from: matchToUpdate)
                                try await scheduleService.updateMatch(createdMatch, with: updateDraft)
                            }
                        }
                        
                        successCount += 1
                    } catch {
                        failureCount += 1
                        lastError = error
                        // Continue importing other matches even if one fails
                    }
                    
                    // Update progress (80-100% for importing)
                    await MainActor.run {
                        importProgress = 0.8 + (Double(index + 1) / Double(draftsToImport.count) * 0.2)
                    }
                }
                
                await MainActor.run {
                    isImporting = false
                    importProgress = 0.0
                    
                    if successCount > 0 {
                        // Show success toast
                        toastManager.showSuccess("Successfully imported \(successCount) match(es)")
                        
                        // Dismiss both preview and scanner views after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            shouldDismissScanner = true
                            dismiss()
                        }
                    } else {
                        // All failed
                        errorMessage = lastError?.localizedDescription ?? "Failed to import matches"
                        showingError = true
                    }
                    
                    if failureCount > 0 && successCount > 0 {
                        // Partial success
                        toastManager.showWarning("Imported \(successCount) match(es), \(failureCount) failed")
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isImporting = false
                    importProgress = 0.0
                }
            }
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.7 {
            return DesignSystem.Colors.success
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return DesignSystem.Colors.error
        }
    }
}

// MARK: - Editable Match Data

struct EditableMatchData: Identifiable {
    let id: UUID
    var matchNumber: String
    var scheduledTime: Date
    var redTeam1: String
    var redTeam2: String
    var blueTeam1: String
    var blueTeam2: String
    
    init(from extracted: ExtractedMatchData) {
        self.id = extracted.id
        self.matchNumber = extracted.matchNumber ?? ""
        self.scheduledTime = Date() // Will be parsed from time string
        self.redTeam1 = extracted.redTeam1 ?? ""
        self.redTeam2 = extracted.redTeam2 ?? ""
        self.blueTeam1 = extracted.blueTeam1 ?? ""
        self.blueTeam2 = extracted.blueTeam2 ?? ""
    }
}

// MARK: - Match Preview Row

struct MatchPreviewRow: View {
    @Binding var match: EditableMatchData
    let confidence: Double
    let warnings: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            TextField("Match Number", text: $match.matchNumber)
                .font(.headline)
            
            DatePicker("Time", selection: $match.scheduledTime, displayedComponents: [.date, .hourAndMinute])
            
            HStack(spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Red Alliance")
                        .font(.caption)
                        .foregroundColor(.red)
                    TextField("Team 1", text: $match.redTeam1)
                        .keyboardType(.numberPad)
                    TextField("Team 2", text: $match.redTeam2)
                        .keyboardType(.numberPad)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Blue Alliance")
                        .font(.caption)
                        .foregroundColor(.blue)
                    TextField("Team 1", text: $match.blueTeam1)
                        .keyboardType(.numberPad)
                    TextField("Team 2", text: $match.blueTeam2)
                        .keyboardType(.numberPad)
                }
                .frame(maxWidth: .infinity)
            }
            
            if !warnings.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(warnings, id: \.self) { warning in
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(warning)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

struct ConfidenceBadge: View {
    let confidence: Double
    
    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 4)
            .background(confidenceColor)
            .cornerRadius(DesignSystem.CornerRadius.sm)
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.7 {
            return DesignSystem.Colors.success
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return DesignSystem.Colors.error
        }
    }
}
