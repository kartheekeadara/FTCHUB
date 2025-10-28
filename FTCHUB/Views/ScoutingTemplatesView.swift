//
//  ScoutingTemplatesView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct ScoutingTemplatesView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @State private var showingCreateTemplate = false
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
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                TextField("Search templates...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.tertiaryBackground)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.sm)
            
            if scoutingService.isLoading {
                ProgressView("Loading Templates...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = scoutingService.errorMessage {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(DesignSystem.Colors.error)
                    
                    Text("Error Loading Templates")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredTemplates.isEmpty {
                ContentUnavailableView {
                    Label("No Scouting Templates", systemImage: "doc.text")
                } description: {
                    Text("Create your first scouting template to start collecting match data.")
                } actions: {
                    Button("Create Template") {
                        showingCreateTemplate = true
                    }
                    .primaryButtonStyle()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(filteredTemplates) { template in
                            NavigationLink(destination: Text("Template Detail View for \(template.name)")) {
                                ScoutingTemplateCard(template: template)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                }
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreateTemplate = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(DesignSystem.Gradients.primary)
                }
            }
        }
        .sheet(isPresented: $showingCreateTemplate) {
            CreateScoutingTemplateView()
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

struct ScoutingTemplateCard: View {
    let template: ScoutingTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
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
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    if template.isDefault {
                        Label("Default", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.accent)
                    }
                    
                    Text("\(template.templateData.sections.count) sections")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            // Field count and last modified
            HStack {
                Label("\(totalFieldCount) fields", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text(template.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding()
        .cardStyle()
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
