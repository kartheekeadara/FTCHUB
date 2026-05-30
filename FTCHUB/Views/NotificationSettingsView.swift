//
//  NotificationSettingsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject private var notificationService: NotificationService
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isRequestingAuthorization = false
    @State private var showPendingSheet = false
    
    private var pendingNotifications: [UNNotificationRequest] {
        notificationService.pendingNotifications
    }
    
    private var isPermissionDenied: Bool {
        notificationService.authorizationStatus == .denied
    }
    
    var body: some View {
        Form {
            permissionSection
            
            if notificationService.isAuthorized {
                reminderSections
                pendingNotificationsSection
            }
        }
        .navigationTitle(L10n.Settings.notificationsNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPendingSheet) {
            PendingNotificationListView(requests: pendingNotifications) {
                showPendingSheet = false
            }
            .environmentObject(notificationService)
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            Task {
                await notificationService.refreshAuthorizationStatus()
                await notificationService.getPendingNotifications()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await notificationService.refreshAuthorizationStatus() }
        }
        .onDisappear {
            notificationService.savePreferences()
        }
    }
    
    // MARK: - Permission Gate
    
    private var permissionSection: some View {
        Section {
            if notificationService.isAuthorized {
                Label(L10n.Settings.notificationsStatusEnabled, systemImage: "checkmark.seal.fill")
                    .foregroundColor(DesignSystem.Colors.success)
            } else {
                Label(L10n.Settings.notificationsStatusDisabled, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(DesignSystem.Colors.warning)
                
                if isPermissionDenied {
                    Button {
                        notificationService.openSystemNotificationSettings()
                    } label: {
                        Label(L10n.Settings.notificationsOpenSettingsButton, systemImage: "gear")
                    }
                } else {
                    Button {
                        Task { await requestAuthorization() }
                    } label: {
                        Label(L10n.Settings.notificationsEnableButton, systemImage: "bell.badge")
                    }
                    .disabled(isRequestingAuthorization)
                }
            }
        } header: {
            Text(L10n.Settings.notificationsPermissionSection)
        } footer: {
            if !notificationService.isAuthorized {
                Text(L10n.Settings.notificationsDisabledFooter)
            }
        }
    }
    
    // MARK: - Reminder Preferences
    
    @ViewBuilder
    private var reminderSections: some View {
        Section {
            Toggle(L10n.Settings.notificationsEventsToggle, isOn: eventReminderBinding)
            Toggle(L10n.Settings.notificationsMatchesToggle, isOn: matchReminderBinding)
            
            if notificationService.enableEventReminders {
                Stepper(
                    L10n.Settings.notificationsEventsStepper(notificationService.eventReminderMinutes),
                    value: eventMinutesBinding,
                    in: 5...120,
                    step: 5
                )
            }
            
            if notificationService.enableMatchReminders {
                Stepper(
                    L10n.Settings.notificationsMatchesStepper(notificationService.matchReminderMinutes),
                    value: matchMinutesBinding,
                    in: 5...60,
                    step: 5
                )
            }
        } header: {
            Text(L10n.Settings.notificationsEventsSection)
        }
        
        Section {
            Toggle(L10n.Settings.notificationsInventoryToggle, isOn: inventoryAlertsBinding)
            Toggle(L10n.Settings.notificationsTasksToggle, isOn: taskRemindersBinding)
            
            if notificationService.enableTaskReminders {
                Stepper(
                    L10n.Settings.notificationsTasksStepper(notificationService.taskReminderHours),
                    value: taskHoursBinding,
                    in: 1...72,
                    step: 1
                )
            }
        } header: {
            Text(L10n.Settings.notificationsTeamSection)
        } footer: {
            Text(L10n.Settings.notificationsTeamFooter)
        }
    }
    
    private var pendingNotificationsSection: some View {
        Section {
            Button {
                showPendingSheet = true
                Task { await notificationService.getPendingNotifications() }
            } label: {
                Label(L10n.Settings.notificationsPendingButton, systemImage: "list.bullet.rectangle")
            }
        } header: {
            Text(L10n.Settings.notificationsSystemSection)
        }
    }
    
    // MARK: - Bindings
    private var eventReminderBinding: Binding<Bool> {
        Binding {
            notificationService.enableEventReminders
        } set: { newValue in
            notificationService.enableEventReminders = newValue
            notificationService.savePreferences()
            if !newValue {
                Task { await notificationService.cancelAllForType(.events) }
            }
        }
    }
    
    private var matchReminderBinding: Binding<Bool> {
        Binding {
            notificationService.enableMatchReminders
        } set: { newValue in
            notificationService.enableMatchReminders = newValue
            notificationService.savePreferences()
            if !newValue {
                Task { await notificationService.cancelAllForType(.matches) }
            }
        }
    }
    
    private var inventoryAlertsBinding: Binding<Bool> {
        Binding {
            notificationService.enableInventoryAlerts
        } set: { newValue in
            notificationService.enableInventoryAlerts = newValue
            notificationService.savePreferences()
            if !newValue {
                Task { await notificationService.cancelAllForType(.inventory) }
            }
        }
    }
    
    private var taskRemindersBinding: Binding<Bool> {
        Binding {
            notificationService.enableTaskReminders
        } set: { newValue in
            notificationService.enableTaskReminders = newValue
            notificationService.savePreferences()
            if !newValue {
                Task { await notificationService.cancelAllForType(.tasks) }
            }
        }
    }
    
    private var eventMinutesBinding: Binding<Int> {
        Binding {
            notificationService.eventReminderMinutes
        } set: { newValue in
            notificationService.eventReminderMinutes = newValue
            notificationService.savePreferences()
        }
    }
    
    private var matchMinutesBinding: Binding<Int> {
        Binding {
            notificationService.matchReminderMinutes
        } set: { newValue in
            notificationService.matchReminderMinutes = newValue
            notificationService.savePreferences()
        }
    }
    
    private var taskHoursBinding: Binding<Int> {
        Binding {
            notificationService.taskReminderHours
        } set: { newValue in
            notificationService.taskReminderHours = newValue
            notificationService.savePreferences()
        }
    }
    
    private func requestAuthorization() async {
        isRequestingAuthorization = true
        await notificationService.requestAuthorization()
        if notificationService.isAuthorized {
            DesignSystem.Haptics.notify(.success)
        } else {
            DesignSystem.Haptics.notify(.warning)
        }
        isRequestingAuthorization = false
    }
}

// MARK: - Pending Notifications
private struct PendingNotificationListView: View {
    @EnvironmentObject private var notificationService: NotificationService
    let requests: [UNNotificationRequest]
    var onClose: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            List {
                if requests.isEmpty {
                    ContentUnavailableView {
                        Label(L10n.Settings.notificationsPendingEmptyTitle, systemImage: "bell.slash")
                    } description: {
                        Text(L10n.Settings.notificationsPendingEmptySubtitle)
                    }
                } else {
                    ForEach(requests, id: \.identifier) { request in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(request.content.title)
                                .font(.headline)
                            Text(request.content.body)
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            if let triggerDate = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ??
                                (request.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate() {
                                Text(dateFormatter.string(from: triggerDate))
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                notificationService.cancelNotification(withIdentifier: request.identifier)
                                Task { await notificationService.getPendingNotifications() }
                            } label: {
                                Label(L10n.Settings.notificationsCancelSingle, systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.Settings.notificationsPendingTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.General.actionClose) {
                        onClose()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.Settings.notificationsClearAll) {
                        notificationService.cancelAllNotifications()
                        Task { await notificationService.getPendingNotifications() }
                    }
                    .disabled(requests.isEmpty)
                }
            }
        }
    }
}
