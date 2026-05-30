//
//  PracticeExerciseView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct PracticeExerciseView: View {
    let exercise: PracticeExercise
    let moduleColor: Color
    @Environment(\.dismiss) private var dismiss
    @State private var showingResult = false
    @State private var isComplete = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection
                    
                    // Exercise content based on type
                    exerciseContent
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle(exercise.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResult) {
                ExerciseResultView(
                    exercise: exercise,
                    isComplete: isComplete,
                    moduleColor: moduleColor
                )
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.description)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(4)
            
            HStack(spacing: 12) {
                // Difficulty badge
                HStack(spacing: 4) {
                    Image(systemName: exercise.difficulty.icon)
                    Text(exercise.difficulty.rawValue)
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(exercise.difficulty.color.opacity(0.15))
                .foregroundColor(exercise.difficulty.color)
                .cornerRadius(6)
                
                // Time badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                    Text("\(exercise.estimatedTime) min")
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DesignSystem.Colors.textSecondary.opacity(0.1))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .cornerRadius(6)
            }
        }
    }
    
    // MARK: - Exercise Content
    @ViewBuilder
    private var exerciseContent: some View {
        switch exercise.content {
        case .dragAndDrop(let dragDrop):
            DragAndDropExerciseView(exercise: dragDrop, moduleColor: moduleColor) {
                isComplete = true
                showingResult = true
            }
        case .codeCompletion(let code):
            CodeCompletionExerciseView(exercise: code, moduleColor: moduleColor) {
                isComplete = true
                showingResult = true
            }
        case .designDecision(let design):
            DesignDecisionExerciseView(exercise: design, moduleColor: moduleColor) {
                isComplete = true
                showingResult = true
            }
        case .troubleshooting(let troubleshooting):
            TroubleshootingExerciseView(exercise: troubleshooting, moduleColor: moduleColor) {
                isComplete = true
                showingResult = true
            }
        case .configuration(let config):
            ConfigurationExerciseView(exercise: config, moduleColor: moduleColor) {
                isComplete = true
                showingResult = true
            }
        case .matching(let matching):
            MatchingExerciseView(exercise: matching, moduleColor: moduleColor) {
                isComplete = true
                showingResult = true
            }
        }
    }
}

// MARK: - Drag and Drop Exercise View
struct DragAndDropExerciseView: View {
    let exercise: DragAndDropExercise
    let moduleColor: Color
    let onComplete: () -> Void
    @State private var itemPositions: [UUID: CGPoint] = [:]
    @State private var targetAssignments: [UUID: UUID] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(exercise.instructions)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Items to drag
            Text("Drag items to targets:")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(exercise.items) { item in
                    DraggableItemView(item: item, moduleColor: moduleColor)
                }
            }
            
            // Drop targets
            Text("Drop targets:")
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .padding(.top)
            
            ForEach(exercise.targets) { target in
                DropTargetView(
                    target: target,
                    assignedItem: exercise.items.first { item in
                        targetAssignments[item.id] == target.id
                    },
                    moduleColor: moduleColor
                )
            }
            
            // Check button
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
            .padding(.top)
        }
    }
    
    private func checkAnswer() {
        // Simplified check - in real implementation would verify drag and drop
        var allCorrect = true
        for (itemId, targetId) in exercise.correctMapping {
            if targetAssignments[itemId] != targetId {
                allCorrect = false
                break
            }
        }
        
        if allCorrect {
            DesignSystem.Haptics.notify(.success)
            onComplete()
        } else {
            DesignSystem.Haptics.notify(.error)
        }
    }
}

struct DraggableItemView: View {
    let item: DragAndDropExercise.DraggableItem
    let moduleColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.icon)
                .font(.title3)
            Text(item.label)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(moduleColor)
        .padding()
        .background(moduleColor.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(moduleColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DropTargetView: View {
    let target: DragAndDropExercise.DropTarget
    let assignedItem: DragAndDropExercise.DraggableItem?
    let moduleColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(target.label)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(target.description)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            if let item = assignedItem {
                HStack {
                    Image(systemName: item.icon)
                    Text(item.label)
                }
                .font(.caption)
                .foregroundColor(moduleColor)
                .padding(8)
                .background(moduleColor.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(
                    assignedItem != nil ? moduleColor : DesignSystem.Colors.border,
                    lineWidth: assignedItem != nil ? 2 : 1
                )
        )
    }
}

// MARK: - Code Completion Exercise View
struct CodeCompletionExerciseView: View {
    let exercise: CodeCompletionExercise
    let moduleColor: Color
    let onComplete: () -> Void
    @State private var selectedAnswers: [String: String] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(exercise.instructions)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Code template with blanks
            CodeBlockWithBlanks(
                template: exercise.codeTemplate,
                blanks: exercise.blanks,
                options: exercise.options,
                selectedAnswers: $selectedAnswers
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
        }
    }
    
    private func checkAnswer() {
        var allCorrect = true
        for (blankId, correctAnswer) in exercise.correctAnswers {
            if selectedAnswers[blankId] != correctAnswer {
                allCorrect = false
                break
            }
        }
        
        if allCorrect {
            DesignSystem.Haptics.notify(.success)
            onComplete()
        } else {
            DesignSystem.Haptics.notify(.error)
        }
    }
}

struct CodeBlockWithBlanks: View {
    let template: String
    let blanks: [CodeCompletionExercise.CodeBlank]
    let options: [String: [String]]
    @Binding var selectedAnswers: [String: String]
    
    private var lines: [String] {
        template.components(separatedBy: .newlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        CodeLineWithBlank(
                            lineNumber: index + 1,
                            line: line,
                            blanks: blanks.filter { $0.lineNumber == index + 1 },
                            options: options,
                            selectedAnswers: $selectedAnswers
                        )
                    }
                }
            }
        }
        .background(DesignSystem.Colors.secondaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct CodeLineWithBlank: View {
    let lineNumber: Int
    let line: String
    let blanks: [CodeCompletionExercise.CodeBlank]
    let options: [String: [String]]
    @Binding var selectedAnswers: [String: String]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(lineNumber)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 40, alignment: .trailing)
            
            if let blank = blanks.first {
                // Split line and show blank
                let parts = line.components(separatedBy: blank.placeholder)
                if parts.count == 2 {
                    Text(parts[0])
                        .font(.system(.body, design: .monospaced))
                    Menu {
                        ForEach(options[blank.id.uuidString] ?? [], id: \.self) { option in
                            Button(option) {
                                selectedAnswers[blank.id.uuidString] = option
                            }
                        }
                    } label: {
                        Text(selectedAnswers[blank.id.uuidString] ?? blank.placeholder)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(selectedAnswers[blank.id.uuidString] != nil ? .blue : .gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedAnswers[blank.id.uuidString] != nil ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    Text(parts[1])
                        .font(.system(.body, design: .monospaced))
                } else {
                    Text(line)
                        .font(.system(.body, design: .monospaced))
                }
            } else {
                Text(line)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

// MARK: - Design Decision Exercise View
struct DesignDecisionExerciseView: View {
    let exercise: DesignDecisionExercise
    let moduleColor: Color
    let onComplete: () -> Void
    @State private var selectedOption: UUID?
    @State private var showingExplanation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(exercise.scenario)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(4)
            
            Text(exercise.question)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            ForEach(exercise.options) { option in
                DesignOptionCard(
                    option: option,
                    isSelected: selectedOption == option.id,
                    moduleColor: moduleColor
                ) {
                    selectedOption = option.id
                    DesignSystem.Haptics.selection()
                }
            }
            
            if selectedOption != nil {
                Button(action: {
                    showingExplanation = true
                    if selectedOption == exercise.correctAnswer {
                        DesignSystem.Haptics.notify(.success)
                        onComplete()
                    } else {
                        DesignSystem.Haptics.notify(.error)
                    }
                }) {
                    Text("Check Answer")
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
        .sheet(isPresented: $showingExplanation) {
            DesignDecisionExplanationView(
                exercise: exercise,
                selectedOption: selectedOption,
                moduleColor: moduleColor
            )
        }
    }
}

struct DesignOptionCard: View {
    let option: DesignDecisionExercise.DesignOption
    let isSelected: Bool
    let moduleColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Text(option.title)
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(option.description)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                if !option.pros.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pros:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        ForEach(option.pros, id: \.self) { pro in
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption2)
                                Text(pro)
                                    .font(.caption)
                            }
                            .foregroundColor(.green)
                        }
                    }
                }
                
                if !option.cons.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cons:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        ForEach(option.cons, id: \.self) { con in
                            HStack(spacing: 4) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.caption2)
                                Text(con)
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(
                        isSelected ? moduleColor : DesignSystem.Colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct DesignDecisionExplanationView: View {
    let exercise: DesignDecisionExercise
    let selectedOption: UUID?
    let moduleColor: Color
    @Environment(\.dismiss) private var dismiss
    
    private var isCorrect: Bool {
        selectedOption == exercise.correctAnswer
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Result
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                        Text(isCorrect ? "Correct!" : "Not quite")
                            .font(.headline)
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    
                    // Explanation
                    Text(exercise.explanation)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineSpacing(4)
                }
                .padding()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Explanation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Troubleshooting Exercise View
struct TroubleshootingExerciseView: View {
    let exercise: TroubleshootingExercise
    let moduleColor: Color
    let onComplete: () -> Void
    @State private var currentStepId: UUID?
    @State private var path: [UUID] = []
    
    private var currentStep: TroubleshootingExercise.TroubleshootingStep? {
        guard let stepId = currentStepId else {
            return exercise.steps.first
        }
        return exercise.steps.first { $0.id == stepId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Problem description
            VStack(alignment: .leading, spacing: 8) {
                Text("Problem:")
                    .font(.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(exercise.problem)
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            .padding()
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            
            // Current step
            if let step = currentStep {
                TroubleshootingStepView(
                    step: step,
                    moduleColor: moduleColor
                ) { option in
                    handleStepSelection(step: step, option: option)
                }
            }
        }
    }
    
    private func handleStepSelection(step: TroubleshootingExercise.TroubleshootingStep, option: String) {
        path.append(step.id)
        
        if step.isSolution {
            // Check if path matches correct path
            if path == exercise.correctPath {
                DesignSystem.Haptics.notify(.success)
                onComplete()
            } else {
                DesignSystem.Haptics.notify(.error)
            }
        } else if let nextStepId = step.nextStepIds[option] {
            currentStepId = nextStepId
        }
    }
}

struct TroubleshootingStepView: View {
    let step: TroubleshootingExercise.TroubleshootingStep
    let moduleColor: Color
    let onSelect: (String) -> Void
    @State private var selectedOption: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(step.question)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if step.isSolution {
                if let solution = step.solution {
                    Text(solution)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
            } else {
                ForEach(step.options, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                        onSelect(option)
                    }) {
                        Text(option)
                            .font(.body)
                            .foregroundColor(selectedOption == option ? .white : DesignSystem.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(selectedOption == option ? moduleColor : DesignSystem.Colors.cardBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Configuration Exercise View
struct ConfigurationExerciseView: View {
    let exercise: ConfigurationExercise
    let moduleColor: Color
    let onComplete: () -> Void
    @State private var configuration: [String: String] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(exercise.instructions)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // Constraints
            if !exercise.constraints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Constraints:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    ForEach(exercise.constraints, id: \.self) { constraint in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(constraint)
                                .font(.caption)
                        }
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            
            // Components
            ForEach(exercise.components) { component in
                ConfigurableComponentView(
                    component: component,
                    selectedValue: Binding(
                        get: { configuration[component.id.uuidString] ?? "" },
                        set: { configuration[component.id.uuidString] = $0 }
                    ),
                    moduleColor: moduleColor
                )
            }
            
            Button(action: checkAnswer) {
                Text("Check Configuration")
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
    
    private func checkAnswer() {
        var allCorrect = true
        for (componentId, correctValue) in exercise.correctConfiguration {
            if configuration[componentId] != correctValue {
                allCorrect = false
                break
            }
        }
        
        if allCorrect {
            DesignSystem.Haptics.notify(.success)
            onComplete()
        } else {
            DesignSystem.Haptics.notify(.error)
        }
    }
}

struct ConfigurableComponentView: View {
    let component: ConfigurationExercise.ConfigurableComponent
    @Binding var selectedValue: String
    let moduleColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(component.name)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(component.description)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Picker(component.name, selection: $selectedValue) {
                Text("Select...").tag("")
                ForEach(component.options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Matching Exercise View
struct MatchingExerciseView: View {
    let exercise: MatchingExercise
    let moduleColor: Color
    let onComplete: () -> Void
    @State private var matches: [UUID: UUID] = [:] // leftId -> rightId
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(exercise.instructions)
                .font(.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: 20) {
                // Left items
                VStack(alignment: .leading, spacing: 12) {
                    Text("Items")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    ForEach(exercise.leftItems) { item in
                        MatchItemView(
                            item: item,
                            isMatched: matches[item.id] != nil,
                            moduleColor: moduleColor
                        )
                    }
                }
                
                // Right items
                VStack(alignment: .leading, spacing: 12) {
                    Text("Matches")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    ForEach(exercise.rightItems) { item in
                        MatchItemView(
                            item: item,
                            isMatched: matches.values.contains(item.id),
                            moduleColor: moduleColor
                        )
                    }
                }
            }
            
            Button(action: checkAnswer) {
                Text("Check Matches")
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
    
    private func checkAnswer() {
        var allCorrect = true
        for (leftId, rightId) in exercise.correctPairs {
            if matches[leftId] != rightId {
                allCorrect = false
                break
            }
        }
        
        if allCorrect {
            DesignSystem.Haptics.notify(.success)
            onComplete()
        } else {
            DesignSystem.Haptics.notify(.error)
        }
    }
}

struct MatchItemView: View {
    let item: MatchingExercise.MatchItem
    let isMatched: Bool
    let moduleColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if let description = item.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isMatched ? moduleColor.opacity(0.1) : DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(
                    isMatched ? moduleColor : DesignSystem.Colors.border,
                    lineWidth: isMatched ? 2 : 1
                )
        )
    }
}

// MARK: - Exercise Result View
struct ExerciseResultView: View {
    let exercise: PracticeExercise
    let isComplete: Bool
    let moduleColor: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Result icon
                Image(systemName: isComplete ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(isComplete ? .green : .red)
                
                Text(isComplete ? "Exercise Complete!" : "Keep Trying")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(isComplete ? "Great job! You've successfully completed this exercise." : "Don't give up! Review the material and try again.")
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
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
                .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignSystem.Colors.background)
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

