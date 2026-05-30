//
//  DriveTeamTimerView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// Move TimerMode outside view to avoid Swift 6 concurrency issues
enum TimerMode: Equatable, Sendable {
    case phaseBased
    case competition
    
    var displayName: String {
        switch self {
        case .phaseBased: return "Phase Based"
        case .competition: return "Competition"
        }
    }
    
    // Explicit Equatable conformance to avoid main actor isolation issues
    static func == (lhs: TimerMode, rhs: TimerMode) -> Bool {
        switch (lhs, rhs) {
        case (.phaseBased, .phaseBased), (.competition, .competition):
            return true
        default:
            return false
        }
    }
}

struct DriveTeamTimerView: View {
    
    @State private var timeRemaining = 30 // Start with auto phase duration
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var currentPhase: MatchPhase = .auto
    @State private var hasPhaseInitialized = false
    @State private var timerMode: TimerMode = .phaseBased
    @State private var showingWarning = false
    @State private var warningMessage = ""
    @State private var lastWarningTime: Int = -1
    @State private var phaseDotPulsing = false
    
#if canImport(UIKit)
    @State private var feedbackGenerator = UINotificationFeedbackGenerator()
    @State private var impactGenerator = UIImpactFeedbackGenerator(style: .medium)
#endif
    
    private var phaseBinding: Binding<MatchPhase> {
        Binding {
            currentPhase
        } set: { newValue in
            if hasPhaseInitialized {
                currentPhase = newValue
                resetTimer()
            } else {
                hasPhaseInitialized = true
                currentPhase = newValue
            }
        }
    }
    
    private var phaseName: String {
        if currentPhase == MatchPhase.auto {
            return "Autonomous"
        } else if currentPhase == MatchPhase.teleop {
            return "Teleop"
        } else {
            return "Endgame"
        }
    }
    
    private var phaseDuration: Int {
        if timerMode == .competition {
            return 150 // 2:30 for competition mode
        }
        if currentPhase == MatchPhase.auto {
            return 30
        } else if currentPhase == MatchPhase.teleop {
            return 120
        } else {
            return 30
        }
    }
    
    private var competitionWarnings: [(time: Int, message: String)] {
        [
            (120, "2:00 - Endgame starting soon"),
            (90, "1:30 - One minute remaining"),
            (30, "0:30 - Thirty seconds remaining"),
            (10, "0:10 - Final countdown!")
        ]
    }
    
    private var phaseColor: Color {
        if currentPhase == MatchPhase.auto {
            return DesignSystem.Colors.primary
        } else if currentPhase == MatchPhase.teleop {
            return DesignSystem.Colors.accent
        } else {
            return DesignSystem.Colors.error // Red for endgame
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Mode selector at top
                    modeSelector
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.lg)
                        .padding(.bottom, DesignSystem.Spacing.md)
                    
                    // Timer display - main focal point
                    timerDisplay()
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    
                    // Phase indicator
                    phaseIndicator
                        .padding(.top, DesignSystem.Spacing.sm)
                        .padding(.bottom, DesignSystem.Spacing.md)
                    
                    // Warning banner
                    warningBanner
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.bottom, DesignSystem.Spacing.lg)
                    
                    // Controls section
                    controlsSection
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            }
            .tabBarScrollInset()
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Drive Team Timer")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Match Warning", isPresented: $showingWarning) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(warningMessage)
            }
        }
    }
    
    private var modeSelector: some View {
        SegmentedPillToggle(
            segments: [
                SegmentedPillSegment(
                    id: TimerMode.phaseBased.displayName,
                    title: "Phase Based",
                    selectedColor: DesignSystem.Colors.primary
                ),
                SegmentedPillSegment(
                    id: TimerMode.competition.displayName,
                    title: "Competition",
                    selectedColor: DesignSystem.Colors.primary
                )
            ],
            selectedID: Binding(
                get: { timerMode.displayName },
                set: { newValue in
                    if newValue == TimerMode.phaseBased.displayName {
                        timerMode = .phaseBased
                    } else if newValue == TimerMode.competition.displayName {
                        timerMode = .competition
                    }
                }
            ),
            onSelect: { _ in
                resetTimer()
                #if canImport(UIKit)
                DesignSystem.Haptics.selection()
                #endif
            }
        )
    }
    
    private struct ModeButton: View {
        let title: String
        let icon: String
        let isSelected: Bool
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : color)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [color, color.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            DesignSystem.Colors.tertiaryBackground
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(isSelected ? Color.white.opacity(0.3) : color.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected ? color.opacity(0.3) : DesignSystem.Colors.shadow.opacity(0.1), radius: isSelected ? 8 : 2, x: 0, y: isSelected ? 4 : 1)
            }
        }
    }
    
    private var warningBanner: some View {
        Group {
            if showingWarning && !warningMessage.isEmpty {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                    Text(warningMessage)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                .padding(DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(DesignSystem.Colors.warning.opacity(0.15))
                .cornerRadius(DesignSystem.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var phaseIndicator: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            if timerMode == .competition {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "trophy.fill")
                        .font(.title3)
                        .foregroundColor(DesignSystem.Colors.accent)
                    Text("Competition Mode")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                Text("Full Match: 2:30")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            } else {
                Text("CURRENT PHASE")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .tracking(0.08)
            
            Text(phaseName)
                    .font(.system(size: 24, weight: .semibold))
                .foregroundColor(phaseColor)
            
            Text("\(phaseDuration) seconds")
                    .font(.system(size: 14, weight: .regular))
                .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    private func timerDisplay() -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Large timer display - main focal point
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(formatTime(timeRemaining))
                    .font(.system(size: 140, weight: .bold, design: .rounded))
                    .foregroundColor(timerColor)
                    .monospacedDigit()
                    .shadow(color: (timeRemaining <= 10 && isRunning) ? DesignSystem.Colors.error.opacity(0.5) : timerColor.opacity(0.3), radius: (timeRemaining <= 10 && isRunning) ? 30 : 20, x: 0, y: 10)
                    .scaleEffect((timeRemaining <= 10 && isRunning) ? 1.02 : 1.0)
                    .animation((timeRemaining <= 10 && isRunning) ? .easeInOut(duration: 0.5).repeatForever() : .default, value: timeRemaining)
                
                progressBarView
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
            .padding(.vertical, DesignSystem.Spacing.md)
            
            // Phase/status indicator
            if timerMode == .phaseBased {
                if timeRemaining <= 10 && timeRemaining > 0 {
                    Text("\(timeRemaining) seconds remaining")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.error)
                        .transition(.scale.combined(with: .opacity))
                }
            } else {
                let phase = getCompetitionPhase()
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // Pulsing dot when timer is running
                    Circle()
                        .fill(phase.color)
                        .frame(width: 10, height: 10)
                        .opacity(isRunning ? (phaseDotPulsing ? 0.4 : 1.0) : 1.0)
                        .animation(isRunning ? .easeInOut(duration: 1.0).repeatForever() : .default, value: phaseDotPulsing)
                        .shadow(color: phase.color.opacity(0.6), radius: isRunning ? 6 : 3, x: 0, y: 0)
                    Text(phase.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(phase.color)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(phase.color.opacity(0.15))
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(phase.color.opacity(0.3), lineWidth: 1.5)
                )
                .onChange(of: isRunning) { _, running in
                    phaseDotPulsing = running
                }
                .onAppear { phaseDotPulsing = isRunning }
            }
        }
    }
    
    private func getCompetitionPhase() -> (name: String, color: Color) {
        if timeRemaining > 120 {
            return ("Autonomous", DesignSystem.Colors.primary)
        } else if timeRemaining > 30 {
            return ("Teleop", DesignSystem.Colors.accent)
        } else {
            return ("Endgame", DesignSystem.Colors.error) // Red for endgame
        }
    }
    
    private var progressBarView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.28, green: 0.28, blue: 0.30, opacity: 1.0)) // gray-700
                    .frame(height: 6)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 3)
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: progressWidth(in: geometry), height: 6)
                    .animation(.linear(duration: 1.0), value: timeRemaining)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.5), radius: 4, x: 0, y: 2)
            }
        }
        .frame(height: 6)
    }
    
    private var progressColor: Color {
        if timerMode == .competition {
            return getCompetitionPhase().color
        }
        return phaseColor
    }
    
    private var controlsSection: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Button(action: toggleTimer) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.body)
                        Text(isRunning ? "Pause" : "Start")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Gradients.primary)
                    .foregroundColor(.white)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Button(action: resetTimer) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                            .font(.body)
                        Text("Reset")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.tertiaryBackground)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1.5)
                    )
                }
            }
            
            // Phase selector (only for phase-based mode) - moved below buttons
            if timerMode == .phaseBased {
        VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Select Phase")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
            HStack(spacing: DesignSystem.Spacing.md) {
                        PhaseButton(
                            phase: .auto,
                            isSelected: currentPhase == .auto,
                            color: DesignSystem.Colors.primary,
                            isDisabled: isRunning
                        ) {
                            if !isRunning {
                                currentPhase = .auto
                                resetTimer()
                            }
                        }
                        
                        PhaseButton(
                            phase: .teleop,
                            isSelected: currentPhase == .teleop,
                            color: DesignSystem.Colors.accent,
                            isDisabled: isRunning
                        ) {
                            if !isRunning {
                                currentPhase = .teleop
                                resetTimer()
                            }
                        }
                        
                        PhaseButton(
                            phase: .endgame,
                            isSelected: currentPhase == .endgame,
                            color: DesignSystem.Colors.secondary,
                            isDisabled: isRunning
                        ) {
                            if !isRunning {
                                currentPhase = .endgame
                                resetTimer()
                            }
                        }
                    }
                }
                .padding(.top, DesignSystem.Spacing.md)
            }
        }
    }
    
    private struct PhaseButton: View {
        let phase: MatchPhase
        let isSelected: Bool
        let color: Color
        let isDisabled: Bool
        let action: () -> Void
        
        private var phaseIcon: String {
            switch phase {
            case MatchPhase.auto: return "bolt.fill"
            case MatchPhase.teleop: return "timer"
            case MatchPhase.endgame: return "flag.checkered"
            }
        }
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.25) : color.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .shadow(color: (isSelected ? Color.white : color).opacity(0.3), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
                        
                        Image(systemName: phaseIcon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(isSelected ? .white : color)
                    }
                    
                    Text(phase.displayName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [color, color.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            DesignSystem.Colors.tertiaryBackground
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(isSelected ? Color.white.opacity(0.4) : color.opacity(0.3), lineWidth: isSelected ? 3 : 2)
                )
                .shadow(color: isSelected ? color.opacity(0.6) : DesignSystem.Colors.shadow.opacity(0.2), radius: isSelected ? 20 : 8, x: 0, y: isSelected ? 10 : 4)
                .opacity(isDisabled ? 0.5 : 1.0)
                .scaleEffect(isSelected ? 1.02 : 1.0)
            }
            .disabled(isDisabled)
        }
    }
    
    private var timerColor: Color {
        // Make timer red for endgame phase
        if timerMode == .phaseBased && currentPhase == .endgame {
            return DesignSystem.Colors.error
        } else if timerMode == .competition && timeRemaining <= 30 {
            return DesignSystem.Colors.error
        } else if timeRemaining <= 5 {
            return DesignSystem.Colors.error
        } else if timeRemaining <= 10 {
            return DesignSystem.Colors.warning
        } else {
            return DesignSystem.Colors.textPrimary
        }
    }
    
    private func progressWidth(in geometry: GeometryProxy) -> CGFloat {
        let progress = Double(phaseDuration - timeRemaining) / Double(phaseDuration)
        return geometry.size.width * CGFloat(max(0, min(1, progress)))
    }
    
    private func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        // Capture timerMode to avoid main actor isolation issues in timer closure
        let currentMode = timerMode
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
                
                // Check for competition mode warnings
                if currentMode == .competition {
                    self.checkCompetitionWarnings()
                }
                
                // Haptic feedback at critical times
                #if canImport(UIKit)
                if currentMode == .competition {
                    // Competition mode warnings
                    if self.timeRemaining == 120 || self.timeRemaining == 90 || self.timeRemaining == 30 {
                        self.impactGenerator.impactOccurred(intensity: 0.7)
                    } else if self.timeRemaining == 10 {
                        self.impactGenerator.impactOccurred(intensity: 0.9)
                    } else if self.timeRemaining <= 5 && self.timeRemaining > 0 {
                        self.impactGenerator.impactOccurred(intensity: 1.0)
                    }
                } else {
                    // Phase-based mode
                    if self.timeRemaining == 10 {
                        self.impactGenerator.impactOccurred(intensity: 0.7)
                    } else if self.timeRemaining == 5 {
                        self.impactGenerator.impactOccurred(intensity: 0.9)
                    } else if self.timeRemaining <= 3 && self.timeRemaining > 0 {
                        self.impactGenerator.impactOccurred(intensity: 1.0)
                    }
                }
                #endif
            } else {
                self.timer?.invalidate()
                self.isRunning = false
                self.triggerCompletionFeedback()
                // Don't show phase change alerts - just notify completion
                if currentMode == .competition {
                    // Show match end notification
                    self.warningMessage = "Match Complete!"
                    self.showingWarning = true
                }
                // Removed phase complete alert for phase-based mode
            }
        }
        
        #if canImport(UIKit)
        DesignSystem.Haptics.selection()
        #endif
        isRunning = true
    }
    
    private func checkCompetitionWarnings() {
        for warning in competitionWarnings {
            if timeRemaining == warning.time && lastWarningTime != warning.time {
                warningMessage = warning.message
                showingWarning = true
                lastWarningTime = warning.time
                
                // Auto-dismiss warning after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if showingWarning && lastWarningTime == warning.time {
                        withAnimation {
                            showingWarning = false
                        }
                    }
                }
                break
            }
        }
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        isRunning = false
        #if canImport(UIKit)
        DesignSystem.Haptics.selection()
        #endif
    }
    
    private func resetTimer() {
        timer?.invalidate()
        isRunning = false
        timeRemaining = phaseDuration
        showingWarning = false
        warningMessage = ""
        lastWarningTime = -1
        #if canImport(UIKit)
        DesignSystem.Haptics.selection()
        #endif
    }
    
    private func addTime() {
        timeRemaining = min(timeRemaining + 5, phaseDuration + 30)
        #if canImport(UIKit)
        DesignSystem.Haptics.impact(.light)
        #endif
    }
    
    private func subtractTime() {
        timeRemaining = max(timeRemaining - 5, 0)
        #if canImport(UIKit)
        DesignSystem.Haptics.impact(.light)
        #endif
    }
    
    private func advanceToNextPhase() {
        switch currentPhase {
        case MatchPhase.auto:
            currentPhase = MatchPhase.teleop
        case MatchPhase.teleop:
            currentPhase = MatchPhase.endgame
        case MatchPhase.endgame:
            currentPhase = MatchPhase.auto
        }
        resetTimer()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func triggerCompletionFeedback() {
        #if canImport(UIKit)
        // Strong notification feedback when timer completes
        feedbackGenerator.notificationOccurred(.success)
        // Also trigger impact for stronger vibration
        impactGenerator.impactOccurred(intensity: 1.0)
        #endif
    }
}

#Preview {
    DriveTeamTimerView()
}
