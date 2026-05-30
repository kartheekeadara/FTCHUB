//
//  CodeExampleView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct CodeExampleView: View {
    let example: CodeExample
    let moduleColor: Color
    @State private var selectedLine: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text(example.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            // Explanation
            Text(example.explanation)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineSpacing(4)
            
            // Code block
            CodeExampleBlock(
                code: example.code,
                language: example.language,
                lineExplanations: example.lineExplanations,
                selectedLine: $selectedLine
            )
            
            // Line-by-line explanations (if available)
            if let lineExplanations = example.lineExplanations, !lineExplanations.isEmpty, let selectedLine = selectedLine, let explanation = lineExplanations[selectedLine] {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Line \(selectedLine) Explanation")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(explanation)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding()
                        .background(moduleColor.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
        }
        .padding()
    }
}

// MARK: - Code Example Block
struct CodeExampleBlock: View {
    let code: String
    let language: String
    let lineExplanations: [Int: String]?
    @Binding var selectedLine: Int?
    
    private var codeLines: [String] {
        code.components(separatedBy: .newlines)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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
            .padding()
            .background(DesignSystem.Colors.secondaryBackground)
            
            // Code lines
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(codeLines.enumerated()), id: \.offset) { index, line in
                        CodeLineView(
                            lineNumber: index + 1,
                            code: line,
                            hasExplanation: lineExplanations?[index + 1] != nil,
                            isSelected: selectedLine == index + 1
                        ) {
                            if lineExplanations?[index + 1] != nil {
                                selectedLine = selectedLine == index + 1 ? nil : index + 1
                                DesignSystem.Haptics.selection()
                            }
                        }
                    }
                }
            }
            .background(DesignSystem.Colors.secondaryBackground)
        }
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Code Line View
struct CodeLineView: View {
    let lineNumber: Int
    let code: String
    let hasExplanation: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Line number
                Text("\(lineNumber)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 40, alignment: .trailing)
                
                // Code
                Text(code.isEmpty ? " " : code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                
                // Explanation indicator
                if hasExplanation {
                    Image(systemName: isSelected ? "info.circle.fill" : "info.circle")
                        .font(.caption)
                        .foregroundColor(isSelected ? .blue : DesignSystem.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .disabled(!hasExplanation)
    }
}

