//
//  NotificationSettingsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationService = NotificationService()
    @State private var eventReminders = true
    @State private var matchReminders = true
    @State private var inventoryAlerts = true
    @State private var taskReminders = true
    @State private var grantReminders = true
    
    var body: some View {
        NavigationView {
            List {
                Section("Event Notifications") {
                    Toggle("Event Reminders", isOn: $eventReminders)
                    Toggle("Match Reminders", isOn: $matchReminders)
                }
                
                Section("Team Notifications") {
                    Toggle("Inventory Alerts", isOn: $inventoryAlerts)
                    Toggle("Task Reminders", isOn: $taskReminders)
                    Toggle("Grant Deadlines", isOn: $grantReminders)
                }
                
                Section("Notification Settings") {
                    Button("Request Permission") {
                        Task {
                            await notificationService.requestAuthorization()
                        }
                    }
                    
                    if notificationService.isAuthorized {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Notifications Enabled")
                        }
                    }
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NotificationSettingsView()
}
