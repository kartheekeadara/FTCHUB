//
//  SimplifiedCalendarService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import EventKit

@MainActor
class SimplifiedCalendarService: ObservableObject {
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var events: [CalendarEvent] = []
    
    private let eventStore = EKEventStore()
    
    init() {
        // Only check calendar access if not in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            checkCalendarAccess()
        } else {
            // Set mock values for previews
            self.isConnected = false
            self.isLoading = false
            self.errorMessage = nil
            self.events = []
        }
    }
    
    // MARK: - Calendar Access
    func requestCalendarAccess() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            isConnected = granted
            
            if granted {
                await loadCalendarEvents()
            }
        } catch {
            errorMessage = error.localizedDescription
            isConnected = false
        }
    }
    
    private func checkCalendarAccess() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            isConnected = true
            Task {
                await loadCalendarEvents()
            }
        case .denied, .restricted:
            isConnected = false
        case .notDetermined:
            isConnected = false
        @unknown default:
            isConnected = false
        }
    }
    
    // MARK: - Calendar Events
    func loadCalendarEvents() async {
        guard isConnected else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let startDate = Calendar.current.startOfDay(for: Date())
            let endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
            let ekEvents = eventStore.events(matching: predicate)
            
            let calendarEvents = ekEvents.compactMap { event in
                CalendarEvent(from: event)
            }
            
            events = calendarEvents
        } catch {
            errorMessage = error.localizedDescription
        }
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
        
        // Update local event with calendar ID
        var updatedEvent = event
        updatedEvent.googleCalendarId = ekEvent.eventIdentifier
        try await syncEventToDatabase(updatedEvent)
    }
    
    func updateCalendarEvent(_ event: CalendarEvent) async throws {
        guard isConnected, let eventId = event.googleCalendarId else {
            throw CalendarError.notConnected
        }
        
        if let ekEvent = eventStore.event(withIdentifier: eventId) {
            ekEvent.title = event.title
            ekEvent.notes = event.description
            ekEvent.startDate = event.startDate
            ekEvent.endDate = event.endDate
            ekEvent.location = event.location
            
            try eventStore.save(ekEvent, span: .thisEvent)
            try await syncEventToDatabase(event)
        }
    }
    
    func deleteCalendarEvent(_ event: CalendarEvent) async throws {
        guard isConnected, let eventId = event.googleCalendarId else {
            throw CalendarError.notConnected
        }
        
        if let ekEvent = eventStore.event(withIdentifier: eventId) {
            try eventStore.remove(ekEvent, span: .thisEvent)
            try await removeEventFromDatabase(event)
        }
    }
    
    // MARK: - Database Sync
    private func syncEventToDatabase(_ event: CalendarEvent) async throws {
        // This would sync with your Supabase database
        // For now, we'll just store locally
        print("Syncing event to database: \(event.title)")
    }
    
    private func removeEventFromDatabase(_ event: CalendarEvent) async throws {
        // This would remove from your Supabase database
        print("Removing event from database: \(event.title)")
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
    var googleCalendarId: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, location
        case teamId = "team_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case eventType = "event_type"
        case status
        case googleCalendarId = "google_calendar_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from ekEvent: EKEvent) {
        self.id = UUID()
        self.teamId = UUID() // This should be set from the current team
        self.title = ekEvent.title
        self.description = ekEvent.notes
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.location = ekEvent.location
        self.eventType = .meeting // Default, should be determined from context
        self.status = .scheduled
        self.googleCalendarId = ekEvent.eventIdentifier
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(id: UUID = UUID(), teamId: UUID, title: String, description: String?, startDate: Date, endDate: Date, location: String?, eventType: EventType, status: EventStatus = .scheduled, googleCalendarId: String? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.teamId = teamId
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.eventType = eventType
        self.status = status
        self.googleCalendarId = googleCalendarId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
