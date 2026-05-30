//
//  ScoringCalculatorView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ScoringCalculatorView: View {
    @StateObject private var viewModel = DecodeScoringViewModel()
    @State private var selectedPhase: MatchPhase = MatchPhase.auto
    @State private var showHelp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Sticky Header
                largeScoreCard
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.sm)
                    .padding(.bottom, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.background)
                    .zIndex(1)
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Quick Stats Row
                        quickStatsRow
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Phase Selector
                        phaseSelector
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Scoring Categories Grid
                        scoringCategoriesGrid
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Pattern & Randomization Section
                        patternSection
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Ranking Points
                        rankingPointsCard
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Fouls Section
                        foulsCard
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                    .padding(.top, DesignSystem.Spacing.sm)
                    .padding(.bottom, DesignSystem.Spacing.lg)
                }
                .tabBarScrollInset()
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation {
                            viewModel.reset()
                        }
                        #if canImport(UIKit)
                        DesignSystem.Haptics.impact(.medium)
                        #endif
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showHelp) {
                ScoringHelpView()
            }
        }
    }
    
    // MARK: - Large Score Card
    
    private var largeScoreCard: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Total Score")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text("\(viewModel.preFoulTotal)")
                .font(.system(size: 88, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.preFoulTotal)
            
            if viewModel.foulPointsCommitted > 0 {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("-\(viewModel.foulPointsCommitted) from fouls")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.3))
                .cornerRadius(DesignSystem.CornerRadius.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xl)
        .background(
            LinearGradient(
                colors: [
                    DesignSystem.Colors.accent,
                    DesignSystem.Colors.primary.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.accent.opacity(0.3), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Quick Stats Row
    
    private var quickStatsRow: some View {
        HStack(spacing: 0) {
            StatBadge(label: "Auto", value: "\(viewModel.autoPoints)", color: DesignSystem.Colors.primary)
            Divider()
                .frame(width: 1)
                .background(DesignSystem.Colors.separator)
                .padding(.vertical, 12)
            StatBadge(label: "Teleop", value: "\(viewModel.teleopPoints)", color: DesignSystem.Colors.accent)
            Divider()
                .frame(width: 1)
                .background(DesignSystem.Colors.separator)
                .padding(.vertical, 12)
            StatBadge(
                label: "Patterns",
                value: "\(viewModel.autoPatternMatches + viewModel.teleopPatternMatches)",
                color: DesignSystem.Colors.secondary
            )
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Phase Selector
    
    private var phaseSelector: some View {
        SegmentedPillToggle(
            segments: [
                SegmentedPillSegment(
                    id: MatchPhase.auto.rawValue,
                    title: "Auto",
                    subtitle: "\(viewModel.autoPoints) pts",
                    selectedColor: DesignSystem.Colors.primary
                ),
                SegmentedPillSegment(
                    id: MatchPhase.teleop.rawValue,
                    title: "Teleop",
                    subtitle: "\(viewModel.teleopPoints) pts",
                    selectedColor: DesignSystem.Colors.accent
                )
            ],
            selectedID: Binding(
                get: { selectedPhase.rawValue },
                set: { newValue in
                    if let phase = MatchPhase(rawValue: newValue) {
                        selectedPhase = phase
                    }
                }
            )
        )
    }
    
    // MARK: - Scoring Categories Grid
    
    private var scoringCategoriesGrid: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // List-style layout (consistent for both auto and teleop)
            VStack(spacing: DesignSystem.Spacing.sm) {
                if selectedPhase == MatchPhase.auto {
                    ScoringCategoryCard(
                        title: "Classified",
                        value: $viewModel.autoClassifiedArtifacts,
                        pointsPerItem: 3,
                        color: DesignSystem.Colors.primary
                    )
                    
                    ScoringCategoryCard(
                        title: "Overflown",
                        value: $viewModel.autoOverflowArtifacts,
                        pointsPerItem: 1,
                        color: DesignSystem.Colors.accent
                    )
                    
                    // Robot Leaves - Full width
                    RobotLeavesCard(
                        robot1Leaves: $viewModel.robot1AutoLeaves,
                        robot2Leaves: $viewModel.robot2AutoLeaves,
                        totalPoints: viewModel.autoLeavePoints
                    )
                } else {
                    ScoringCategoryCard(
                        title: "Classified",
                        value: $viewModel.teleopClassifiedArtifacts,
                        pointsPerItem: 3,
                        color: DesignSystem.Colors.primary
                    )
                    
                    ScoringCategoryCard(
                        title: "Overflown",
                        value: $viewModel.teleopOverflowArtifacts,
                        pointsPerItem: 1,
                        color: DesignSystem.Colors.accent
                    )
                    
                    ScoringCategoryCard(
                        title: "Depot",
                        value: $viewModel.teleopDepotArtifacts,
                        pointsPerItem: 1,
                        color: DesignSystem.Colors.secondary
                    )
                    
                    // Base Positions - Full width
                    BasePositionsCard(
                        robot1Base: $viewModel.robot1TeleopBase,
                        robot2Base: $viewModel.robot2TeleopBase,
                        totalPoints: viewModel.teleopBasePoints
                    )
                }
            }
        }
    }
    
    // MARK: - Pattern Section
    
    private var patternSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Randomization Header
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Randomization Pattern")
                        .font(.headline)
                        .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Select or roll for pattern")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                    
                    Spacer()
                
                Button {
                    withAnimation {
                        viewModel.rollRandomization()
                    }
                    #if canImport(UIKit)
                    DesignSystem.Haptics.impact(.light)
                    #endif
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 14))
                        Text("Roll")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(DesignSystem.Colors.textOnPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(DesignSystem.Colors.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            
            // Pattern Picker
            Picker("Randomization", selection: $viewModel.randomization) {
                ForEach(DecodeScoringViewModel.RandomizationMotif.allCases) { motif in
                    Text(motif.displayName).tag(motif)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            
            // Pattern Visualization
            if let pattern = viewModel.randomization.pattern {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Pattern:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        ForEach(Array(pattern.enumerated()), id: \.offset) { index, color in
                            VStack(spacing: 2) {
                                Text(color.symbol)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        LinearGradient(
                                            colors: [color.tint, color.tint.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(8)
                                    .shadow(color: color.tint.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                Text("G\(index + 1)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            
            // Gate Assignments
            GateGridSection(
                title: "Gate Assignments",
                gates: selectedPhase == MatchPhase.auto ? $viewModel.autoClassifierState : $viewModel.teleopClassifierState,
                pattern: viewModel.randomization.pattern,
                matches: selectedPhase == MatchPhase.auto ? viewModel.autoPatternMatches : viewModel.teleopPatternMatches,
                phaseColor: selectedPhase == MatchPhase.auto ? DesignSystem.Colors.primary : DesignSystem.Colors.accent
            )
        }
    }
    
    // MARK: - Additional Controls Section
    
    private var additionalControlsSection: some View {
        Group {
            if selectedPhase == MatchPhase.auto {
                RobotLeavesCard(
                    robot1Leaves: $viewModel.robot1AutoLeaves,
                    robot2Leaves: $viewModel.robot2AutoLeaves,
                    totalPoints: viewModel.autoLeavePoints
                )
            } else {
                BasePositionsCard(
                    robot1Base: $viewModel.robot1TeleopBase,
                    robot2Base: $viewModel.robot2TeleopBase,
                    totalPoints: viewModel.teleopBasePoints
                )
            }
        }
    }
    
    // MARK: - Ranking Points Card
    
    private var rankingPointsCard: some View {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Ranking Points")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                let movementAchieved = viewModel.movementProgress.achieved
                let goalAchieved = viewModel.goalProgress.achieved
                let patternAchieved = viewModel.patternProgress.achieved
                let achievedCount = (movementAchieved ? 1 : 0) + (goalAchieved ? 1 : 0) + (patternAchieved ? 1 : 0)
                
                if achievedCount > 0 {
                    Text("\(achievedCount)/3")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(DesignSystem.Colors.accent.opacity(0.15))
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                RankingPointRow(
                    title: "Movement",
                    icon: "figure.run",
                    value: viewModel.movementProgress.value,
                    goal: viewModel.movementProgress.goal,
                    achieved: viewModel.movementProgress.achieved,
                    color: DesignSystem.Colors.primary
                )
                
                RankingPointRow(
                    title: "Goal",
                    icon: "target",
                    value: viewModel.goalProgress.value,
                    goal: viewModel.goalProgress.goal,
                    achieved: viewModel.goalProgress.achieved,
                    color: DesignSystem.Colors.accent
                )
                
                RankingPointRow(
                    title: "Pattern",
                    icon: "square.grid.3x3",
                    value: viewModel.patternProgress.value,
                    goal: viewModel.patternProgress.goal,
                    achieved: viewModel.patternProgress.achieved,
                    color: DesignSystem.Colors.secondary
                )
            }
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Fouls Card
    
    private var foulsCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Fouls")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if viewModel.foulPointsCommitted > 0 {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DesignSystem.Colors.error)
                        Text("-\(viewModel.foulPointsCommitted) pts")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.error)
                    }
                }
            }
            
            HStack(spacing: DesignSystem.Spacing.md) {
                FoulCounter(
                    title: "Minor",
                    subtitle: "-5 pts each",
                    value: $viewModel.minorFouls,
                    color: DesignSystem.Colors.warning
                )
                
                FoulCounter(
                    title: "Major",
                    subtitle: "-15 pts each",
                    value: $viewModel.majorFouls,
                    color: DesignSystem.Colors.error
                )
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(viewModel.foulPointsCommitted > 0 ? DesignSystem.Colors.error.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.sm)
    }
}

// MARK: - Scoring Category Card

private struct ScoringCategoryCard: View {
    let title: String
    @Binding var value: Int
    let pointsPerItem: Int
    let color: Color
    
    private var totalPoints: Int {
        value * pointsPerItem
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: DesignSystem.Spacing.md) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Text("\(pointsPerItem) pts each")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            Divider()
                .padding(.leading, DesignSystem.Spacing.md)
            
            // Value and Controls Row
            HStack(spacing: DesignSystem.Spacing.md) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
                
                if totalPoints > 0 {
                    Text("+\(totalPoints) pts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Button {
                        value = max(0, value - 1)
                        #if canImport(UIKit)
                        DesignSystem.Haptics.impact(.light)
                        #endif
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(value > 0 ? color : DesignSystem.Colors.textTertiary)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(value > 0 ? color : DesignSystem.Colors.textTertiary.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .disabled(value <= 0)
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        value += 1
                        #if canImport(UIKit)
                        DesignSystem.Haptics.impact(.light)
                        #endif
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(color)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(color, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Robot Leaves Card

private struct RobotLeavesCard: View {
    @Binding var robot1Leaves: Bool
    @Binding var robot2Leaves: Bool
    let totalPoints: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Robot Leaves Starting Zone")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if totalPoints > 0 {
                    Text("+\(totalPoints) pts")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            
            HStack(spacing: DesignSystem.Spacing.lg) {
                ToggleRow(
                    label: "Robot 1",
                    isOn: $robot1Leaves,
                    color: DesignSystem.Colors.primary
                )
                
                ToggleRow(
                    label: "Robot 2",
                    isOn: $robot2Leaves,
                    color: DesignSystem.Colors.primary
                )
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Base Positions Card

private struct BasePositionsCard: View {
    @Binding var robot1Base: DecodeScoringViewModel.TeleopBasePosition
    @Binding var robot2Base: DecodeScoringViewModel.TeleopBasePosition
    let totalPoints: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Base Positions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if totalPoints > 0 {
                    Text("+\(totalPoints) pts")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.accent)
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                PickerRow(
                    title: "Robot 1 Base",
                    selection: $robot1Base,
                    options: DecodeScoringViewModel.TeleopBasePosition.allCases,
                    color: DesignSystem.Colors.accent
                )
                
                PickerRow(
                    title: "Robot 2 Base",
                    selection: $robot2Base,
                    options: DecodeScoringViewModel.TeleopBasePosition.allCases,
                    color: DesignSystem.Colors.accent
                )
            }
            
            if robot1Base == .full && robot2Base == .full {
                Text("Both robots in full base! +10 bonus")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.accent)
                    .padding(.top, DesignSystem.Spacing.xs)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Toggle Row

private struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(color)
                .labelsHidden()
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Gate Grid Section

private struct GateGridSection: View {
    let title: String
    @Binding var gates: [DecodeScoringViewModel.ArtifactColor]
    let pattern: [DecodeScoringViewModel.ArtifactColor]?
    let matches: Int
    let phaseColor: Color
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    private func isMatching(_ index: Int) -> Bool {
        guard let pattern = pattern, !pattern.isEmpty else { return false }
        let expected = pattern[index % pattern.count]
        return gates[index] == expected && gates[index] != .none
    }
    
    private func backgroundForGate(index: Int) -> Color {
        if isMatching(index) {
            return DesignSystem.Colors.success.opacity(0.15)
        }
        if gates[index] != .none {
            return gates[index].tint.opacity(0.1)
        }
        return DesignSystem.Colors.tertiaryBackground
    }
    
    private func strokeColorForGate(index: Int) -> Color {
        if isMatching(index) {
            return DesignSystem.Colors.success.opacity(0.5)
        }
        if gates[index] != .none {
            return gates[index].tint.opacity(0.3)
        }
        return DesignSystem.Colors.border.opacity(0.3)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
                Spacer()
                
                if matches > 0 {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.success)
                            .font(.caption)
                        Text("\(matches) matches")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.success)
                    }
                }
            }
            
            LazyVGrid(columns: columns, spacing: DesignSystem.Spacing.sm) {
                ForEach(gates.indices, id: \.self) { index in
                    VStack(spacing: 4) {
                        // Gate label above picker per spec
                        Text("G\(index + 1)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textTertiary)

                        Picker("", selection: Binding(
                            get: { gates[index] },
                            set: { newValue in
                                gates[index] = newValue
                                #if canImport(UIKit)
                                DesignSystem.Haptics.impact(.light)
                                #endif
                            }
                        )) {
                            ForEach(DecodeScoringViewModel.ArtifactColor.allCases) { color in
                                Text(color.displayName).tag(color)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(phaseColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(backgroundForGate(index: index))
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                .stroke(strokeColorForGate(index: index), lineWidth: isMatching(index) ? 2 : 1)
                        )
                        .overlay(
                            Group {
                                if isMatching(index) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(DesignSystem.Colors.success)
                                        .font(.caption)
                                        .offset(x: 6, y: -6)
                                }
                            },
                            alignment: .topTrailing
                        )
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Ranking Point Row

private struct RankingPointRow: View {
    let title: String
    let icon: String
    let value: Int
    let goal: Int
    let achieved: Bool
    let color: Color
    
    private var progress: Double {
        min(Double(value) / Double(goal), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                ZStack {
                    Circle()
                        .fill(achieved ? color.opacity(0.2) : DesignSystem.Colors.tertiaryBackground)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(achieved ? color : DesignSystem.Colors.textSecondary)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text("\(value)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(achieved ? color : DesignSystem.Colors.textPrimary)
                    
                    Text("/ \(goal)")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if achieved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(color)
                            .font(.caption)
                    }
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geometry.size.width * progress, progress > 0 ? 4 : 0), height: 4)
                        .shadow(color: color.opacity(0.4), radius: 2, x: 0, y: 0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Foul Counter

private struct FoulCounter: View {
    let title: String
    let subtitle: String
    @Binding var value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Text("\(value)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .monospacedDigit()
            
            HStack(spacing: DesignSystem.Spacing.md) {
                Button {
                    value = max(0, value - 1)
                    #if canImport(UIKit)
                    DesignSystem.Haptics.impact(.light)
                    #endif
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(value > 0 ? color : DesignSystem.Colors.textTertiary)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(value > 0 ? color : DesignSystem.Colors.textTertiary.opacity(0.5), lineWidth: 1)
                        )
                }
                .disabled(value <= 0)
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    value += 1
                    #if canImport(UIKit)
                    DesignSystem.Haptics.impact(.light)
                    #endif
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(color, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(color.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - Picker Row

private struct PickerRow<Option: Identifiable & Hashable & CustomStringConvertible>: View {
    let title: String
    @Binding var selection: Option
    let options: [Option]
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(options) { option in
                    Text(option.description).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .tint(color)
            .frame(maxWidth: 180)
        }
    }
}

// MARK: - Scoring Help View

struct ScoringHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    private let sections: [(icon: String, title: String, items: [String])] = [
        (
            "cpu",
            "Autonomous",
            [
                "Robot Leaves: +3 pts per robot",
                "Classified Artifacts: +3 pts each",
                "Overflow Artifacts: +1 pt each",
                "Pattern Matches: +2 pts per match"
            ]
        ),
        (
            "gamecontroller.fill",
            "Teleop",
            [
                "Classified Artifacts: +3 pts each",
                "Overflow Artifacts: +1 pt each",
                "Depot Artifacts: +1 pt each",
                "Pattern Matches: +2 pts per match",
                "Partial Base: +5 pts",
                "Full Base: +10 pts",
                "Both Full: +10 bonus"
            ]
        ),
        (
            "chart.bar.fill",
            "Ranking Points",
            [
                "Movement: Need 16+ pts",
                "Goal: Need 36+ artifacts",
                "Pattern: Need 18+ pattern points"
            ]
        ),
        (
            "flag.fill",
            "Fouls",
            [
                "Minor Foul: -5 pts each",
                "Major Foul: -15 pts each"
            ]
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Decode scoring")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("Point values and ranking thresholds used by this calculator. Update values on the main screen to see totals instantly.")
                            .font(.subheadline)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.separator, lineWidth: 1)
                    )

                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        ScoringHelpSectionCard(
                            systemImage: section.icon,
                            title: section.title,
                            items: section.items
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Scoring Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(DesignSystem.Colors.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }
}

private struct ScoringHelpSectionCard: View {
    let systemImage: String
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Colors.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Spacer(minLength: 0)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(DesignSystem.Colors.primary.opacity(0.5))
                            .frame(width: 12)
                        Text(item)
                            .font(.subheadline)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.separator, lineWidth: 1)
        )
    }
}

extension DecodeScoringViewModel.TeleopBasePosition: CustomStringConvertible {
    var description: String { displayName }
}

#Preview {
    NavigationView {
        ScoringCalculatorView()
    }
}
