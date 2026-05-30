//
//  AvailabilityDashboardView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct AvailabilityDashboardView: View {
    @StateObject private var availabilityService = AvailabilityService.shared
    @EnvironmentObject var teamService: TeamService
    
    var upcomingEvents: [Event] {
        teamService.events.filter { $0.startDate > Date() }.sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Conflicts Alert
                    if !availabilityService.conflicts.isEmpty {
                        ConflictAlertCard(conflicts: availabilityService.conflicts)
                            .padding(.horizontal)
                    }
                    
                    // Upcoming Events with RSVP
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Events")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if upcomingEvents.isEmpty {
                            Text("No upcoming events")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(upcomingEvents) { event in
                                EventRSVPCard(event: event)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Availability")
            .onAppear {
                let conflicts = availabilityService.detectConflicts(for: teamService.events)
                availabilityService.conflicts = conflicts
            }
        }
    }
}

struct ConflictAlertCard: View {
    let conflicts: [ConflictInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Schedule Conflicts Detected")
                    .font(.headline)
            }
            
            Text("\(conflicts.count) conflict(s) found in your schedule")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(conflicts.prefix(3)) { conflict in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(conflict.eventTitle) conflicts with \(conflict.conflictingEventTitle)")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EventRSVPCard: View {
    let event: Event
    @State private var selectedStatus: RSVPStatus = .pending
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                    Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: event.eventType.icon)
                    .foregroundColor(Color.fromString(event.eventType.color))
            }
            
            HStack(spacing: 8) {
                ForEach([RSVPStatus.attending, .maybe, .declined], id: \.self) { status in
                    Button(action: { selectedStatus = status }) {
                        HStack {
                            Image(systemName: status.icon)
                            Text(status.displayName)
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedStatus == status ? Color.fromString(status.color).opacity(0.3) : Color(.systemGray6))
                        .foregroundColor(selectedStatus == status ? Color.fromString(status.color) : .secondary)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    AvailabilityDashboardView()
        .environmentObject(TeamService())
}


