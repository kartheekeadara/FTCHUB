//
//  ScoutingTemplatePickerView.swift
//  FTCHUB
//
//  Created on 11/23/25.
//

import SwiftUI

struct ScoutingTemplatePickerView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTemplate: ScoutingTemplate?
    @State private var localSelectedTemplate: ScoutingTemplate?
    @State private var showingCreateTemplate = false
    var onTemplateSelected: ((ScoutingTemplate?) -> Void)?
    var onCancel: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if scoutingService.scoutingTemplates.isEmpty {
                    // No templates - prompt to create one
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Spacer()
                        
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 80))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("No Templates Available")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Create a scouting template first to start collecting reports. Templates define the fields you'll fill out when scouting teams.")
                            .font(.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.xl)
                        
                        Button(action: {
                            showingCreateTemplate = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Template")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignSystem.Spacing.xl)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(DesignSystem.Gradients.primary)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, DesignSystem.Spacing.md)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Show template selection
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("Select a Template")
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(.top, DesignSystem.Spacing.lg)
                            
                            Text("Choose which template you'd like to use for this scouting report")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                .padding(.bottom, DesignSystem.Spacing.md)
                            
                            LazyVStack(spacing: DesignSystem.Spacing.md) {
                                ForEach(scoutingService.scoutingTemplates) { template in
                                    TemplateSelectionCard(
                                        template: template,
                                        isSelected: localSelectedTemplate?.id == template.id
                                    ) {
                                        localSelectedTemplate = template
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Action buttons
                            VStack(spacing: DesignSystem.Spacing.md) {
                                if let template = localSelectedTemplate {
                                    Button(action: {
                                        // Update the binding first
                                        selectedTemplate = template
                                        // Call the callback with the template - this sets state in parent and handles dismissal
                                        onTemplateSelected?(template)
                                        // Don't call dismiss() here - let the parent handle it via showingTemplatePicker = false
                                    }) {
                                        HStack {
                                            Text("Continue with \(template.name)")
                                                .fontWeight(.semibold)
                                            Image(systemName: "arrow.right")
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, DesignSystem.Spacing.md)
                                        .background(DesignSystem.Gradients.primary)
                                        .cornerRadius(DesignSystem.CornerRadius.md)
                                        .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                }
                                
                                // Option to create without template
                                Button(action: {
                                    // Pass nil to indicate no template selected - use generic form
                                    selectedTemplate = nil
                                    onTemplateSelected?(nil)
                                }) {
                                    HStack {
                                        Text("Create Without Template")
                                            .fontWeight(.medium)
                                        Image(systemName: "doc.text")
                                    }
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DesignSystem.Spacing.md)
                                    .background(DesignSystem.Colors.primary.opacity(0.1))
                                    .cornerRadius(DesignSystem.CornerRadius.md)
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.lg)
                            .padding(.bottom, DesignSystem.Spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Reset local selection
                        localSelectedTemplate = nil
                        selectedTemplate = nil
                        // Call cancel callback to reset parent state
                        onCancel?()
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateScoutingTemplateView()
                    .environmentObject(scoutingService)
            }
            .task {
                await scoutingService.loadScoutingData()
            }
        }
    }
}

struct TemplateSelectionCard: View {
    let template: ScoutingTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(DesignSystem.Gradients.primary.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.title3)
                        .foregroundStyle(DesignSystem.Gradients.primary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text(template.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if template.isDefault {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.accent)
                        }
                    }
                    
                    if let description = template.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Label("\(template.templateData.sections.count) sections", systemImage: "list.bullet")
                        Label("\(totalFieldCount) fields", systemImage: "square.grid.2x2")
                    }
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .background(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var totalFieldCount: Int {
        template.templateData.sections.reduce(0) { $0 + $1.fields.count }
    }
}

#Preview {
    ScoutingTemplatePickerView(selectedTemplate: .constant(nil), onTemplateSelected: { _ in })
        .environmentObject(ScoutingService())
}

