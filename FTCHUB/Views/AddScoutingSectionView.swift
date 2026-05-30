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
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignSystem.Colors.primary.opacity(0.15),
                                                DesignSystem.Colors.primary.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundStyle(DesignSystem.Gradients.primary)
                            }
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                Text("No fields yet")
                                    .font(.headline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text("Add your first field to start building this section")
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button {
                                showingAddField = true
                            } label: {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Add First Field")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(DesignSystem.Gradients.primary)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.xl)
                        .padding(.horizontal, DesignSystem.Spacing.md)
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
