//
//  QuizView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct QuizView: View {
    let quiz: Quiz
    let moduleColor: Color
    @Environment(\.dismiss) private var dismiss
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswers: Set<Int> = []
    @State private var showingResult = false
    @State private var userAnswers: [UUID: Set<Int>] = [:]
    @State private var isAnswered = false
    @State private var showingAchievement = false
    @State private var unlockedAchievements: [Achievement] = []
    
    private var currentQuestion: QuizQuestion {
        quiz.questions[currentQuestionIndex]
    }
    
    private var isLastQuestion: Bool {
        currentQuestionIndex == quiz.questions.count - 1
    }
    
    private var score: Int {
        var correct = 0
        for question in quiz.questions {
            if let userAnswer = userAnswers[question.id],
               userAnswer == question.correctAnswers {
                correct += 1
            }
        }
        return correct
    }
    
    private var isPerfectScore: Bool {
        score == quiz.questions.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showingResult {
                    QuizResultView(
                        quiz: quiz,
                        score: score,
                        totalQuestions: quiz.questions.count,
                        userAnswers: userAnswers,
                        moduleColor: moduleColor
                    )
                } else {
                    quizContent
                }
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle(quiz.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAchievement) {
                AchievementCelebrationView(achievements: unlockedAchievements)
            }
        }
    }
    
    // MARK: - Quiz Content
    private var quizContent: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Question number
                    Text("Question \(currentQuestionIndex + 1) of \(quiz.questions.count)")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.top)
                    
                    // Question
                    Text(currentQuestion.question)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    // Options
                    optionsView
                    
                    // Explanation (if answered)
                    if isAnswered {
                        explanationView
                    }
                }
                .padding()
            }
            
            // Navigation buttons
            navigationButtons
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(DesignSystem.Colors.secondaryBackground)
                    .frame(height: 4)
                
                Rectangle()
                    .fill(moduleColor)
                    .frame(width: geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(quiz.questions.count), height: 4)
            }
        }
        .frame(height: 4)
    }
    
    // MARK: - Options View
    private var optionsView: some View {
        VStack(spacing: 12) {
            ForEach(Array(currentQuestion.options.enumerated()), id: \.offset) { index, option in
                OptionButton(
                    option: option,
                    index: index,
                    isSelected: selectedAnswers.contains(index),
                    isCorrect: currentQuestion.correctAnswers.contains(index),
                    isAnswered: isAnswered,
                    allowsMultiple: currentQuestion.type == .multipleSelect,
                    action: {
                        handleOptionSelection(index)
                    }
                )
            }
        }
    }
    
    // MARK: - Explanation View
    private var explanationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isAnswerCorrect ? .green : .red)
                Text(isAnswerCorrect ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .foregroundColor(isAnswerCorrect ? .green : .red)
            }
            
            if !currentQuestion.explanation.isEmpty {
                Text(currentQuestion.explanation)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding()
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(isAnswerCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentQuestionIndex > 0 {
                Button(action: previousQuestion) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.headline)
                    .foregroundColor(moduleColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(moduleColor.opacity(0.1))
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
            
            Button(action: nextAction) {
                HStack {
                    Text(isLastQuestion ? "Finish" : "Next")
                    if !isLastQuestion {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isAnswered ? moduleColor : DesignSystem.Colors.textSecondary
                )
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            .disabled(!isAnswered)
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
    }
    
    // MARK: - Computed Properties
    private var isAnswerCorrect: Bool {
        selectedAnswers == currentQuestion.correctAnswers
    }
    
    // MARK: - Actions
    private func handleOptionSelection(_ index: Int) {
        guard !isAnswered else { return }
        
        DesignSystem.Haptics.selection()
        
        if currentQuestion.type == .multipleSelect {
            if selectedAnswers.contains(index) {
                selectedAnswers.remove(index)
            } else {
                selectedAnswers.insert(index)
            }
        } else {
            selectedAnswers = [index]
        }
        
        // Auto-submit for single choice
        if currentQuestion.type == .multipleChoice {
            submitAnswer()
        }
    }
    
    private func submitAnswer() {
        isAnswered = true
        userAnswers[currentQuestion.id] = selectedAnswers
        
        if isAnswerCorrect {
            DesignSystem.Haptics.notify(.success)
        } else {
            DesignSystem.Haptics.notify(.error)
        }
    }
    
    private func nextAction() {
        if !isAnswered && !selectedAnswers.isEmpty {
            submitAnswer()
        } else if isAnswered {
            if isLastQuestion {
                // Record quiz completion and check achievements
                achievementManager.recordQuizCompletion(
                    quizId: quiz.id,
                    score: score,
                    totalQuestions: quiz.questions.count
                )
                
                // Check for newly unlocked achievements
                let beforeUnlocked = achievementManager.unlockedAchievements
                achievementManager.checkAchievements()
                let afterUnlocked = achievementManager.unlockedAchievements
                
                // Find newly unlocked achievements
                let newlyUnlockedIds = afterUnlocked.subtracting(beforeUnlocked)
                if !newlyUnlockedIds.isEmpty {
                    let allAchievements = AchievementData.allAchievements
                    unlockedAchievements = allAchievements.filter { newlyUnlockedIds.contains($0.id) }
                    if !unlockedAchievements.isEmpty {
                        showingAchievement = true
                    }
                }
                
                showingResult = true
            } else {
                nextQuestion()
            }
        }
    }
    
    private func nextQuestion() {
        currentQuestionIndex += 1
        selectedAnswers = []
        isAnswered = false
    }
    
    private func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            selectedAnswers = userAnswers[currentQuestion.id] ?? []
            isAnswered = userAnswers[currentQuestion.id] != nil
        }
    }
}

// MARK: - Option Button
struct OptionButton: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let isAnswered: Bool
    let allowsMultiple: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(
                            isAnswered ? (isCorrect ? Color.green : (isSelected ? Color.red : Color.gray)) : (isSelected ? Color.blue : Color.gray),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(
                                isAnswered ? (isCorrect ? Color.green : Color.red) : Color.blue
                            )
                            .frame(width: 16, height: 16)
                    }
                    
                    if isAnswered && isCorrect && !isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // Option text
                Text(option)
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(
                        isSelected ? (isAnswered ? (isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1)) : Color.blue.opacity(0.1)) : DesignSystem.Colors.cardBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        isSelected ? (isAnswered ? (isCorrect ? Color.green : Color.red) : Color.blue) : DesignSystem.Colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isAnswered && !allowsMultiple)
    }
}

// MARK: - Quiz Result View
struct QuizResultView: View {
    let quiz: Quiz
    let score: Int
    let totalQuestions: Int
    let userAnswers: [UUID: Set<Int>]
    let moduleColor: Color
    @Environment(\.dismiss) private var dismiss
    
    private var percentage: Int {
        Int((Double(score) / Double(totalQuestions)) * 100)
    }
    
    private var resultEmoji: String {
        switch percentage {
        case 90...100: return "🎉"
        case 70..<90: return "👍"
        case 50..<70: return "📚"
        default: return "💪"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score display
                VStack(spacing: 16) {
                    Text(resultEmoji)
                        .font(.system(size: 64))
                    
                    Text("\(score) / \(totalQuestions)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(moduleColor)
                    
                    Text("\(percentage)%")
                        .font(.title2)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(resultMessage)
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                
                // Review answers
                VStack(alignment: .leading, spacing: 16) {
                    Text("Review Answers")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ForEach(Array(quiz.questions.enumerated()), id: \.element.id) { index, question in
                        AnswerReviewCard(
                            question: question,
                            questionNumber: index + 1,
                            userAnswer: userAnswers[question.id] ?? [],
                            moduleColor: moduleColor
                        )
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(moduleColor)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                }
            }
            .padding()
        }
        .background(DesignSystem.Colors.background)
    }
    
    private var resultMessage: String {
        switch percentage {
        case 90...100: return "Excellent work! You've mastered this topic!"
        case 70..<90: return "Great job! You have a solid understanding."
        case 50..<70: return "Good effort! Review the material and try again."
        default: return "Keep learning! Review the content and try again."
        }
    }
}

// MARK: - Answer Review Card
struct AnswerReviewCard: View {
    let question: QuizQuestion
    let questionNumber: Int
    let userAnswer: Set<Int>
    let moduleColor: Color
    
    private var isCorrect: Bool {
        userAnswer == question.correctAnswers
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Q\(questionNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isCorrect ? Color.green : Color.red)
                    .cornerRadius(6)
                
                Text(question.question)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            if !isCorrect {
                VStack(alignment: .leading, spacing: 8) {
                    if !userAnswer.isEmpty {
                        HStack {
                            Text("Your answer:")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            ForEach(Array(userAnswer.sorted()), id: \.self) { index in
                                Text(question.options[index])
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        Text("Correct answer:")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        ForEach(Array(question.correctAnswers.sorted()), id: \.self) { index in
                            Text(question.options[index])
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            if !question.explanation.isEmpty {
                Text(question.explanation)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(8)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

