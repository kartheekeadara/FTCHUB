//
//  AddScoutingSectionView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct AddScoutingSectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var fields: [ScoutingField] = []
    @State private var showingAddField = false
    
    let onSave: (ScoutingSection) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Section Details") {
                    CustomTextField(title: "Title", text: $title, placeholder: "e.g., Autonomous, Teleop, Endgame")
                }
                
                Section("Fields") {
                    if fields.isEmpty {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 30))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text("No fields yet")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Button("Add First Field") {
                                showingAddField = true
                            }
                            .primaryButtonStyle()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(fields) { field in
                            ScoutingFieldRow(field: field)
                        }
                        .onDelete(perform: deleteFields)
                    }
                }
                
                Section {
                    Button("Add Field") {
                        showingAddField = true
                    }
                    .frame(maxWidth: .infinity)
                    .secondaryButtonStyle()
                }
            }
            .navigationTitle("Add Section")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSection()
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingAddField) {
                AddScoutingFieldView { newField in
                    fields.append(newField)
                }
            }
        }
    }
    
    var isFormValid: Bool {
        !title.isEmpty
    }
    
    private func deleteFields(at offsets: IndexSet) {
        fields.remove(atOffsets: offsets)
    }
    
    private func saveSection() {
        let section = ScoutingSection(title: title, fields: fields, order: 0)
        onSave(section)
        dismiss()
    }
}

struct ScoutingFieldRow: View {
    let field: ScoutingField
    
    var body: some View {
        HStack {
            Image(systemName: field.type.icon)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(field.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(field.type.displayName)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            if field.isRequired {
                Text("Required")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.accent)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(DesignSystem.Colors.accent.opacity(0.2))
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            }
        }
    }
}

#Preview {
    AddScoutingSectionView { _ in }
}
