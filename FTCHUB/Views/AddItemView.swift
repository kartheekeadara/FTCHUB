//
//  AddItemView.swift
//  FTCHUB
//
//  Unified interface for adding Tasks or Events
//

import SwiftUI

enum ItemType {
    case task
    case event
}

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var authService: AuthService
    @StateObject private var calendarService = SimplifiedCalendarService()
    @ObservedObject private var notificationService = NotificationService.shared
    
    @State private var selectedType: ItemType?
    @State private var showingTaskForm = false
    @State private var showingEventForm = false
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(DesignSystem.Gradients.primary)
                    
                    Text("Add Item")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Choose what you want to add")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.top, DesignSystem.Spacing.xl)
                
                // Type Selection
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Task Option
                    Button {
                        selectedType = .task
                        showingTaskForm = true
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.primary.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "checklist")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Task")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Text("Create a task with due date")
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Event Option
                    Button {
                        selectedType = .event
                        showingEventForm = true
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(DesignSystem.Colors.accent.opacity(0.15))
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Event")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                Text("Schedule a team event")
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.border.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                Spacer()
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTaskForm) {
            // Directly open task creation form
            CreateTaskView(selectedDate: selectedDate)
                .environmentObject(teamService)
                .environmentObject(authService)
                .onDisappear {
                    Task {
                        await teamService.loadTeamData()
                    }
                }
        }
        .sheet(isPresented: $showingEventForm) {
            // Create event editor with new draft and auto-present
            EventCreationView()
                .environmentObject(calendarService)
                .environmentObject(teamService)
                .environmentObject(notificationService)
                .onDisappear {
                    Task {
                        await teamService.loadTeamData()
                        await calendarService.loadTeamEvents()
                    }
                }
        }
        .onAppear {
            // Ensure calendar service has team context
            if let teamId = teamService.currentTeam?.id {
                calendarService.updateTeamContext(teamId: teamId)
            }
        }
    }
}
