//
//  EnhancedSettingsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct EnhancedSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var calendarService = SimplifiedCalendarService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var offlineService = OfflineService()
    @StateObject private var exportService = ExportService.shared
    @State private var showingCalendarAuth = false
    @State private var showingNotificationSettings = false
    @State private var showingExportOptions = false
    @State private var showingBackupOptions = false
    
    var body: some View {
        NavigationView {
            List {
                // User Profile Section
                Section {
                    UserProfileCard()
                }
                
                // Team Management Section
                Section("Team Management") {
                    NavigationLink(destination: TeamSettingsView()) {
                        SettingsRow(
                            icon: "person.3.fill",
                            title: "Team Settings",
                            subtitle: "Manage team information and members"
                        )
                    }
                    
                    NavigationLink(destination: MemberManagementView()) {
                        SettingsRow(
                            icon: "person.badge.plus",
                            title: "Invite Members",
                            subtitle: "Add new team members"
                        )
                    }
                }
                
                // Calendar & Events Section
                Section("Calendar & Events") {
                    Button(action: { showingCalendarAuth = true }) {
                        SettingsRow(
                            icon: "calendar",
                            title: "Google Calendar",
                            subtitle: calendarService.isConnected ? "Connected" : "Connect to sync events",
                            trailing: calendarService.isConnected ? AnyView(Image(systemName: "checkmark.circle.fill").foregroundColor(.green)) : AnyView(EmptyView())
                        )
                    }
                    .foregroundColor(.primary)
                    
                    NavigationLink(destination: EventManagementView()) {
                        SettingsRow(
                            icon: "calendar.badge.plus",
                            title: "Event Management",
                            subtitle: "Create and manage team events"
                        )
                    }
                }
                
                // Scouting & Analytics Section
                Section("Scouting & Analytics") {
                    NavigationLink(destination: ScoutingSettingsView()) {
                        SettingsRow(
                            icon: "chart.bar.fill",
                            title: "Scouting Settings",
                            subtitle: "Configure scouting templates and reports"
                        )
                    }
                    
                    NavigationLink(destination: AllianceSelectionSettingsView()) {
                        SettingsRow(
                            icon: "person.2.circle.fill",
                            title: "Alliance Selection",
                            subtitle: "Configure team ranking criteria"
                        )
                    }
                    
                    NavigationLink(destination: QRCodeSettingsView()) {
                        SettingsRow(
                            icon: "qrcode",
                            title: "QR Code Settings",
                            subtitle: "Manage QR code generation and scanning"
                        )
                    }
                }
                
                // Inventory & Finance Section
                Section("Inventory & Finance") {
                    NavigationLink(destination: InventorySettingsView()) {
                        SettingsRow(
                            icon: "cube.box.fill",
                            title: "Inventory Settings",
                            subtitle: "Configure inventory management"
                        )
                    }
                    
                    NavigationLink(destination: FinanceSettingsView()) {
                        SettingsRow(
                            icon: "dollarsign.circle.fill",
                            title: "Finance Settings",
                            subtitle: "Manage orders and budget tracking"
                        )
                    }
                }
                
                // Notifications Section
                Section("Notifications") {
                    Button(action: { showingNotificationSettings = true }) {
                        SettingsRow(
                            icon: "bell.fill",
                            title: "Notification Settings",
                            subtitle: notificationService.isAuthorized ? "Configured" : "Set up notifications"
                        )
                    }
                    .foregroundColor(.primary)
                    
                    NavigationLink(destination: GrantDeadlinesView()) {
                        SettingsRow(
                            icon: "calendar.badge.exclamationmark",
                            title: "Grant Deadlines",
                            subtitle: "Track funding opportunities"
                        )
                    }
                }
                
                // Data & Sync Section
                Section("Data & Sync") {
                    Button(action: { showingExportOptions = true }) {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "Export Data",
                            subtitle: "Export team data to CSV/PDF"
                        )
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: { showingBackupOptions = true }) {
                        SettingsRow(
                            icon: "icloud.and.arrow.up",
                            title: "Backup & Restore",
                            subtitle: "Backup or restore team data"
                        )
                    }
                    .foregroundColor(.primary)
                    
                    NavigationLink(destination: OfflineSettingsView()) {
                        SettingsRow(
                            icon: "wifi.slash",
                            title: "Offline Mode",
                            subtitle: offlineService.isOfflineMode ? "Enabled" : "Configure offline access",
                            trailing: offlineService.isOfflineMode ? AnyView(Image(systemName: "checkmark.circle.fill").foregroundColor(.green)) : AnyView(EmptyView())
                        )
                    }
                }
                
                // Privacy & Security Section
                Section("Privacy & Security") {
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(
                            icon: "lock.shield.fill",
                            title: "Privacy Settings",
                            subtitle: "Manage data privacy and security"
                        )
                    }
                    
                    NavigationLink(destination: DataManagementView()) {
                        SettingsRow(
                            icon: "externaldrive.fill",
                            title: "Data Management",
                            subtitle: "Manage stored data and cache"
                        )
                    }
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink(destination: HelpCenterView()) {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            subtitle: "Get help and contact support"
                        )
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "About",
                            subtitle: "App version and information"
                        )
                    }
                }
                
                // Sign Out Section
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
        .sheet(isPresented: $showingCalendarAuth) {
            CalendarAuthView()
                .environmentObject(calendarService)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView()
                .environmentObject(exportService)
        }
        .sheet(isPresented: $showingBackupOptions) {
            BackupOptionsView()
                .environmentObject(exportService)
        }
    }
}

struct UserProfileCard: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(DesignSystem.Gradients.primary)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(authService.currentUser?.initials ?? "?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authService.currentUser?.displayName ?? "Unknown User")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(authService.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                if let role = authService.currentUser?.role {
                    Text(role.displayName)
                        .font(.caption)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.primary.opacity(0.1))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                }
            }
            
            Spacer()
            
            Button("Edit") {
                // Navigate to profile editing
            }
            .font(.caption)
            .foregroundColor(DesignSystem.Colors.primary)
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let trailing: AnyView?
    
    init(icon: String, title: String, subtitle: String, trailing: AnyView? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
            
            if let trailing = trailing {
                trailing
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}

// MARK: - Supporting Views

struct CalendarAuthView: View {
    @EnvironmentObject var calendarService: SimplifiedCalendarService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "calendar")
                    .font(.system(size: 80))
                    .foregroundStyle(DesignSystem.Gradients.primary)
                
                Text("Connect Google Calendar")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Sync your team events with Google Calendar for seamless scheduling and reminders.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                
                if calendarService.isConnected {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connected to Google Calendar")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Button("Disconnect") {
                            calendarService.isConnected = false
                        }
                        .foregroundColor(.red)
                    }
                } else {
                    Button("Connect to Calendar") {
                        Task {
                            await calendarService.requestCalendarAccess()
                        }
                    }
                    .primaryButtonStyle()
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .navigationTitle("Calendar Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExportOptionsView: View {
    @EnvironmentObject var exportService: ExportService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .csv
    @State private var selectedData: ExportDataType = .all
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
    }
    
    enum ExportDataType: String, CaseIterable {
        case all = "All Data"
        case inventory = "Inventory Only"
        case scouting = "Scouting Only"
        case team = "Team Data Only"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("Export Team Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Export Format")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Data to Export")
                        .font(.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Picker("Data", selection: $selectedData) {
                        ForEach(ExportDataType.allCases, id: \.self) { dataType in
                            Text(dataType.rawValue).tag(dataType)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Button("Export Data") {
                    Task {
                        // Implement export logic
                    }
                }
                .primaryButtonStyle()
                .disabled(exportService.isExporting)
                
                if exportService.isExporting {
                    ProgressView("Exporting...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BackupOptionsView: View {
    @EnvironmentObject var exportService: ExportService
    @Environment(\.dismiss) private var dismiss
    @State private var isCreatingBackup = false
    @State private var isRestoringBackup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("Backup & Restore")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Create a backup of your team data or restore from a previous backup.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Button("Create Backup") {
                        Task {
                            isCreatingBackup = true
                            do {
                                let _ = try await exportService.createBackup()
                                // Handle success
                            } catch {
                                // Handle error
                            }
                            isCreatingBackup = false
                        }
                    }
                    .primaryButtonStyle()
                    .disabled(isCreatingBackup)
                    
                    Button("Restore from Backup") {
                        isRestoringBackup = true
                        // Implement file picker for backup restoration
                    }
                    .secondaryButtonStyle()
                    .disabled(isRestoringBackup)
                }
                
                if isCreatingBackup || isRestoringBackup {
                    ProgressView("Processing...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Views for Navigation

struct TeamSettingsView: View {
    var body: some View {
        Text("Team Settings")
            .navigationTitle("Team Settings")
    }
}

struct MemberManagementView: View {
    var body: some View {
        Text("Member Management")
            .navigationTitle("Invite Members")
    }
}

struct EventManagementView: View {
    var body: some View {
        Text("Event Management")
            .navigationTitle("Event Management")
    }
}

struct ScoutingSettingsView: View {
    var body: some View {
        Text("Scouting Settings")
            .navigationTitle("Scouting Settings")
    }
}

struct AllianceSelectionSettingsView: View {
    var body: some View {
        Text("Alliance Selection Settings")
            .navigationTitle("Alliance Selection")
    }
}

struct QRCodeSettingsView: View {
    var body: some View {
        Text("QR Code Settings")
            .navigationTitle("QR Code Settings")
    }
}

struct InventorySettingsView: View {
    var body: some View {
        Text("Inventory Settings")
            .navigationTitle("Inventory Settings")
    }
}

struct FinanceSettingsView: View {
    var body: some View {
        Text("Finance Settings")
            .navigationTitle("Finance Settings")
    }
}

struct GrantDeadlinesView: View {
    var body: some View {
        Text("Grant Deadlines")
            .navigationTitle("Grant Deadlines")
    }
}

struct OfflineSettingsView: View {
    var body: some View {
        Text("Offline Settings")
            .navigationTitle("Offline Mode")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy Settings")
    }
}

struct DataManagementView: View {
    var body: some View {
        Text("Data Management")
            .navigationTitle("Data Management")
    }
}

struct HelpCenterView: View {
    var body: some View {
        Text("Help & Support")
            .navigationTitle("Help & Support")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "app.fill")
                .font(.system(size: 80))
                .foregroundStyle(DesignSystem.Gradients.primary)
            
            Text("FTC Team Hub")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("A comprehensive team management app for FIRST Tech Challenge teams.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}

#Preview {
    EnhancedSettingsView()
        .environmentObject(AuthService())
}
