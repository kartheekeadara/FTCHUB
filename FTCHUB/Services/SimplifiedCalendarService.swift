//
//  SimplifiedCalendarService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import EventKit
import Supabase
import PostgREST

@MainActor
class SimplifiedCalendarService: ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var events: [CalendarEvent] = []
    @Published var teamEvents: [Event] = []
    @Published private(set) var activeTeamId: UUID?
    
    private let eventStore = EKEventStore()
    private let supabase = SupabaseService.shared.client
    
    init() {
        // Calendar sync disabled - permission removed from Info.plist
        // Set default values - calendar sync is no longer available
        self.isConnected = false
        self.isLoading = false
        self.errorMessage = nil
        self.events = []
    }
    
    // MARK: - Calendar Access (Disabled)
    func requestCalendarAccess() async {
        // Calendar sync disabled - permission removed from Info.plist
        isConnected = false
        errorMessage = "Calendar sync is no longer available."
    }
    
    private func checkCalendarAccess() {
        // Calendar sync disabled - always set to false
        isConnected = false
    }
    
    func updateTeamContext(teamId: UUID?) {
        guard activeTeamId != teamId else { return }
        activeTeamId = teamId
        if teamId == nil {
            teamEvents = []
        } else {
            Task { await loadTeamEvents() }
        }
    }
    
    // MARK: - Calendar Events
    func loadCalendarEvents() async {
        guard isConnected else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let startDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let ekEvents = eventStore.events(matching: predicate)
        
        let calendarEvents = ekEvents.compactMap { event in
            CalendarEvent(from: event)
        }
        
        events = calendarEvents
    }
    
    func createCalendarEvent(_ event: CalendarEvent) async throws {
        guard isConnected else { throw CalendarError.notConnected }
        
        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = event.title
        ekEvent.notes = event.description
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.location = event.location
        
        if let calendar = eventStore.defaultCalendarForNewEvents {
            ekEvent.calendar = calendar
        }
        
        try eventStore.save(ekEvent, span: .thisEvent)
        
        // Update local event
        try await syncEventToDatabase(event)
    }
    
    func updateCalendarEvent(_ event: CalendarEvent) async throws {
        guard isConnected else {
            throw CalendarError.notConnected
        }
        
        // Note: Calendar sync is disabled, this method is no longer functional
        throw CalendarError.notConnected
    }
    
    func deleteCalendarEvent(_ event: CalendarEvent) async throws {
        guard isConnected else {
            throw CalendarError.notConnected
        }
        
        // Note: Calendar sync is disabled, this method is no longer functional
        throw CalendarError.notConnected
    }
    
    // MARK: - Database Sync
    private func syncEventToDatabase(_ event: CalendarEvent) async throws {
        // This would sync with your Supabase database
        // For now, we'll just store locally
        DebugLog.log("Syncing event to database: \(event.title)")
    }
    
    private func removeEventFromDatabase(_ event: CalendarEvent) async throws {
        // This would remove from your Supabase database
        DebugLog.log("Removing event from database: \(event.title)")
    }
}

// MARK: - Team Event Management
extension SimplifiedCalendarService {
    func loadTeamEvents() async {
        guard let teamId = activeTeamId else {
            teamEvents = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let events: [Event] = try await supabase
                .from("events")
                .select()
                .eq("team_id", value: teamId)
                .order("start_date", ascending: true)
                .execute()
                .value
            
            teamEvents = events
        } catch {
            errorMessage = error.localizedDescription
            TelemetryService.shared.logError(error, context: ["action": "load_team_events"])
        }
    }
    
    func createTeamEvent(from draft: EventDraft) async throws -> Event {
        guard let teamId = activeTeamId else {
            throw CalendarError.syncFailed
        }
        
        let now = Date()
        let newEvent = Event(
            id: UUID(),
            teamId: teamId,
            title: draft.title,
            description: draft.notes,
            startDate: draft.startDate,
            endDate: draft.endDate,
            location: draft.location,
            eventType: draft.eventType,
            status: draft.status,
            createdAt: now,
            updatedAt: now
        )
        
        do {
            let inserted: [Event] = try await supabase
                .from("events")
                .insert(newEvent, returning: .representation)
                .execute()
                .value
            
            guard let created = inserted.first else {
                throw CalendarError.syncFailed
            }
            
            teamEvents.append(created)
            teamEvents.sort { $0.startDate < $1.startDate }
            return created
        } catch {
            TelemetryService.shared.logError(error, context: ["action": "create_team_event"])
            throw error
        }
    }
    
    func updateTeamEvent(_ event: Event, with draft: EventDraft) async throws -> Event {
        let updatedEvent = Event(
            id: event.id,
            teamId: event.teamId,
            title: draft.title,
            description: draft.notes,
            startDate: draft.startDate,
            endDate: draft.endDate,
            location: draft.location,
            eventType: draft.eventType,
            status: draft.status,
            createdAt: event.createdAt,
            updatedAt: Date()
        )
        
        do {
            let resultArray: [Event] = try await supabase
                .from("events")
                .update(updatedEvent, returning: .representation)
                .eq("id", value: event.id)
                .execute()
                .value
            
            guard let result = resultArray.first else {
                throw CalendarError.syncFailed
            }
            
            if let index = teamEvents.firstIndex(where: { $0.id == result.id }) {
                teamEvents[index] = result
            } else {
                teamEvents.append(result)
            }
            teamEvents.sort { $0.startDate < $1.startDate }
            return result
        } catch {
            TelemetryService.shared.logError(error, context: ["action": "update_team_event"])
            throw error
        }
    }
    
    func deleteTeamEvent(_ event: Event) async throws {
        do {
            try await supabase
                .from("events")
                .delete()
                .eq("id", value: event.id)
                .execute()
            
            teamEvents.removeAll { $0.id == event.id }
        } catch {
            TelemetryService.shared.logError(error, context: ["action": "delete_team_event"])
            throw error
        }
    }
    
    func syncEventToDeviceCalendar(_ event: Event) async throws {
        guard isConnected else { throw CalendarError.notConnected }
        let calendarEvent = CalendarEvent(event: event)
        try await createCalendarEvent(calendarEvent)
    }
}

// MARK: - Calendar Event Model
struct CalendarEvent: Identifiable, Codable {
    let id: UUID
    let teamId: UUID
    let title: String
    let description: String?
    let startDate: Date
    let endDate: Date
    let location: String?
    let eventType: EventType
    let status: EventStatus
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location
        case teamId = "team_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case eventType = "event_type"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from ekEvent: EKEvent) {
        self.id = UUID()
        self.teamId = UUID()
        self.title = ekEvent.title
        self.description = ekEvent.notes
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.location = ekEvent.location
        self.eventType = .meeting // Default, should be determined from context
        self.status = .scheduled
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(id: UUID = UUID(), teamId: UUID, title: String, description: String?, startDate: Date, endDate: Date, location: String?, eventType: EventType, status: EventStatus = .scheduled, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.teamId = teamId
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.eventType = eventType
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(event: Event) {
        self.id = event.id
        self.teamId = event.teamId
        self.title = event.title
        self.description = event.description
        self.startDate = event.startDate
        self.endDate = event.endDate ?? event.startDate.addingTimeInterval(3600)
        self.location = event.location
        self.eventType = event.eventType
        self.status = event.status
        self.createdAt = event.createdAt
        self.updatedAt = event.updatedAt
    }
}

struct EventDraft: Identifiable, Equatable {
    let id: UUID
    var title: String
    var notes: String
    var startDate: Date
    var endDate: Date
    var location: String
    var eventType: EventType
    var status: EventStatus
    var syncToCalendar: Bool
    var scheduleReminder: Bool
    var reminderMinutesBefore: Int
    
    init(
        id: UUID = UUID(),
        title: String = "",
        notes: String = "",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(3600),
        location: String = "",
        eventType: EventType = .meeting,
        status: EventStatus = .scheduled,
        syncToCalendar: Bool = false,
        scheduleReminder: Bool = false,
        reminderMinutesBefore: Int = 15
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.eventType = eventType
        self.status = status
        self.syncToCalendar = syncToCalendar
        self.scheduleReminder = scheduleReminder
        self.reminderMinutesBefore = reminderMinutesBefore
    }
    
    init(event: Event) {
        self.id = event.id
        self.title = event.title
        self.notes = event.description ?? ""
        self.startDate = event.startDate
        self.endDate = event.endDate ?? event.startDate.addingTimeInterval(3600)
        self.location = event.location ?? ""
        self.eventType = event.eventType
        self.status = event.status
        self.syncToCalendar = false
        self.scheduleReminder = false
        self.reminderMinutesBefore = 15
    }
}

// MARK: - Calendar Errors
enum CalendarError: LocalizedError {
    case notConnected
    case noViewController
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to calendar"
        case .noViewController:
            return "No view controller available for authentication"
        case .syncFailed:
            return "Failed to sync with calendar"
        }
    }
}
