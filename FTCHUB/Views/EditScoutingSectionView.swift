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
