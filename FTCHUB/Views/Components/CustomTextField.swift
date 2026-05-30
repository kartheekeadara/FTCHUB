//
//  CustomTextField.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isMultiline: Bool = false
    var isSecure: Bool = false
    var isDisabled: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @FocusState private var isFocused: Bool
    @State private var showPassword: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tertiaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(isFocused ? DesignSystem.Colors.primary : DesignSystem.Colors.border, lineWidth: isFocused ? 2 : 1)
                    )
                    .disabled(isDisabled)
                    .focused($isFocused)
            } else if isSecure {
                HStack {
                    if showPassword {
                        TextField(placeholder, text: $text)
                            .textFieldStyle(CustomTextFieldStyle(isFocused: isFocused))
                            .disabled(isDisabled)
                            .focused($isFocused)
                    } else {
                        SecureField(placeholder, text: $text)
                            .textFieldStyle(CustomTextFieldStyle(isFocused: isFocused))
                            .disabled(isDisabled)
                            .focused($isFocused)
                    }
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.trailing, DesignSystem.Spacing.sm)
                    }
                }
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(CustomTextFieldStyle(isFocused: isFocused))
                    .keyboardType(keyboardType)
                    .disabled(isDisabled)
                    .focused($isFocused)
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    var isFocused: Bool = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isFocused ? DesignSystem.Colors.primary : DesignSystem.Colors.border, lineWidth: isFocused ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextField(
            title: "Item Name",
            text: .constant("Sample Item"),
            placeholder: "Enter item name"
        )
        
        CustomTextField(
            title: "Description",
            text: .constant("This is a sample description"),
            placeholder: "Enter description",
            isMultiline: true
        )
    }
    .padding()
}
