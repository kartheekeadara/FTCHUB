//
//  InteractiveTutorialView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct InteractiveTutorialView: View {
    let tutorial: TutorialContent
    let moduleColor: Color
    @State private var currentStepIndex = 0
    
    private var currentStep: TutorialStep {
        tutorial.steps[currentStepIndex]
    }
    
    private var isFirstStep: Bool {
        currentStepIndex == 0
    }
    
    private var isLastStep: Bool {
        currentStepIndex == tutorial.steps.count - 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            stepIndicator
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Step title
                    Text(currentStep.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    // Step content
                    Text(currentStep.content)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineSpacing(4)
                    
                    // Code example (if available)
                    if let codeExample = currentStep.codeExample {
                        CodeBlock(code: codeExample, language: "java")
                    }
                    
                    // Image (if available)
                    if let imageName = currentStep.imageName {
                        Group {
                            #if canImport(UIKit)
                            if let image = UIImage(named: imageName) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(DesignSystem.Colors.secondaryBackground)
                            }
                            #else
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(DesignSystem.Colors.secondaryBackground)
                            #endif
                        }
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                }
                .padding()
            }
            
            // Navigation buttons
            navigationButtons
        }
    }
    
    // MARK: - Step Indicator
    private var stepIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(0..<tutorial.steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStepIndex ? moduleColor : DesignSystem.Colors.textSecondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    if index < tutorial.steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStepIndex ? moduleColor : DesignSystem.Colors.textSecondary.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            
            Text("Step \(currentStepIndex + 1) of \(tutorial.steps.count)")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.vertical, 12)
        .background(DesignSystem.Colors.secondaryBackground)
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if !isFirstStep {
                Button(action: previousStep) {
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
            
            Button(action: nextStep) {
                HStack {
                    Text(isLastStep ? "Complete" : "Next")
                    if !isLastStep {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(moduleColor)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
    }
    
    // MARK: - Actions
    private func nextStep() {
        if !isLastStep {
            withAnimation {
                currentStepIndex += 1
            }
            DesignSystem.Haptics.selection()
        }
    }
    
    private func previousStep() {
        if !isFirstStep {
            withAnimation {
                currentStepIndex -= 1
            }
            DesignSystem.Haptics.selection()
        }
    }
}

// MARK: - Code Block
struct CodeBlock: View {
    let code: String
    let language: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(language.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.Colors.secondaryBackground)
                    .cornerRadius(4)
                
                Spacer()
                
                Button(action: {
                    #if canImport(UIKit)
                    UIPasteboard.general.string = code
                    #endif
                    DesignSystem.Haptics.notify(.success)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding()
            }
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
        }
    }
}

