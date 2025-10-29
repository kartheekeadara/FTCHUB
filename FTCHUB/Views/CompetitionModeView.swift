//
//  CompetitionModeView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct CompetitionModeView: View {
    @State private var currentMatch: Int = 1
    @State private var nextMatchTime: Date = Date().addingTimeInterval(900)
    @State private var selectedTab: CompetitionTab = .schedule
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Match Status
                    CurrentMatchCard(matchNumber: currentMatch, nextMatchTime: nextMatchTime)
                        .padding(.horizontal)
                    
                    // Quick Access Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        QuickActionButton(icon: "calendar", title: "Schedule", color: .blue) {
                            selectedTab = .schedule
                        }
                        
                        QuickActionButton(icon: "checklist", title: "Pre-Match", color: .green) {
                            selectedTab = .preMatch
                        }
                        
                        QuickActionButton(icon: "person.3.fill", title: "Alliance", color: .purple) {
                            selectedTab = .alliance
                        }
                        
                        QuickActionButton(icon: "phone.fill", title: "Contacts", color: .red) {
                            selectedTab = .contacts
                        }
                    }
                    .padding(.horizontal)
                    
                    // Tab Content
                    switch selectedTab {
                    case .schedule:
                        MatchScheduleSection()
                    case .preMatch:
                        PreMatchChecklistSection()
                    case .alliance:
                        AllianceInfoSection()
                    case .contacts:
                        EmergencyContactsSection()
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Competition Mode")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Current Match Card
struct CurrentMatchCard: View {
    let matchNumber: Int
    let nextMatchTime: Date
    
    var timeUntilMatch: String {
        let interval = nextMatchTime.timeIntervalSinceNow
        if interval < 0 {
            return "Match in progress"
        }
        let minutes = Int(interval / 60)
        return "\(minutes) min"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Match")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("#\(matchNumber)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Time Until")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timeUntilMatch)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                InfoPill(icon: "clock", text: nextMatchTime.formatted(date: .omitted, time: .shortened))
                InfoPill(icon: "location", text: "Field 1")
                InfoPill(icon: "person.2", text: "Red Alliance")
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
    }
}

// MARK: - Info Pill
struct InfoPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Match Schedule Section
struct MatchScheduleSection: View {
    let matches = [
        CompetitionMatch(number: 1, time: Date().addingTimeInterval(900), field: "Field 1", alliance: "Red", opponents: ["1234", "5678"]),
        CompetitionMatch(number: 2, time: Date().addingTimeInterval(2700), field: "Field 2", alliance: "Blue", opponents: ["9012", "3456"]),
        CompetitionMatch(number: 3, time: Date().addingTimeInterval(4500), field: "Field 1", alliance: "Red", opponents: ["7890", "2345"])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Matches")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(matches) { match in
                MatchRow(match: match)
                    .padding(.horizontal)
            }
        }
    }
}

struct MatchRow: View {
    let match: CompetitionMatch
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Match #\(match.number)")
                    .font(.headline)
                Text(match.time.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(match.field)
                    .font(.caption)
                Text(match.alliance)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(match.alliance == "Red" ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(match.alliance == "Red" ? .red : .blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Pre-Match Checklist Section
struct PreMatchChecklistSection: View {
    @State private var checklistItems: [ChecklistItem] = [
        ChecklistItem(title: "Robot inspection passed", isCompleted: true),
        ChecklistItem(title: "Battery fully charged", isCompleted: true),
        ChecklistItem(title: "Controllers paired", isCompleted: false),
        ChecklistItem(title: "Autonomous tested", isCompleted: false),
        ChecklistItem(title: "Alliance strategy discussed", isCompleted: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pre-Match Checklist")
                    .font(.headline)
                Spacer()
                Text("\(checklistItems.filter(\.isCompleted).count)/\(checklistItems.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ForEach($checklistItems) { $item in
                ChecklistRow(item: $item)
                    .padding(.horizontal)
            }
        }
    }
}

struct ChecklistRow: View {
    @Binding var item: ChecklistItem
    
    var body: some View {
        Button(action: {
            item.isCompleted.toggle()
        }) {
            HStack {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .font(.title3)
                
                Text(item.title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .strikethrough(item.isCompleted)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Alliance Info Section
struct AllianceInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alliance Partners")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                AlliancePartnerCard(teamNumber: "1234", role: "Captain", strengths: ["Auto", "Endgame"])
                AlliancePartnerCard(teamNumber: "5678", role: "Partner", strengths: ["TeleOp", "Defense"])
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Strategy Notes")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text("• Focus on autonomous points\n• Captain handles specimen placement\n• Partner plays defense in TeleOp")
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }
}

struct AlliancePartnerCard: View {
    let teamNumber: String
    let role: String
    let strengths: [String]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Team \(teamNumber)")
                    .font(.headline)
                Text(role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(strengths, id: \.self) { strength in
                    Text(strength)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Emergency Contacts Section
struct EmergencyContactsSection: View {
    let contacts = [
        EmergencyContact(name: "Head Coach", phone: "(555) 123-4567", role: "Primary"),
        EmergencyContact(name: "Event Coordinator", phone: "(555) 987-6543", role: "Event Staff"),
        EmergencyContact(name: "Technical Advisor", phone: "(555) 456-7890", role: "Support")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Contacts")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(contacts) { contact in
                ContactRow(contact: contact)
                    .padding(.horizontal)
            }
        }
    }
}

struct ContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                Text(contact.role)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                if let url = URL(string: "tel://\(contact.phone.filter { $0.isNumber })") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text(contact.phone)
                        .font(.subheadline)
                    Image(systemName: "phone.fill")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types
enum CompetitionTab {
    case schedule, preMatch, alliance, contacts
}

struct CompetitionMatch: Identifiable {
    let id = UUID()
    let number: Int
    let time: Date
    let field: String
    let alliance: String
    let opponents: [String]
}

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    var isCompleted: Bool
}

struct EmergencyContact: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let role: String
}

#Preview {
    CompetitionModeView()
}

