//
//  EditScoutingReportView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct EditScoutingReportView: View {
    let report: ScoutingReport
    @EnvironmentObject var scoutingService: ScoutingService
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Enumerations
    enum StartingPosition: String, CaseIterable, Identifiable {
        case gate1 = "Gate 1"
        case gate2 = "Gate 2"
        case gate3 = "Gate 3"
        case depot = "Depot"
        case audience = "Audience Side"
        
        var id: String { rawValue }
    }
    
    enum PreloadArtifact: String, CaseIterable, Identifiable {
        case green = "Green Artifact"
        case purple = "Purple Artifact"
        case none = "None"
        
        var id: String { rawValue }
    }
    
    enum RandomizationMotif: String, CaseIterable, Identifiable {
        case unknown = "Not Observed"
        case motif1 = "Motif 1"
        case motif2 = "Motif 2"
        case motif3 = "Motif 3"
        
        var id: String { rawValue }
    }
    
    enum StrategyFocus: String, CaseIterable, Identifiable {
        case overflowCycles = "Overflow Cycling"
        case classifiedStacks = "Classified Stacking"
        case support = "Support / Feeder"
        case defense = "Disrupt / Defense"
        case mixed = "Balanced Mixed"
        
        var id: String { rawValue }
    }
    
    enum DriveBase: String, CaseIterable, Identifiable {
        case mecanum = "Mecanum"
        case tank = "Tank / Kitbot"
        case omni = "Omni"
        case swerve = "Swerve"
        case other = "Other"
        
        var id: String { rawValue }
    }
    
    enum BaseDockResult: String, CaseIterable, Identifiable {
        case none = "None"
        case partial = "Partial"
        case full = "Full"
        
        var id: String { rawValue }
    }
    
    enum ReliabilityLevel: String, CaseIterable, Identifiable {
        case veryReliable = "Very Reliable"
        case mostlyReliable = "Mostly Reliable"
        case inconsistent = "Inconsistent"
        case oftenBroken = "Often Broken"
        
        var id: String { rawValue }
    }
    
    // MARK: - Basic Match Info
    @State private var scoutedTeamNumber: String = ""
    @State private var matchNumber: String = ""
    @State private var allianceColor: String = "Red"
    @State private var eventName: String = ""
    @State private var startingPosition: StartingPosition = .gate1
    @State private var preloadArtifact: PreloadArtifact = .green
    @State private var driveBase: DriveBase = .mecanum
    @State private var matchPhase: MatchPhase = .teleop
    
    // MARK: - Autonomous
    @State private var observedMotif: RandomizationMotif = .unknown
    @State private var autoClassifiedArtifacts: Int = 0
    @State private var autoOverflowArtifacts: Int = 0
    @State private var robot1AutoLeaves: Bool = false
    @State private var robot2AutoLeaves: Bool = false
    @State private var autoPatternSuccess: Bool = false
    @State private var autoReliability: Int = 3
    
    // MARK: - Teleop
    @State private var teleopClassifiedArtifacts: Int = 0
    @State private var teleopOverflowArtifacts: Int = 0
    @State private var teleopDepotCycles: Int = 0
    @State private var allianceCoordination: Bool = false
    @State private var drivingQuality: Double = 3.0
    @State private var robotSpeed: Double = 3.0
    @State private var strategyFocus: StrategyFocus = .overflowCycles
    @State private var defendsWell: Bool = false
    @State private var penaltiesCommitted: Int = 0
    
    // MARK: - Endgame & Ranking
    @State private var robot1BaseResult: BaseDockResult = .none
    @State private var robot2BaseResult: BaseDockResult = .none
    @State private var parkedInZone: Bool = false
    @State private var endgameExecution: Int = 3
    @State private var earnedMovementRP: Bool = false
    @State private var earnedGoalRP: Bool = false
    @State private var earnedPatternRP: Bool = false
    
    // MARK: - Assessment
    @State private var overallQuality: Double = 3.0
    @State private var allianceSelectionRating: Double = 3.0
    @State private var reliabilityLevel: ReliabilityLevel = .mostlyReliable
    @State private var artifactStrategyNotes: String = ""
    @State private var generalNotes: String = ""
    @State private var allianceNotes: String = ""
    
    @State private var isSubmitting = false
    
    private let allianceColors = ["Red", "Blue"]
    
    init(report: ScoutingReport) {
        self.report = report
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    if geometry.size.width > geometry.size.height {
                    // Landscape layout
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            header
                            matchInformation
                            autonomousSection
                        }
                        .frame(maxWidth: .infinity)
                        
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            teleopSection
                            endgameSection
                            assessmentSection
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(DesignSystem.Spacing.md)
                    
                    submitButton
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.bottom, DesignSystem.Spacing.lg)
                } else {
                    // Portrait layout
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        header
                        matchInformation
                        autonomousSection
                        teleopSection
                        endgameSection
                        assessmentSection
                        submitButton
                    }
                    .padding(DesignSystem.Spacing.md)
                    }
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Edit Scout Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .onAppear {
            loadReportData()
        }
        .alert("Error", isPresented: Binding(get: { scoutingService.errorMessage != nil }, set: { _ in scoutingService.errorMessage = nil })) {
            Button("OK") { }
        } message: {
            Text(scoutingService.errorMessage ?? "An unknown error occurred.")
        }
    }
    
    private func loadReportData() {
        scoutedTeamNumber = report.scoutedTeamNumber
        matchNumber = report.matchNumber ?? ""
        eventName = report.eventName ?? ""
        
        // Load from reportData dictionary
        if let alliance = report.reportData["Alliance Color"] {
            allianceColor = alliance
        }
        
        if let startingPos = report.reportData["Starting Position"],
           let pos = StartingPosition(rawValue: startingPos) {
            startingPosition = pos
        }
        
        if let preload = report.reportData["Preload Artifact"],
           let artifact = PreloadArtifact(rawValue: preload) {
            preloadArtifact = artifact
        }
        
        if let drive = report.reportData["Drive Base"],
           let base = DriveBase(rawValue: drive) {
            driveBase = base
        }
        
        if let phase = report.phase {
            matchPhase = phase
        }
        
        if let motif = report.reportData["Observed Randomization"],
           let randomMotif = RandomizationMotif(rawValue: motif) {
            observedMotif = randomMotif
        }
        
        autoClassifiedArtifacts = Int(report.reportData["Auto Classified Artifacts"] ?? "0") ?? 0
        autoOverflowArtifacts = Int(report.reportData["Auto Overflow Artifacts"] ?? "0") ?? 0
        robot1AutoLeaves = report.boolValue(for: "Robot 1 Auto Leave") ?? false
        robot2AutoLeaves = report.boolValue(for: "Robot 2 Auto Leave") ?? false
        autoPatternSuccess = report.boolValue(for: "Auto Pattern Success") ?? false
        autoReliability = Int(report.reportData["Autonomous Reliability"] ?? "3") ?? 3
        
        teleopClassifiedArtifacts = Int(report.reportData["Teleop Classified Artifacts"] ?? "0") ?? 0
        teleopOverflowArtifacts = Int(report.reportData["Teleop Overflow Artifacts"] ?? "0") ?? 0
        teleopDepotCycles = Int(report.reportData["Teleop Depot Cycles"] ?? "0") ?? 0
        allianceCoordination = report.boolValue(for: "Alliance Coordination") ?? false
        drivingQuality = Double(report.reportData["Driving Quality"] ?? "3") ?? 3.0
        robotSpeed = Double(report.reportData["Robot Speed"] ?? "3") ?? 3.0
        
        if let strategy = report.reportData["Strategy Focus"],
           let focus = StrategyFocus(rawValue: strategy) {
            strategyFocus = focus
        }
        
        defendsWell = report.boolValue(for: "Defends Well") ?? false
        penaltiesCommitted = Int(report.reportData["Penalties Observed"] ?? "0") ?? 0
        
        if let robot1 = report.reportData["Robot 1 Base Result"],
           let result1 = BaseDockResult(rawValue: robot1) {
            robot1BaseResult = result1
        }
        
        if let robot2 = report.reportData["Robot 2 Base Result"],
           let result2 = BaseDockResult(rawValue: robot2) {
            robot2BaseResult = result2
        }
        
        parkedInZone = report.boolValue(for: "Parked In Base Zone") ?? false
        endgameExecution = Int(report.reportData["Endgame Execution"] ?? "3") ?? 3
        earnedMovementRP = report.boolValue(for: "Movement RP") ?? false
        earnedGoalRP = report.boolValue(for: "Goal RP") ?? false
        earnedPatternRP = report.boolValue(for: "Pattern RP") ?? false
        
        overallQuality = Double(report.reportData["Overall Quality"] ?? "3") ?? 3.0
        allianceSelectionRating = Double(report.reportData["Alliance Selection Rating"] ?? "3") ?? 3.0
        
        if let reliability = report.reportData["Reliability Level"],
           let level = ReliabilityLevel(rawValue: reliability) {
            reliabilityLevel = level
        }
        
        artifactStrategyNotes = report.reportData["Artifact Strategy Notes"] ?? ""
        generalNotes = report.notes ?? report.reportData["General Notes"] ?? ""
        allianceNotes = report.reportData["Alliance Selection Notes"] ?? ""
    }
    
    private var header: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 50))
                .foregroundStyle(DesignSystem.Gradients.primary)
                .shadow(color: DesignSystem.Colors.shadow, radius: 10, x: 0, y: 4)
            Text("Edit Scout Report")
                .font(.title.weight(.bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Text("Team \(report.scoutedTeamNumber)")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.top, DesignSystem.Spacing.lg)
    }
    
    private var matchInformation: some View {
        CardView(title: "Match Overview", icon: "info.circle") {
            VStack(spacing: DesignSystem.Spacing.md) {
                CustomTextField(title: "Team Number", text: $scoutedTeamNumber, placeholder: "e.g., 12345", keyboardType: .numberPad)
                CustomTextField(title: "Match Number", text: $matchNumber, placeholder: "e.g., Q1, SF1-2")
                CustomTextField(title: "Event Name", text: $eventName, placeholder: "Optional")
                
                Picker("Alliance Color", selection: $allianceColor) {
                    ForEach(allianceColors, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                
                Picker("Starting Position", selection: $startingPosition) {
                    ForEach(StartingPosition.allCases) { Text($0.rawValue).tag($0) }
                }
                
                Picker("Preload Artifact", selection: $preloadArtifact) {
                    ForEach(PreloadArtifact.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                
                Picker("Drive Base", selection: $driveBase) {
                    ForEach(DriveBase.allCases) { Text($0.rawValue).tag($0) }
                }
                
                Picker("Match Phase", selection: $matchPhase) {
                    ForEach(MatchPhase.allCases, id: \.self) { phase in
                        Text(phase.displayName).tag(phase)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var autonomousSection: some View {
        CardView(title: "Autonomous Insights (30 sec)", icon: "play.circle.fill") {
            VStack(spacing: DesignSystem.Spacing.md) {
                Picker("Randomization Observed", selection: $observedMotif) {
                    ForEach(RandomizationMotif.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    StepperRow(title: "Classified Artifacts", value: $autoClassifiedArtifacts, range: 0...20)
                    StepperRow(title: "Overflow Artifacts", value: $autoOverflowArtifacts, range: 0...20)
                }
                
                Toggle("Robot 1 leaves starting position", isOn: $robot1AutoLeaves)
                Toggle("Robot 2 leaves starting position", isOn: $robot2AutoLeaves)
                Toggle("Matches published motif pattern", isOn: $autoPatternSuccess)
                
                RatingRow(title: "Autonomous Reliability", rating: $autoReliability)
            }
        }
    }
    
    private var teleopSection: some View {
        CardView(title: "Teleop Cycle Study (120 sec)", icon: "person.circle.fill") {
            VStack(spacing: DesignSystem.Spacing.md) {
                StepperRow(title: "Classified Artifacts", value: $teleopClassifiedArtifacts, range: 0...75)
                StepperRow(title: "Overflow Artifacts", value: $teleopOverflowArtifacts, range: 0...75)
                StepperRow(title: "Depot Cycles", value: $teleopDepotCycles, range: 0...60)
                
                Toggle("Alliance coordination on cycles", isOn: $allianceCoordination)
                Toggle("Defends effectively", isOn: $defendsWell)
                
                Picker("Primary strategy focus", selection: $strategyFocus) {
                    ForEach(StrategyFocus.allCases) { Text($0.rawValue).tag($0) }
                }
                
                SliderRow(title: "Driving Quality", value: $drivingQuality, lowLabel: "Inconsistent", highLabel: "Elite")
                SliderRow(title: "Robot Speed", value: $robotSpeed, lowLabel: "Slow", highLabel: "Fast")
                StepperRow(title: "Rule infractions observed", value: $penaltiesCommitted, range: 0...15)
            }
        }
    }
    
    private var endgameSection: some View {
        CardView(title: "Endgame & Ranking Points", icon: "flag.circle.fill") {
            VStack(spacing: DesignSystem.Spacing.md) {
                Picker("Robot 1 base result", selection: $robot1BaseResult) {
                    ForEach(BaseDockResult.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                
                Picker("Robot 2 base result", selection: $robot2BaseResult) {
                    ForEach(BaseDockResult.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                
                Toggle("Alliance parked in base zone", isOn: $parkedInZone)
                
                RankingToggleRow(title: "Movement RP achieved", help: "16+ leave/base points", isOn: $earnedMovementRP)
                RankingToggleRow(title: "Goal RP achieved", help: "36 artifacts scored", isOn: $earnedGoalRP)
                RankingToggleRow(title: "Pattern RP achieved", help: "18 pattern points", isOn: $earnedPatternRP)
                
                RatingRow(title: "Endgame execution", rating: $endgameExecution)
            }
        }
    }
    
    private var assessmentSection: some View {
        CardView(title: "Alliance Fit & Notes", icon: "chart.bar.fill") {
            VStack(spacing: DesignSystem.Spacing.md) {
                SliderRow(title: "Overall team quality", value: $overallQuality, lowLabel: "1", highLabel: "5")
                SliderRow(title: "Alliance selection rating", value: $allianceSelectionRating, lowLabel: "1", highLabel: "5")
                
                Picker("Reliability level", selection: $reliabilityLevel) {
                    ForEach(ReliabilityLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                
                NotesEditor(title: "Artifact strategy notes", text: $artifactStrategyNotes)
                NotesEditor(title: "General observations", text: $generalNotes)
                NotesEditor(title: "Alliance selection notes", text: $allianceNotes)
            }
        }
    }
    
    private var submitButton: some View {
        Button {
            Task { await updateReport() }
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isSubmitting ? "Updating..." : "Update Scouting Report")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? DesignSystem.Gradients.primary : DesignSystem.Gradients.secondary)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .disabled(!isFormValid || isSubmitting)
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.bottom, DesignSystem.Spacing.xl)
    }
    
    private var isFormValid: Bool {
        !scoutedTeamNumber.isEmpty && !matchNumber.isEmpty
    }
    
    private func updateReport() async {
        isSubmitting = true
        defer { isSubmitting = false }
        
        let reportData: [String: String] = [
            "Alliance Color": allianceColor,
            "Starting Position": startingPosition.rawValue,
            "Preload Artifact": preloadArtifact.rawValue,
            "Drive Base": driveBase.rawValue,
            "Match Phase": matchPhase.rawValue,
            "Observed Randomization": observedMotif.rawValue,
            "Auto Classified Artifacts": String(autoClassifiedArtifacts),
            "Auto Overflow Artifacts": String(autoOverflowArtifacts),
            "Robot 1 Auto Leave": robot1AutoLeaves ? "true" : "false",
            "Robot 2 Auto Leave": robot2AutoLeaves ? "true" : "false",
            "Auto Pattern Success": autoPatternSuccess ? "true" : "false",
            "Autonomous Reliability": String(autoReliability),
            "Teleop Classified Artifacts": String(teleopClassifiedArtifacts),
            "Teleop Overflow Artifacts": String(teleopOverflowArtifacts),
            "Teleop Depot Cycles": String(teleopDepotCycles),
            "Alliance Coordination": allianceCoordination ? "true" : "false",
            "Driving Quality": String(Int(drivingQuality)),
            "Robot Speed": String(Int(robotSpeed)),
            "Strategy Focus": strategyFocus.rawValue,
            "Defends Well": defendsWell ? "true" : "false",
            "Penalties Observed": String(penaltiesCommitted),
            "Robot 1 Base Result": robot1BaseResult.rawValue,
            "Robot 2 Base Result": robot2BaseResult.rawValue,
            "Parked In Base Zone": parkedInZone ? "true" : "false",
            "Endgame Execution": String(endgameExecution),
            "Movement RP": earnedMovementRP ? "true" : "false",
            "Goal RP": earnedGoalRP ? "true" : "false",
            "Pattern RP": earnedPatternRP ? "true" : "false",
            "Overall Quality": String(Int(overallQuality)),
            "Alliance Selection Rating": String(Int(allianceSelectionRating)),
            "Reliability Level": reliabilityLevel.rawValue,
            "Artifact Strategy Notes": artifactStrategyNotes,
            "General Notes": generalNotes,
            "Alliance Selection Notes": allianceNotes
        ]
        
        var updatedReport = report
        updatedReport.scoutedTeamNumber = scoutedTeamNumber
        updatedReport.matchNumber = matchNumber.isEmpty ? nil : matchNumber
        updatedReport.eventName = eventName.isEmpty ? nil : eventName
        updatedReport.phase = matchPhase
        updatedReport.reportData = reportData
        updatedReport.notes = generalNotes
        updatedReport.updatedAt = Date()
        
        do {
            try await scoutingService.updateScoutingReport(report: updatedReport)
            dismiss()
        } catch {
            // Error is already set in scoutingService.errorMessage
            // The alert will show it automatically
            DebugLog.log("Failed to update report: \(error)")
        }
    }
}

// MARK: - Helper Views (reuse from CreateScoutingReportView)
private struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
            HStack(spacing: DesignSystem.Spacing.md) {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value > range.lowerBound ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                }
                .disabled(value <= range.lowerBound)
                
                Text("\(value)")
                    .font(.title3.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(minWidth: 50)
                    .multilineTextAlignment(.center)
                
                Button {
                    if value < range.upperBound {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value < range.upperBound ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                }
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let lowLabel: String
    let highLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Slider(value: $value, in: 1...5, step: 1)
            HStack {
                Text(lowLabel)
                Spacer()
                Text("\(Int(value))")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(highLabel)
            }
            .font(.caption)
            .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

private struct RatingRow: View {
    let title: String
    @Binding var rating: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        rating = star
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(star <= rating ? .yellow : DesignSystem.Colors.textTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
                Text("\(rating)/5")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

private struct RankingToggleRow: View {
    let title: String
    let help: String
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Toggle(title, isOn: $isOn)
            Text(help)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

private struct NotesEditor: View {
    let title: String
    @Binding var text: String
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            TextEditor(text: $text)
                .frame(height: 80)
                .padding(8)
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .stroke(isFocused ? DesignSystem.Colors.primary : DesignSystem.Colors.border, lineWidth: isFocused ? 2 : 1)
                )
                .focused($isFocused)
        }
    }
}

#Preview {
    NavigationView {
        EditScoutingReportView(report: ScoutingReport.sample)
            .environmentObject(ScoutingService())
    }
}

