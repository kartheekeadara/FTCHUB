//
//  AddScoutingFieldView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct AddScoutingFieldView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var type: ScoutingFieldType = .text
    @State private var title = ""
    @State private var description = ""
    @State private var isRequired = false
    @State private var options: [String] = []
    @State private var minValue: Double = 0
    @State private var maxValue: Double = 10
    @State private var step: Double = 1
    @State private var newOption = ""
    
    let onSave: (ScoutingField) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Field Type") {
                    Picker("Type", selection: $type) {
                        ForEach(ScoutingFieldType.allCases, id: \.self) { fieldType in
                            HStack {
                                Image(systemName: fieldType.icon)
                                Text(fieldType.displayName)
                            }
                            .tag(fieldType)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Field Details") {
                    CustomTextField(title: "Title", text: $title, placeholder: "e.g., Driving Quality")
                    CustomTextField(title: "Description", text: $description, placeholder: "Optional description", isMultiline: true)
                    
                    Toggle("Required", isOn: $isRequired)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                // Type-specific options
                if type == .multipleChoice {
                    Section("Options") {
                        ForEach(options, id: \.self) { option in
                            HStack {
                                Text(option)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Spacer()
                                
                                Button("Remove") {
                                    options.removeAll { $0 == option }
                                }
                                .foregroundColor(DesignSystem.Colors.error)
                                .font(.caption)
                            }
                        }
                        
                        HStack {
                            TextField("Add option", text: $newOption)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Add") {
                                if !newOption.isEmpty {
                                    options.append(newOption)
                                    newOption = ""
                                }
                            }
                            .disabled(newOption.isEmpty)
                        }
                    }
                }
                
                if type == .slider || type == .number {
                    Section("Range") {
                        HStack {
                            Text("Min Value")
                            Spacer()
                            TextField("Min", value: $minValue, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("Max Value")
                            Spacer()
                            TextField("Max", value: $maxValue, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                        }
                        
                        if type == .slider {
                            HStack {
                                Text("Step")
                                Spacer()
                                TextField("Step", value: $step, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 80)
                            }
                        }
                    }
                }
                
                if type == .rating {
                    Section("Rating Details") {
                        Text("This field will collect ratings from 1 to 5 stars")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("Add Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveField()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    var isFormValid: Bool {
        if !title.isEmpty {
            if type == .multipleChoice {
                return !options.isEmpty
            }
            return true
        }
        return false
    }
    
    private func saveField() {
        let field = ScoutingField(
            type: type,
            title: title,
            description: description.isEmpty ? nil : description,
            isRequired: isRequired,
            options: options.isEmpty ? nil : options,
            minValue: (type == .slider || type == .number) ? minValue : nil,
            maxValue: (type == .slider || type == .number) ? maxValue : nil,
            step: type == .slider ? step : nil
        )
        
        onSave(field)
        dismiss()
    }
}

#Preview {
    AddScoutingFieldView { _ in }
}
