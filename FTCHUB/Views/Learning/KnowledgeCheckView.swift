//
//  KnowledgeCheckView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct KnowledgeCheckView: View {
    let check: KnowledgeCheck
    let moduleColor: Color
    @State private var userAnswer = ""
    @State private var showingAnswer = false
    @State private var isCorrect = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Knowledge Check")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            // Question
            Text(check.question)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding()
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
            
            // Answer input
            if !showingAnswer {
                TextField("Your answer...", text: $userAnswer, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
                
                Button(action: checkAnswer) {
                    Text("Check Answer")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(moduleColor)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .disabled(userAnswer.isEmpty)
            } else {
                // Result
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                        Text(isCorrect ? "Correct!" : "Not quite")
                            .font(.headline)
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Correct Answer:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(check.correctAnswer)
                            .font(.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    
                    if !check.explanation.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Explanation:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text(check.explanation)
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .padding()
                                .background(DesignSystem.Colors.secondaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
            }
        }
        .padding()
    }
    
    private func checkAnswer() {
        let normalizedUserAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedCorrectAnswer = check.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        isCorrect = normalizedUserAnswer == normalizedCorrectAnswer
        
        showingAnswer = true
        
        if isCorrect {
            DesignSystem.Haptics.notify(.success)
        } else {
            DesignSystem.Haptics.notify(.error)
        }
    }
}

