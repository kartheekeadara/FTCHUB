//
//  EditScoutingSectionView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct EditScoutingSectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var section: ScoutingSection
    @State private var showingAddField = false
    
    let onSave: (ScoutingSection) -> Void
    
    init(section: ScoutingSection, onSave: @escaping (ScoutingSection) -> Void) {
        self._section = State(initialValue: section)
        self.onSave = onSave
    }
    
    var body: some View {
        Form {
            Section("Section Details") {
                CustomTextField(title: "Title", text: Binding(
                    get: { section.title },
                    set: { section.title = $0 }
                ), placeholder: "Section title")
            }
            
            Section("Fields") {
                if section.fields.isEmpty {
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
                    ForEach(section.fields) { field in
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
        .navigationTitle("Edit Section")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    onSave(section)
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingAddField) {
            AddScoutingFieldView { newField in
                section.fields.append(newField)
            }
        }
    }
    
    private func deleteFields(at offsets: IndexSet) {
        section.fields.remove(atOffsets: offsets)
    }
}

#Preview {
    NavigationView {
        EditScoutingSectionView(section: ScoutingSection(title: "Test Section", fields: [])) { _ in }
    }
}
