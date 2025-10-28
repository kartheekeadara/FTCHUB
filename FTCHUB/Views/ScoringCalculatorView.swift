//
//  ScoringCalculatorView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct ScoringCalculatorView: View {
    @State private var autoScore = 0
    @State private var teleopScore = 0
    @State private var endgameScore = 0
    @State private var penalties = 0
    
    var totalScore: Int {
        autoScore + teleopScore + endgameScore - penalties
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "calculator.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("Scoring Calculator")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Calculate match scores and points")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.top, DesignSystem.Spacing.xl)
                    
                    // Score Display
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("Total Score")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("\(totalScore)")
                            .font(.system(size: 80, weight: .bold, design: .monospaced))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    .padding()
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                    .shadow(color: DesignSystem.Colors.shadow, radius: 6, x: 0, y: 2)
                    
                    // Score Inputs
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        ScoreInputCard(
                            title: "Autonomous",
                            score: $autoScore,
                            color: DesignSystem.Colors.primary,
                            icon: "timer"
                        )
                        
                        ScoreInputCard(
                            title: "Teleop",
                            score: $teleopScore,
                            color: DesignSystem.Colors.accent,
                            icon: "gamecontroller"
                        )
                        
                        ScoreInputCard(
                            title: "Endgame",
                            score: $endgameScore,
                            color: DesignSystem.Colors.secondary,
                            icon: "flag"
                        )
                        
                        ScoreInputCard(
                            title: "Penalties",
                            score: $penalties,
                            color: DesignSystem.Colors.error,
                            icon: "exclamationmark.triangle"
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Action Buttons
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Button(action: resetScores) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset All")
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
                        
                        Button(action: saveScore) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save Score")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignSystem.Gradients.primary)
                            .foregroundColor(.white)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Scoring Calculator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func resetScores() {
        autoScore = 0
        teleopScore = 0
        endgameScore = 0
        penalties = 0
    }
    
    private func saveScore() {
        // TODO: Implement score saving
    }
}

struct ScoreInputCard: View {
    let title: String
    @Binding var score: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            HStack(spacing: DesignSystem.Spacing.lg) {
                Button(action: { score = max(0, score - 1) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text("\(score)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .frame(minWidth: 60)
                
                Button(action: { score += 1 }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(color)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow, radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ScoringCalculatorView()
}