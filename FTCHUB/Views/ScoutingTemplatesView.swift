//
//  ScoutingTemplatesView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct ScoutingTemplatesView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var scheduleService: ScheduleService
    var scoutingSelectedTab: Binding<Int> = .constant(1)
    var isEmbeddedInScoutingHub: Bool = false
    
    @State private var showingCreateTemplate = false
    @State private var selectedTemplate: ScoutingTemplate? = nil
    @State private var searchText = ""
    
    var filteredTemplates: [ScoutingTemplate] {
        if searchText.isEmpty {
            return scoutingService.scoutingTemplates
        } else {
            return scoutingService.scoutingTemplates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.md) {
                ScoutingSearchBar(
                    text: $searchText,
                    placeholder: "Search templates...",
                    isEmbeddedInScoutingHub: isEmbeddedInScoutingHub
                )
                
                if scoutingService.isLoading {
                    EnhancedLoadingView(message: "Loading Templates...")
                        .frame(minHeight: 200)
                } else if let errorMessage = scoutingService.errorMessage {
                    ErrorView(
                        error: ErrorHandler.userFriendlyError(from: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]), context: "Loading scouting templates"),
                        onRetry: {
                            Task {
                                await scoutingService.loadScoutingData()
                            }
                        }
                    )
                } else if filteredTemplates.isEmpty {
                    EnhancedEmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No Templates Found",
                        message: "Create a scouting template to start collecting match data. Templates define the fields you'll fill out when scouting teams.",
                        actionTitle: "Create Template",
                        action: {
                            showingCreateTemplate = true
                        }
                    )
                } else {
                    LazyVStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(filteredTemplates) { template in
                            ScoutingTemplateRow(
                                template: template,
                                onSelect: {
                                    selectedTemplate = template
                                },
                                onDelete: {
                                    Task {
                                        do {
                                            try await scoutingService.deleteScoutingTemplate(template: template)
                                        } catch {
                                            // Error handled by service
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(isEmbeddedInScoutingHub ? "" : "Templates")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateTemplate = true
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text("New")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Gradients.primary)
                }
            }
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateScoutingTemplateView()
                .environmentObject(scoutingService)
                .environmentObject(teamService)
        }
        .sheet(item: $selectedTemplate) { template in
            DynamicScoutingFormView(template: template)
                .environmentObject(scoutingService)
        }
        .onAppear {
            Task {
                await scoutingService.loadScoutingData()
            }
        }
        .refreshable {
            await scoutingService.loadScoutingData()
        }
    }
}

struct ScoutingTemplateRow: View {
    let template: ScoutingTemplate
    let onSelect: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Button(action: onSelect) {
                ScoutingTemplateCard(template: template)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete button (only for non-default templates)
            if !template.isDefault {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(DesignSystem.Colors.error)
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.error.opacity(0.1))
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Template", systemImage: "trash")
            }
            .disabled(template.isDefault)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !template.isDefault {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Delete Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \"\(template.name)\"? This action cannot be undone.")
        }
    }
}

struct ScoutingTemplateCard: View {
    let template: ScoutingTemplate
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Gradients.primary.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "doc.text.fill")
                    .font(.title2)
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
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var totalFieldCount: Int {
        template.templateData.sections.reduce(0) { $0 + $1.fields.count }
    }
}

#Preview {
    NavigationView {
        ScoutingTemplatesView()
            .environmentObject(ScoutingService())
            .environmentObject(AuthService())
    }
}
