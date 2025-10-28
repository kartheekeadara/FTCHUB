//
//  TemplatePickerView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct TemplatePickerView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTemplate: ScoutingTemplate?
    
    var body: some View {
        NavigationView {
            List {
                if scoutingService.scoutingTemplates.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("No Templates Available")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Create a scouting template first to start collecting reports.")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(scoutingService.scoutingTemplates) { template in
                        Button(action: {
                            selectedTemplate = template
                            dismiss()
                        }) {
                            TemplatePickerRow(template: template, isSelected: selectedTemplate?.id == template.id)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TemplatePickerRow: View {
    let template: ScoutingTemplate
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(template.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let description = template.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Label("\(template.templateData.sections.count) sections", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    if template.isDefault {
                        Label("Default", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(.title2)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .contentShape(Rectangle())
    }
}

#Preview {
    TemplatePickerView(selectedTemplate: .constant(nil))
        .environmentObject(ScoutingService())
        .environmentObject(AuthService())
}
