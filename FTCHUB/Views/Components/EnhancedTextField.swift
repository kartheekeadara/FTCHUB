//
//  EnhancedTextField.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct EnhancedTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false
    var isMultiline: Bool = false
    var helperText: String? = nil
    var errorText: String? = nil
    var isRequired: Bool = false
    
    @FocusState private var isFocused: Bool
    @State private var isFloating: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.tertiaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(
                                isFocused ? DesignSystem.Colors.primary : 
                                errorText != nil ? DesignSystem.Colors.error : DesignSystem.Colors.border,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
                
                // Floating label
                Text(title + (isRequired ? " *" : ""))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(
                        isFocused ? DesignSystem.Colors.primary :
                        errorText != nil ? DesignSystem.Colors.error : DesignSystem.Colors.textSecondary
                    )
                    .background(DesignSystem.Colors.tertiaryBackground)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
                    .offset(y: isFloating ? -8 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isFloating)
                
                // Input field
                Group {
                    if isMultiline {
                        TextEditor(text: $text)
                            .font(DesignSystem.Typography.body)
                    } else if isSecure {
                        SecureField(placeholder, text: $text)
                            .font(DesignSystem.Typography.body)
                    } else {
                        TextField(placeholder, text: $text)
                            .font(DesignSystem.Typography.body)
                    }
                }
                .focused($isFocused)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.md)
                .padding(.top, isFloating ? DesignSystem.Spacing.sm : 0)
            }
            .frame(minHeight: isMultiline ? 80 : 50)
            
            // Helper text or error text
            if let errorText = errorText {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                    Text(errorText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            } else if let helperText = helperText {
                Text(helperText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .onChange(of: text) { oldValue, newValue in
            withAnimation {
                isFloating = !newValue.isEmpty || isFocused
            }
        }
        .onChange(of: isFocused) { oldValue, newValue in
            withAnimation {
                isFloating = !text.isEmpty || newValue
            }
        }
        .onAppear {
            isFloating = !text.isEmpty
        }
    }
}

// MARK: - Enhanced Picker
struct EnhancedPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    let isRequired: Bool
    @ViewBuilder let content: () -> Content
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(title + (isRequired ? " *" : ""))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Text(selection as? String ?? "Select option")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.tertiaryBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 0) {
                    content()
                }
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                )
                .shadow(color: DesignSystem.Colors.shadow, radius: 4, x: 0, y: 2)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
}

// MARK: - Enhanced Toggle
struct EnhancedToggle: View {
    let title: String
    @Binding var isOn: Bool
    let description: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let description = description {
                        Text(description)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .tint(DesignSystem.Colors.primary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        EnhancedTextField(
            title: "Team Number",
            text: .constant(""),
            placeholder: "Enter team number",
            helperText: "Enter the team number you're scouting",
            isRequired: true
        )
        
        EnhancedTextField(
            title: "Notes",
            text: .constant("Some notes here"),
            placeholder: "Enter notes",
            isMultiline: true,
            errorText: "This field is required"
        )
        
        EnhancedPicker(title: "Alliance Color", selection: .constant("Red"), isRequired: true) {
            Text("Red").tag("Red")
            Text("Blue").tag("Blue")
        }
        
        EnhancedToggle(
            title: "Alliance Coordination",
            isOn: .constant(true),
            description: "Does this team coordinate well with alliance partners?"
        )
    }
    .padding()
}
