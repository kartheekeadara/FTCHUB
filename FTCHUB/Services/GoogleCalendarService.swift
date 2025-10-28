//
//  GoogleCalendarService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine
import GoogleSignIn
import GoogleAPIClientForREST_Calendar

@MainActor
class GoogleCalendarService: ObservableObject {
    static let shared = GoogleCalendarService()
    
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var calendarEvents: [CalendarEvent] = []
    @Published var syncStatus: CalendarSyncStatus = .idle
    
    private let calendarService = GTLRCalendarService()
    private var lastSyncDate: Date?
    
    private init() {
        // Initialize with preview check
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            isConnected = false
            isLoading = false
        }
    }
    
    // MARK: - Authentication
    func connectGoogleCalendar() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Request calendar scope
            let additionalScopes = [kGTLRAuthScopeCalendar]
            
            guard let rootViewController = await getRootViewController() else {
                throw CalendarError.noViewController
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: additionalScopes
            )
            
            // Set up calendar service with user authorization
            calendarService.authorizer = result.user.fetcherAuthorizer
            isConnected = true
            
            // Start initial sync
            await syncCalendar()
            
        } catch {
            errorMessage = error.localizedDescription
            isConnected = false
        }
        
        isLoading = false
    }
    
    func disconnectGoogleCalendar() {
        GIDSignIn.sharedInstance.signOut()
        isConnected = false
        calendarEvents = []
        lastSyncDate = nil
    }
    
    // MARK: - Calendar Sync
    func syncCalendar() async {
        guard isConnected else { return }
        
        syncStatus = .syncing
        errorMessage = nil
        
        do {
            // Fetch events from Google Calendar
            let query = GTLRCalendarQuery_EventsList.query(withCalendarId: "primary")
            query.timeMin = GTLRDateTime(date: Date().addingTimeInterval(-30 * 24 * 60 * 60)) // Last 30 days
            query.timeMax = GTLRDateTime(date: Date().addingTimeInterval(90 * 24 * 60 * 60)) // Next 90 days
            query.singleEvents = true
            query.orderBy = kGTLRCalendarOrderByStartTime
            
            let result = try await calendarService.executeQuery(query)
            
            if let eventList = result as? GTLRCalendar_Events,
               let items = eventList.items {
                
                // Convert Google Calendar events to our model
                calendarEvents = items.compactMap { convertToCalendarEvent($0) }
                lastSyncDate = Date()
                syncStatus = .success
            }
            
        } catch {
            errorMessage = error.localizedDescription
            syncStatus = .failed
        }
    }
    
    // MARK: - Event Management
    func createCalendarEvent(from event: Event) async throws {
        guard isConnected else { throw CalendarError.notConnected }
        
        let calendarEvent = GTLRCalendar_Event()
        calendarEvent.summary = event.title
        calendarEvent.descriptionProperty = event.eventDescription
        calendarEvent.location = event.location
        
        // Set start time
        let startDateTime = GTLRDateTime(date: event.startDate)
        let start = GTLRCalendar_EventDateTime()
        start.dateTime = startDateTime
        calendarEvent.start = start
        
        // Set end time
        let endDate = event.endDate ?? event.startDate.addingTimeInterval(3600) // Default 1 hour
        let endDateTime = GTLRDateTime(date: endDate)
        let end = GTLRCalendar_EventDateTime()
        end.dateTime = endDateTime
        calendarEvent.end = end
        
        // Add attendees if available
        // This would require team member email addresses
        
        // Create event on Google Calendar
        let query = GTLRCalendarQuery_EventsInsert.query(
            withObject: calendarEvent,
            calendarId: "primary"
        )
        
        _ = try await calendarService.executeQuery(query)
        
        // Refresh calendar
        await syncCalendar()
    }
    
    func updateCalendarEvent(event: Event, googleEventId: String) async throws {
        guard isConnected else { throw CalendarError.notConnected }
        
        // Fetch existing event
        let getQuery = GTLRCalendarQuery_EventsGet.query(
            withCalendarId: "primary",
            eventId: googleEventId
        )
        
        guard let existingEvent = try await calendarService.executeQuery(getQuery) as? GTLRCalendar_Event else {
            throw CalendarError.eventNotFound
        }
        
        // Update event properties
        existingEvent.summary = event.title
        existingEvent.descriptionProperty = event.eventDescription
        existingEvent.location = event.location
        
        let startDateTime = GTLRDateTime(date: event.startDate)
        let start = GTLRCalendar_EventDateTime()
        start.dateTime = startDateTime
        existingEvent.start = start
        
        let endDate = event.endDate ?? event.startDate.addingTimeInterval(3600)
        let endDateTime = GTLRDateTime(date: endDate)
        let end = GTLRCalendar_EventDateTime()
        end.dateTime = endDateTime
        existingEvent.end = end
        
        // Update event on Google Calendar
        let updateQuery = GTLRCalendarQuery_EventsUpdate.query(
            withObject: existingEvent,
            calendarId: "primary",
            eventId: googleEventId
        )
        
        _ = try await calendarService.executeQuery(updateQuery)
        
        // Refresh calendar
        await syncCalendar()
    }
    
    func deleteCalendarEvent(googleEventId: String) async throws {
        guard isConnected else { throw CalendarError.notConnected }
        
        let deleteQuery = GTLRCalendarQuery_EventsDelete.query(
            withCalendarId: "primary",
            eventId: googleEventId
        )
        
        _ = try await calendarService.executeQuery(deleteQuery)
        
        // Refresh calendar
        await syncCalendar()
    }
    
    // MARK: - Helper Methods
    private func convertToCalendarEvent(_ googleEvent: GTLRCalendar_Event) -> CalendarEvent? {
        guard let identifier = googleEvent.identifier,
              let summary = googleEvent.summary,
              let startDateTime = googleEvent.start?.dateTime?.date else {
            return nil
        }
        
        let endDate = googleEvent.end?.dateTime?.date ?? startDateTime.addingTimeInterval(3600)
        
        return CalendarEvent(
            id: identifier,
            title: summary,
            description: googleEvent.descriptionProperty,
            startDate: startDateTime,
            endDate: endDate,
            location: googleEvent.location,
            isAllDay: googleEvent.start?.date != nil,
            attendees: googleEvent.attendees?.compactMap { $0.email } ?? []
        )
    }
    
    private func getRootViewController() async -> UIViewController? {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
}

// MARK: - Supporting Types
enum CalendarError: LocalizedError {
    case notConnected
    case noViewController
    case eventNotFound
    case authenticationFailed
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Google Calendar is not connected"
        case .noViewController:
            return "Unable to find view controller for authentication"
        case .eventNotFound:
            return "Calendar event not found"
        case .authenticationFailed:
            return "Failed to authenticate with Google"
        case .syncFailed:
            return "Failed to sync with Google Calendar"
        }
    }
}

enum CalendarSyncStatus {
    case idle
    case syncing
    case success
    case failed
}

struct CalendarEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let startDate: Date
    let endDate: Date
    let location: String?
    let isAllDay: Bool
    let attendees: [String]
}
