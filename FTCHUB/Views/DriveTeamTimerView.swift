//
//  DriveTeamTimerView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct DriveTeamTimerView: View {
    @State private var timeRemaining = 150 // 2.5 minutes in seconds
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var currentPhase = MatchPhase.auto
    
    enum MatchPhase: String, CaseIterable {
        case auto = "Autonomous"
        case teleop = "Teleop"
        case endgame = "Endgame"
        
        var duration: Int {
            switch self {
            case .auto: return 30
            case .teleop: return 120
            case .endgame: return 30
            }
        }
        
        var color: Color {
            switch self {
            case .auto: return DesignSystem.Colors.primary
            case .teleop: return DesignSystem.Colors.accent
            case .endgame: return DesignSystem.Colors.secondary
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Phase Indicator
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Current Phase")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(currentPhase.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(currentPhase.color)
                }
                
                // Timer Display
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 80, weight: .bold, design: .monospaced))
                        .foregroundColor(timeRemaining <= 30 ? DesignSystem.Colors.error : DesignSystem.Colors.textPrimary)
                    
                    // Progress Bar
                    ProgressView(value: Double(timeRemaining), total: Double(currentPhase.duration))
                        .progressViewStyle(LinearProgressViewStyle(tint: currentPhase.color))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                
                // Controls
                VStack(spacing: DesignSystem.Spacing.lg) {
                    HStack(spacing: DesignSystem.Spacing.lg) {
                        Button(action: startTimer) {
                            HStack {
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                Text(isRunning ? "Pause" : "Start")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Gradients.primary)
                            .foregroundColor(.white)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                        .disabled(timeRemaining <= 0)
                        
                        Button(action: resetTimer) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Colors.secondaryBackground)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                            )
                        }
                    }
                    
                    // Phase Selector
                    Picker("Phase", selection: $currentPhase) {
                        ForEach(MatchPhase.allCases, id: \.self) { phase in
                            Text(phase.rawValue).tag(phase)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: currentPhase) { _ in
                        resetTimer()
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .navigationTitle("Drive Team Timer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func startTimer() {
        if isRunning {
            timer?.invalidate()
            isRunning = false
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer?.invalidate()
                    isRunning = false
                    // Auto-advance to next phase
                    advanceToNextPhase()
                }
            }
            isRunning = true
        }
    }
    
    private func resetTimer() {
        timer?.invalidate()
        isRunning = false
        timeRemaining = currentPhase.duration
    }
    
    private func advanceToNextPhase() {
        switch currentPhase {
        case .auto:
            currentPhase = .teleop
        case .teleop:
            currentPhase = .endgame
        case .endgame:
            currentPhase = .auto
        }
        resetTimer()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    DriveTeamTimerView()
}