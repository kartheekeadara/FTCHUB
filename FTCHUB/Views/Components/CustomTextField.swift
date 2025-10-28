//
//  CustomTextField.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isMultiline: Bool = false
    var isSecure: Bool = false
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.tertiaryBackground)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .disabled(isDisabled)
            } else if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(CustomTextFieldStyle())
                    .disabled(isDisabled)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(CustomTextFieldStyle())
                    .disabled(isDisabled)
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
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
