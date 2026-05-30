//
//  TutorialContentComponents.swift
//  FTCHUB
//
//  Created for Phase 2: Content Enhancement
//  Reusable components for tutorial-style content display
//

import SwiftUI

// MARK: - Step-by-Step Guide Component
struct StepByStepGuide: View {
    let steps: [TutorialContentStep]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                StepCard(step: step, stepNumber: index + 1, accentColor: accentColor)
            }
        }
    }
}

struct TutorialContentStep {
    let title: String
    let description: String
    let details: [String]?
    let tips: [String]?
    let warnings: [String]?
    let codeExample: String?
}

struct StepCard: View {
    let step: TutorialContentStep
    let stepNumber: Int
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step Header
            HStack(alignment: .top, spacing: 12) {
                // Step Number Badge
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Text("\(stepNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(step.description)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Step Details
            if let details = step.details, !details.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(details, id: \.self) { detail in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(accentColor)
                                .padding(.top, 2)
                            
                            Text(detail)
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.leading, 48)
            }
            
            // Tips
            if let tips = step.tips, !tips.isEmpty {
                TipSection(tips: tips, accentColor: accentColor)
                    .padding(.leading, 48)
            }
            
            // Warnings
            if let warnings = step.warnings, !warnings.isEmpty {
                WarningSection(warnings: warnings)
                    .padding(.leading, 48)
            }
            
            // Code Example
            if let code = step.codeExample, !code.isEmpty {
                TutorialCodeBlock(code: code, accentColor: accentColor)
                    .padding(.leading, 48)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: accentColor.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Quick Tips Component
struct QuickTipsCard: View {
    let tips: [String]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(accentColor)
                Text("Quick Tips")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(accentColor)
                            .padding(.top, 2)
                        
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.08),
                            accentColor.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Tip Section
struct TipSection: View {
    let tips: [String]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(accentColor)
                Text("Tips:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
            }
            
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .foregroundColor(accentColor)
                    Text(tip)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(accentColor.opacity(0.05))
        )
    }
}

// MARK: - Warning Section
struct WarningSection: View {
    let warnings: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("Warnings:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            ForEach(warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 6) {
                    Text("⚠")
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

// MARK: - Code Block Component
struct TutorialCodeBlock: View {
    let code: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "curlybraces")
                    .font(.caption)
                    .foregroundColor(accentColor)
                Text("Code Example")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Comparison Table Component
struct ComparisonTable: View {
    let title: String
    let items: [TutorialComparisonItem]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: 0) {
                ForEach(items) { item in
                    ComparisonRow(item: item, accentColor: accentColor)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct TutorialComparisonItem: Identifiable {
    let id = UUID()
    let name: String
    let pros: [String]
    let cons: [String]
    let bestFor: String
}

struct ComparisonRow: View {
    let item: TutorialComparisonItem
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Name
            Text(item.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(accentColor)
                .padding(.horizontal, 12)
                .padding(.top, 12)
            
            // Pros
            if !item.pros.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pros:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                    
                    ForEach(item.pros, id: \.self) { pro in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(pro)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
            
            // Cons
            if !item.cons.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cons:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                    
                    ForEach(item.cons, id: \.self) { con in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(con)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
            
            // Best For
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.caption)
                    .foregroundColor(accentColor)
                Text("Best for: \(item.bestFor)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(
            Rectangle()
                .fill(Color(.systemGray6).opacity(0.3))
        )
    }
}

// MARK: - Key Concept Card
struct KeyConceptCard: View {
    let title: String
    let description: String
    let examples: [String]?
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let examples = examples, !examples.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Examples:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(accentColor)
                    
                    ForEach(examples, id: \.self) { example in
                        HStack(alignment: .top, spacing: 6) {
                            Text("→")
                                .foregroundColor(accentColor)
                            Text(example)
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Checklist Component
struct ChecklistView: View {
    let title: String
    let items: [TutorialChecklistItem]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items) { item in
                    TutorialChecklistRow(item: item, accentColor: accentColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct TutorialChecklistItem: Identifiable {
    let id = UUID()
    let text: String
    let isImportant: Bool
}

struct TutorialChecklistRow: View {
    let item: TutorialChecklistItem
    let accentColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "square")
                .font(.body)
                .foregroundColor(accentColor)
            
            Text(item.text)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .fontWeight(item.isImportant ? .semibold : .regular)
                .fixedSize(horizontal: false, vertical: true)
            
            if item.isImportant {
                Spacer()
                Text("Important")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.2))
                    .foregroundColor(accentColor)
                    .cornerRadius(4)
            }
        }
    }
}


