//
//  AvailabilityService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine

@MainActor
class AvailabilityService: ObservableObject {
    static let shared = AvailabilityService()
    
    @Published var availabilities: [Availability] = []
    @Published var conflicts: [ConflictInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func loadAvailabilities(for eventId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        // Load sample data for now
        availabilities = []
    }
    
    func respondToEvent(eventId: UUID, status: RSVPStatus, notes: String? = nil) async throws {
        // Implementation placeholder
    }
    
    func detectConflicts(for events: [Event]) -> [ConflictInfo] {
        var detectedConflicts: [ConflictInfo] = []
        
        for i in 0..<events.count {
            for j in (i+1)..<events.count {
                let event1 = events[i]
                let event2 = events[j]
                
                // Check for time overlap
                if event1.startDate < event2.endDate ?? event2.startDate && event2.startDate < event1.endDate ?? event1.startDate {
                    detectedConflicts.append(ConflictInfo(
                        eventId: event1.id,
                        conflictingEventId: event2.id,
                        eventTitle: event1.title,
                        conflictingEventTitle: event2.title,
                        conflictType: .timeOverlap,
                        severity: .critical
                    ))
                }
            }
        }
        
        return detectedConflicts
    }
    
    func getAttendanceRate(for userId: UUID) -> Double {
        let totalEvents = availabilities.count
        guard totalEvents > 0 else { return 0 }
        let attended = availabilities.filter { $0.status == .attending }.count
        return Double(attended) / Double(totalEvents) * 100
    }
}


