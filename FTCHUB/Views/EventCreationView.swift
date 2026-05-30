//
//  EventCreationView.swift
//  FTCHUB
//
//  Direct event creation modal (like CreateTaskView)
//

import SwiftUI

struct EventCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var calendarService: SimplifiedCalendarService
    @EnvironmentObject var teamService: TeamService
    @EnvironmentObject var notificationService: NotificationService
    
    @State private var draft: EventDraft
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    init() {
        let calendar = Calendar.current
        let defaultStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        let defaultEnd = defaultStart.addingTimeInterval(3600) // 1 hour later
        _draft = State(initialValue: EventDraft(
            startDate: defaultStart,
            endDate: defaultEnd,
            syncToCalendar: false,
            scheduleReminder: false
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Event Title", text: $draft.title)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Event Type", selection: $draft.eventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Picker("Status", selection: $draft.status) {
                        ForEach(EventStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    TextField("Location (optional)", text: $draft.location)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Details")
                }
                
                Section {
                    DatePicker(
                        "Start",
                        selection: $draft.startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    DatePicker(
                        "End",
                        selection: $draft.endDate,
                        in: draft.startDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text("Timing")
                }
                
                Section {
                    TextEditor(text: $draft.notes)
                        .frame(minHeight: 80)
                } header: {
                    Text("Description")
                }
                
                Section {
                    if calendarService.isConnected {
                        Toggle("Sync to Calendar", isOn: $draft.syncToCalendar)
                    } else {
                        Label("Calendar sync unavailable", systemImage: "exclamationmark.triangle")
                            .foregroundColor(DesignSystem.Colors.warning)
                            .font(.caption)
                    }
                    
                    if notificationService.isAuthorized {
                        Toggle("Schedule Reminder", isOn: $draft.scheduleReminder)
                        if draft.scheduleReminder {
                            Stepper(
                                "\(draft.reminderMinutesBefore) minutes before",
                                value: $draft.reminderMinutesBefore,
                                in: 5...120,
                                step: 5
                            )
                        }
                    } else {
                        Label("Notifications unavailable", systemImage: "bell.slash.fill")
                            .foregroundColor(DesignSystem.Colors.warning)
                            .font(.caption)
                    }
                } header: {
                    Text("Options")
                }
            }
            .navigationTitle("Add New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await createEvent()
                        }
                    }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
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
        .onAppear {
            if let teamId = teamService.currentTeam?.id {
                calendarService.updateTeamContext(teamId: teamId)
            }
        }
    }
    
    private func createEvent() async {
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard teamService.currentTeam != nil else {
            await MainActor.run {
                errorMessage = "You must be part of a team to create events"
            }
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        do {
            let savedEvent = try await calendarService.createTeamEvent(from: draft)
            if draft.syncToCalendar {
                try? await calendarService.syncEventToDeviceCalendar(savedEvent)
            }
            if draft.scheduleReminder {
                notificationService.rescheduleEventReminder(for: savedEvent, minutesBefore: draft.reminderMinutesBefore)
            }
            await MainActor.run {
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
        
        isCreating = false
    }
}
