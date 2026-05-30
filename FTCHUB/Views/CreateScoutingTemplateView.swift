//
//  CreateScoutingTemplateView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct CreateScoutingTemplateView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var teamService: TeamService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var isDefault = false
    @State private var sections: [ScoutingSection] = []
    @State private var showingAddSection = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Project/Team header
                    if let team = teamService.currentTeam {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(team.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text("Scouting Template")
                                    .font(.system(size: 14))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    // Template name
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Template name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        TextField("e.g., FTC Match Scouting", text: $name)
                            .textInputAutocapitalization(.words)
                            .font(.system(size: 16))
                            .padding(DesignSystem.Spacing.md)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .focused($nameFieldFocused)
                        
                        if let validation = nameValidationMessage {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.error)
                                Text(validation)
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.error)
                            }
                            .padding(.top, DesignSystem.Spacing.xs)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Quick start
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Quick start")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Menu {
                            ForEach(QuickStartPreset.allCases) { preset in
                                Button(preset.title) {
                                    applyQuickStart(preset)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 14))
                                Text("Choose a preset layout")
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(DesignSystem.Spacing.md)
                            .frame(maxWidth: .infinity)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Sections
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("Sections")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Spacer()
                            
                            Button {
                                showingAddSection = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12))
                                    Text("Add")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        
                        if sections.isEmpty {
                            VStack(spacing: DesignSystem.Spacing.md) {
                                Image(systemName: "square.grid.2x2.dashed")
                                    .font(.system(size: 44, weight: .light))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                Text("No sections yet")
                                    .font(.headline)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text("Start by adding your first section to shape this template.")
                                    .font(.footnote)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                
                                Button {
                                    showingAddSection = true
                                } label: {
                                    Label("Add Your First Section", systemImage: "plus.circle.fill")
                                        .font(.body.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, DesignSystem.Spacing.md)
                                        .background(DesignSystem.Gradients.primary)
                                        .foregroundColor(.white)
                                        .cornerRadius(DesignSystem.CornerRadius.md)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(DesignSystem.Spacing.lg)
                            .background(DesignSystem.Colors.tertiaryBackground)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        } else {
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(sections) { section in
                                    NavigationLink(destination: EditScoutingSectionView(section: section, onSave: { updatedSection in
                                        if let index = sections.firstIndex(where: { $0.id == updatedSection.id }) {
                                            sections[index] = sectionWithNormalizedFieldOrder(updatedSection)
                                            updateSectionOrders()
                                        }
                                    })) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(section.title)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                                
                                                Text("\(section.fields.count) fields")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(DesignSystem.Colors.textTertiary)
                                        }
                                        .padding(DesignSystem.Spacing.md)
                                        .background(DesignSystem.Colors.tertiaryBackground)
                                        .cornerRadius(DesignSystem.CornerRadius.md)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Description
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Description")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Add a description...")
                                    .font(.system(size: 16))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $description)
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Save button
                    Button {
                        Task {
                            await saveTemplate()
                        }
                    } label: {
                        Text("Create template")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(DesignSystem.Gradients.primary)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isFormValid || isSaving)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                }
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddSection) {
                AddScoutingSectionView { newSection in
                    appendSection(newSection)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var nameValidationMessage: String? {
        if trimmedName.isEmpty {
            return "Name is required"
        }
        let existingNames = scoutingService.scoutingTemplates.map { $0.name.lowercased() }
        if existingNames.contains(trimmedName.lowercased()) {
            return "A template with this name already exists"
        }
        return nil
    }
    
    private var isFormValid: Bool {
        nameValidationMessage == nil && !sections.isEmpty
    }
    
    private var canAddMoreSections: Bool {
        sections.count < 12
    }
    
    private func deleteSections(at offsets: IndexSet) {
        sections.remove(atOffsets: offsets)
        updateSectionOrders()
    }
    
    private func moveSections(from source: IndexSet, to destination: Int) {
        sections.move(fromOffsets: source, toOffset: destination)
        updateSectionOrders()
    }
    
    private func appendSection(_ newSection: ScoutingSection) {
        sections.append(sectionWithNormalizedFieldOrder(newSection))
        updateSectionOrders()
    }
    
    private func updateSectionOrders() {
        sections = sections.enumerated().map { index, section in
            sectionWithOrder(section, order: index)
        }
    }
    
    private func sectionWithOrder(_ section: ScoutingSection, order: Int) -> ScoutingSection {
        var updated = section
        updated.order = order
        updated.fields = section.fields.enumerated().map { idx, field in
            var mutable = field
            mutable.order = idx
            return mutable
        }
        return updated
    }
    
    private func sectionWithNormalizedFieldOrder(_ section: ScoutingSection) -> ScoutingSection {
        sectionWithOrder(section, order: section.order)
    }
    
    private func normalizedSections() -> [ScoutingSection] {
        sections.enumerated().map { index, section in
            sectionWithOrder(section, order: index)
        }
    }
    
    private func quickStartSections(for preset: QuickStartPreset) -> [ScoutingSection] {
        switch preset {
        case .decodeMatch:
            if let teamId = scoutingService.currentTeamId {
                return ScoutingTemplate.defaultDecode(teamId: teamId).templateData.sections
            } else {
                return ScoutingTemplate.sample.templateData.sections
            }
        case .pitScouting:
            return [
                ScoutingSection(title: "Robot Overview", fields: [
                    ScoutingField(type: .multipleChoice, title: "Drive Base", isRequired: true, options: ["Mecanum", "Tank", "Swerve", "Omni"]),
                    ScoutingField(type: .multipleChoice, title: "Primary Mechanism", options: ["Elevator", "Arm", "Intake", "Hybrid"]),
                    ScoutingField(type: .boolean, title: "Has Spare Robot Parts", description: "Team carries critical spares"),
                    ScoutingField(type: .notes, title: "Robot Notes")
                ]),
                ScoutingSection(title: "Team Logistics", fields: [
                    ScoutingField(type: .boolean, title: "Has Drive Coach", description: "Dedicated drive coach present"),
                    ScoutingField(type: .multipleChoice, title: "Communication Style", options: ["Hands On", "Independent", "Strategic Planner"]),
                    ScoutingField(type: .notes, title: "Pit Interview Highlights")
                ])
            ]
        case .allianceDebrief:
            return [
                ScoutingSection(title: "Alliance Pairing", fields: [
                    ScoutingField(type: .multipleChoice, title: "Preferred Alliance Role", options: ["Primary Scorer", "Secondary Scorer", "Defense", "Support"]),
                    ScoutingField(type: .slider, title: "Synergy Rating", description: "How well did we work together?", minValue: 1, maxValue: 5, step: 1),
                    ScoutingField(type: .notes, title: "Synergy Notes")
                ]),
                ScoutingSection(title: "Strengths & Risks", fields: [
                    ScoutingField(type: .notes, title: "Strengths"),
                    ScoutingField(type: .notes, title: "Weaknesses"),
                    ScoutingField(type: .boolean, title: "Consistent Endgame"),
                    ScoutingField(type: .boolean, title: "Penalty Risk")
                ])
            ]
        }
    }
    
    private func applyQuickStart(_ preset: QuickStartPreset) {
        let generated = quickStartSections(for: preset)
        sections = generated.map(sectionWithNormalizedFieldOrder)
        updateSectionOrders()
        
        switch preset {
        case .decodeMatch:
            name = "DECODE Match Scouting"
            description = "Standard FTC DECODE match template covering autonomous, teleop, and endgame performance."
        case .pitScouting:
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = "Pit Scouting"
            }
        case .allianceDebrief:
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = "Alliance Debrief"
            }
        }
    }
    
    private func saveTemplate() async {
        guard let teamId = scoutingService.currentTeamId ?? teamService.currentTeam?.id else {
            errorMessage = "Join or create a team before saving scouting templates."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        var formData = ScoutingFormData()
        formData.sections = normalizedSections()
        formData.lastModified = Date()
        
        let template = ScoutingTemplate(
            id: UUID(),
            teamId: teamId,
            name: trimmedName,
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            isDefault: isDefault,
            templateData: formData,
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await scoutingService.createScoutingTemplate(template: template)
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSaving = false
            }
        }
    }
}

private enum QuickStartPreset: String, CaseIterable, Identifiable {
    case decodeMatch
    case pitScouting
    case allianceDebrief
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .decodeMatch: return "DECODE Match Layout"
        case .pitScouting: return "Pit Scouting"
        case .allianceDebrief: return "Alliance Debrief"
        }
    }
}

#Preview {
    CreateScoutingTemplateView()
        .environmentObject(ScoutingService())
        .environmentObject(AuthService())
        .environmentObject(TeamService())
}
