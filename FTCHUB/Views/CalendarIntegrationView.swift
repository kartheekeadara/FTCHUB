//
//  CalendarIntegrationView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct CalendarIntegrationView: View {
    @StateObject private var calendarService = GoogleCalendarService.shared
    @State private var showingConnectionSheet = false
    
    var body: some View {
        List {
            Section {
                ConnectionStatusRow(calendarService: calendarService)
            }
            
            if calendarService.isConnected {
                Section("Calendar Events") {
                    if calendarService.calendarEvents.isEmpty {
                        Text("No events found")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(calendarService.calendarEvents) { event in
                            CalendarEventRow(event: event)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await calendarService.syncCalendar()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Now")
                        }
                    }
                    .disabled(calendarService.syncStatus == .syncing)
                    
                    Button(role: .destructive, action: {
                        calendarService.disconnectGoogleCalendar()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Disconnect")
                        }
                    }
                }
            }
        }
        .navigationTitle("Calendar Integration")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(calendarService.errorMessage != nil)) {
            Button("OK") {
                calendarService.errorMessage = nil
            }
        } message: {
            Text(calendarService.errorMessage ?? "")
        }
    }
}

struct ConnectionStatusRow: View {
    @ObservedObject var calendarService: GoogleCalendarService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Google Calendar")
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(calendarService.isConnected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(calendarService.isConnected ? "Connected" : "Not Connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if calendarService.isLoading {
                ProgressView()
            } else if !calendarService.isConnected {
                Button("Connect") {
                    Task {
                        await calendarService.connectGoogleCalendar()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct CalendarEventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let location = event.location {
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        CalendarIntegrationView()
    }
}
