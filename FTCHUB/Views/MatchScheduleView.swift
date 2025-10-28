//
//  MatchScheduleView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct MatchScheduleView: View {
    @State private var matches: [Match] = []
    @State private var showingImportSheet = false
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date Picker
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    .background(DesignSystem.Colors.cardBackground)
                
                // Matches List
                if matches.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Spacer()
                        
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(DesignSystem.Gradients.primary)
                        
                        Text("No Matches Scheduled")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Import a match schedule to get started")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Import Schedule") {
                            showingImportSheet = true
                        }
                        .primaryButtonStyle()
                        
                        Spacer()
                    }
                    .padding()
                } else {
                    List(matches) { match in
                        MatchRowView(match: match)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Match Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") {
                        showingImportSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportScheduleView { importedMatches in
                matches.append(contentsOf: importedMatches)
            }
        }
    }
}

// Using the existing Match model from Models/Match.swift

struct MatchRowView: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("Match \(match.matchNumber)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(match.scheduledTime, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(match.allianceColor.displayName) Alliance")
                        .font(.caption)
                        .foregroundColor(match.allianceColor == .red ? .red : .blue)
                    
                    if let partner1 = match.alliancePartner1 {
                        Text("Team \(partner1)")
                            .font(.subheadline)
                    }
                    if let partner2 = match.alliancePartner2 {
                        Text("Team \(partner2)")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Opponents")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let opponent1 = match.opponent1 {
                        Text("Team \(opponent1)")
                            .font(.subheadline)
                    }
                    if let opponent2 = match.opponent2 {
                        Text("Team \(opponent2)")
                            .font(.subheadline)
                    }
                    if let opponent3 = match.opponent3 {
                        Text("Team \(opponent3)")
                            .font(.subheadline)
                    }
                }
            }
            
            HStack {
                Text("Status: \(match.status.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let location = match.location {
                    Text("Field: \(location)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.cardBackground)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

struct ImportScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    let onImport: ([Match]) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignSystem.Gradients.primary)
                
                Text("Import Match Schedule")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Import a CSV file with match schedule data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Select File") {
                    // TODO: Implement file selection
                    // For now, create sample data
                    let sampleMatches = [
                        Match(
                            id: UUID(),
                            teamId: UUID(),
                            matchNumber: "1",
                            scheduledTime: Date(),
                            allianceColor: .red,
                            alliancePartner1: 12345,
                            alliancePartner2: 54321,
                            opponent1: 99999,
                            opponent2: 11111,
                            opponent3: nil,
                            status: .scheduled,
                            ourScore: nil,
                            opponentScore: nil,
                            location: "Field 1",
                            createdAt: Date(),
                            updatedAt: Date()
                        ),
                        Match(
                            id: UUID(),
                            teamId: UUID(),
                            matchNumber: "2",
                            scheduledTime: Date().addingTimeInterval(3600),
                            allianceColor: .blue,
                            alliancePartner1: 22222,
                            alliancePartner2: 33333,
                            opponent1: 44444,
                            opponent2: 55555,
                            opponent3: nil,
                            status: .scheduled,
                            ourScore: nil,
                            opponentScore: nil,
                            location: "Field 2",
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                    ]
                    onImport(sampleMatches)
                    dismiss()
                }
                .primaryButtonStyle()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MatchScheduleView()
}