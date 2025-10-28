//
//  MainTabView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
import Combine

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var teamService = TeamService()
    @StateObject private var inventoryService = InventoryService()
    @StateObject private var scoutingService = ScoutingService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TeamView()
                .environmentObject(teamService)
                .tabItem {
                    Label("Team", systemImage: selectedTab == 0 ? "person.3.fill" : "person.3")
                }
                .tag(0)
            
            InventoryView()
                .environmentObject(inventoryService)
                .tabItem {
                    Label("Inventory", systemImage: selectedTab == 1 ? "cube.box.fill" : "cube.box")
                }
                .tag(1)
            
            ScoutingView()
                .environmentObject(scoutingService)
                .tabItem {
                    Label("Scouting", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(2)
            
            CompetitionView()
                .tabItem {
                    Label("Competition", systemImage: selectedTab == 3 ? "trophy.fill" : "trophy")
                }
                .tag(3)
            
            EnhancedSettingsView()
                .environmentObject(authService)
                .tabItem {
                    Label("Settings", systemImage: selectedTab == 4 ? "gear.fill" : "gear")
                }
                .tag(4)
        }
        .tint(DesignSystem.Colors.primary)
        .onAppear {
            // Only load data if not in preview mode
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                Task {
                    await teamService.loadTeamData()
                }
            }
        }
    }
}

// MARK: - Enhanced Team View
struct TeamView: View {
    @EnvironmentObject var teamService: TeamService
    @State private var showingCreateTeam = false
    @State private var showingJoinTeam = false
    
    var body: some View {
        NavigationView {
            Group {
                if teamService.currentTeam == nil {
                    NoTeamView(
                        showingCreateTeam: $showingCreateTeam,
                        showingJoinTeam: $showingJoinTeam
                    )
                } else {
                    TeamDashboardView()
                }
            }
            .navigationTitle("Team")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create Team") {
                            showingCreateTeam = true
                        }
                        Button("Join Team") {
                            showingJoinTeam = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateTeam) {
            TeamCreationView()
                .environmentObject(teamService)
        }
        .sheet(isPresented: $showingJoinTeam) {
            TeamJoinView()
                .environmentObject(teamService)
        }
    }
}

struct NoTeamView: View {
    @Binding var showingCreateTeam: Bool
    @Binding var showingJoinTeam: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "person.3")
                    .font(.system(size: 80))
                    .foregroundStyle(DesignSystem.Gradients.primary)
                
                Text("Welcome to FTC Team Hub!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Create a new team or join an existing one to get started with managing your FTC team.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Button(action: { showingCreateTeam = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Team")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .primaryButtonStyle()
                }
                
                Button(action: { showingJoinTeam = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join Existing Team")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .secondaryButtonStyle()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            
            Spacer()
        }
    }
}

struct TeamDashboardView: View {
    @EnvironmentObject var teamService: TeamService
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.lg) {
                // Team Header
                TeamHeaderCard()
                
                // Quick Stats
                QuickStatsCard()
                
                // Upcoming Events
                UpcomingEventsCard()
                
                // Recent Tasks
                RecentTasksCard()
            }
            .padding(DesignSystem.Spacing.md)
        }
        .refreshable {
            await teamService.loadTeamData()
        }
    }
}

struct TeamHeaderCard: View {
    @EnvironmentObject var teamService: TeamService
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text(teamService.currentTeam?.displayName ?? "Team")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let location = teamService.currentTeam?.location {
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(DesignSystem.Gradients.primary)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(teamService.currentTeam?.number ?? "?")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            
            HStack {
                Label("\(teamService.teamMembers.count) Members", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("Active", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.success)
            }
        }
        .padding()
        .cardStyle()
    }
}

struct QuickStatsCard: View {
    @EnvironmentObject var teamService: TeamService
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: DesignSystem.Spacing.lg) {
                StatItem(
                    title: "Events",
                    value: "\(teamService.events.count)",
                    icon: "calendar",
                    color: DesignSystem.Colors.primary
                )
                
                StatItem(
                    title: "Tasks",
                    value: "\(teamService.tasks.count)",
                    icon: "checklist",
                    color: DesignSystem.Colors.accent
                )
                
                StatItem(
                    title: "Members",
                    value: "\(teamService.teamMembers.count)",
                    icon: "person.2",
                    color: DesignSystem.Colors.secondary
                )
            }
        }
        .padding()
        .cardStyle()
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct UpcomingEventsCard: View {
    @EnvironmentObject var teamService: TeamService
    
    var upcomingEvents: [Event] {
        teamService.events
            .filter { $0.startDate > Date() }
            .prefix(3)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Upcoming Events")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to events view
                }
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.primary)
            }
            
            if upcomingEvents.isEmpty {
                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(upcomingEvents) { event in
                    EventRowView(event: event)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(Color(event.eventType.color))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(event.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: event.eventType.icon)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

struct RecentTasksCard: View {
    @EnvironmentObject var teamService: TeamService
    
    var recentTasks: [TeamTask] {
        teamService.tasks.prefix(3).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text("Recent Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to tasks view
                }
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.primary)
            }
            
            if recentTasks.isEmpty {
                Text("No tasks yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentTasks) { task in
                    TaskRowView(task: task)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct TaskRowView: View {
    let task: TeamTask
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(Color(task.status.color))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(task.status.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if task.priority == .urgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.error)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}


struct ScoutingView: View {
    @EnvironmentObject var scoutingService: ScoutingService
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Picker
                Picker("Scouting Tab", selection: $selectedTab) {
                    Text("Templates").tag(0)
                    Text("Reports").tag(1)
                    Text("Analytics").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(DesignSystem.Spacing.md)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    ScoutingTemplatesView()
                        .environmentObject(scoutingService)
                        .tag(0)
                    
                    ScoutingReportsView()
                        .environmentObject(scoutingService)
                        .tag(1)
                    
                    ScoutingAnalyticsView()
                        .environmentObject(scoutingService)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Scouting")
            .background(DesignSystem.Colors.background)
            .onAppear {
                // Only load data if not in preview mode
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                    Task {
                        await scoutingService.loadScoutingData()
                    }
                }
            }
        }
    }
}

struct CompetitionView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "trophy")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("Competition Tools")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                    }
                    .padding(.top, DesignSystem.Spacing.xl)
                    
                    // Quick Access Cards
                    NavigationLink(destination: DriveTeamTimerView()) {
                        CompetitionToolCard(
                            title: "Drive Team Timer",
                            description: "Match phase timer with alerts",
                            icon: "timer",
                            color: DesignSystem.Colors.primary
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: ScoringCalculatorView()) {
                        CompetitionToolCard(
                            title: "Scoring Calculator",
                            description: "Calculate match scores",
                            icon: "calculator",
                            color: DesignSystem.Colors.accent
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: MatchScheduleView()) {
                        CompetitionToolCard(
                            title: "Match Schedule",
                            description: "View and import match schedules",
                            icon: "calendar",
                            color: DesignSystem.Colors.secondary
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: RulesReferenceView()) {
                        CompetitionToolCard(
                            title: "Rules Reference",
                            description: "Search game rules and regulations",
                            icon: "book",
                            color: DesignSystem.Colors.primary
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(DesignSystem.Spacing.md)
            }
            .navigationTitle("Competition")
            .background(DesignSystem.Colors.background)
        }
    }
}

struct CompetitionToolCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.textTertiary)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: DesignSystem.Colors.shadow, radius: 6, x: 0, y: 2)
        )
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(DesignSystem.Gradients.primary)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(authService.currentUser?.initials ?? "?")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(authService.currentUser?.displayName ?? "Unknown User")
                                .font(.headline)
                            Text(authService.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    Button("Edit Profile") {
                        // TODO: Implement profile editing
                    }
                    
                    Button("Change Password") {
                        // TODO: Implement password change
                    }
                }
                
                Section("Team") {
                    Button("Team Settings") {
                        // TODO: Implement team settings
                    }
                    
                    Button("Invite Members") {
                        // TODO: Implement member invitation
                    }
                }
                
                Section("App") {
                    Button("Notifications") {
                        // TODO: Implement notification settings
                    }
                    
                    Button("Data & Privacy") {
                        // TODO: Implement privacy settings
                    }
                    
                    Button("Help & Support") {
                        // TODO: Implement help system
                    }
                }
                
                Section {
                    Button("Sign Out", role: .destructive) {
                        Task {
                            try? await authService.signOut()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    // Use actual services but they will use mock data in preview mode
    let authService = AuthService()
    let teamService = TeamService()
    let inventoryService = InventoryService()
    let scoutingService = ScoutingService()
    
    return MainTabView()
        .environmentObject(authService)
        .environmentObject(teamService)
        .environmentObject(inventoryService)
        .environmentObject(scoutingService)
}

// Mock services removed - using actual services with preview mode handling
