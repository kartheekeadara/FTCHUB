//
//  CreateScoutingTemplateView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct CreateScoutingTemplateView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var isDefault = false
    @State private var sections: [ScoutingSection] = []
    @State private var showingAddSection = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Template Details") {
                    CustomTextField(title: "Name", text: $name, placeholder: "e.g., FTC Match Scouting")
                    CustomTextField(title: "Description", text: $description, placeholder: "Optional description", isMultiline: true)
                    
                    Toggle("Default Template", isOn: $isDefault)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Section("Sections") {
                    if sections.isEmpty {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text("No sections yet")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Button("Add First Section") {
                                showingAddSection = true
                            }
                            .primaryButtonStyle()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(sections) { section in
                            NavigationLink(destination: EditScoutingSectionView(section: section, onSave: { updatedSection in
                                if let index = sections.firstIndex(where: { $0.id == updatedSection.id }) {
                                    sections[index] = updatedSection
                                }
                            })) {
                                ScoutingSectionRow(section: section)
                            }
                        }
                        .onDelete(perform: deleteSections)
                    }
                }
                
                Section {
                    Button("Add Section") {
                        showingAddSection = true
                    }
                    .frame(maxWidth: .infinity)
                    .secondaryButtonStyle()
                }
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveTemplate()
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingAddSection) {
                AddScoutingSectionView { newSection in
                    sections.append(newSection)
                }
            }
            .alert("Error", isPresented: Binding(get: { scoutingService.errorMessage != nil }, set: { _ in scoutingService.errorMessage = nil })) {
                Button("OK") { }
            } message: {
                Text(scoutingService.errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    var isFormValid: Bool {
        !name.isEmpty && !sections.isEmpty
    }
    
    private func deleteSections(at offsets: IndexSet) {
        sections.remove(atOffsets: offsets)
    }
    
    private func saveTemplate() async {
        var formData = ScoutingFormData()
        formData.sections = sections
        
        let template = ScoutingTemplate(
            id: UUID(),
            teamId: UUID(uuidString: "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")!, // TODO: Get from AuthService
            name: name,
            description: description.isEmpty ? nil : description,
            isDefault: isDefault,
            templateData: formData,
            createdBy: nil, // TODO: Get from AuthService
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await scoutingService.createScoutingTemplate(template: template)
            dismiss()
        } catch {
            // Error handled by service
        }
    }
}

struct ScoutingSectionRow: View {
    let section: ScoutingSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(section.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text("\(section.fields.count) fields")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

#Preview {
    CreateScoutingTemplateView()
        .environmentObject(ScoutingService())
        .environmentObject(AuthService())
}
