//
//  SafetyComplianceView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct SafetyComplianceView: View {
    @StateObject private var safetyService = SafetyService.shared
    @State private var selectedTab: SafetyTab = .overview
    @State private var showingAddConsent = false
    @State private var showingAddContact = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Safety Tab", selection: $selectedTab) {
                    Text("Overview").tag(SafetyTab.overview)
                    Text("Consent").tag(SafetyTab.consent)
                    Text("Emergency").tag(SafetyTab.emergency)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    SafetyOverviewView()
                        .environmentObject(safetyService)
                        .tag(SafetyTab.overview)
                    
                    ConsentManagementView()
                        .environmentObject(safetyService)
                        .tag(SafetyTab.consent)
                    
                    EmergencyContactsView()
                        .environmentObject(safetyService)
                        .tag(SafetyTab.emergency)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Safety & Compliance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingAddConsent = true }) {
                            Label("Add Consent", systemImage: "doc.text.badge.plus")
                        }
                        Button(action: { showingAddContact = true }) {
                            Label("Add Emergency Contact", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
}

enum SafetyTab {
    case overview, consent, emergency
}

// MARK: - Safety Overview
struct SafetyOverviewView: View {
    @EnvironmentObject var safetyService: SafetyService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Compliance Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Compliance Status")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        StatusCard(
                            title: "Consent Forms",
                            value: "\(safetyService.consentRecords.filter(\.isValid).count)",
                            total: ConsentRecord.ConsentType.allCases.count,
                            icon: "doc.text.fill",
                            color: .blue
                        )
                        
                        StatusCard(
                            title: "Emergency Contacts",
                            value: "\(safetyService.emergencyContacts.count)",
                            total: 2,
                            icon: "person.fill",
                            color: .green
                        )
                    }
                }
                .padding()
                
                // Required Consents
                VStack(alignment: .leading, spacing: 12) {
                    Text("Required Consents")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(ConsentRecord.ConsentType.allCases, id: \.self) { type in
                        ConsentRequirementRow(
                            consentType: type,
                            hasConsent: safetyService.consentRecords.contains { $0.consentType == type && $0.isValid }
                        )
                        .padding(.horizontal)
                    }
                }
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: ConsentManagementView().environmentObject(safetyService)) {
                        ActionCard(
                            title: "Manage Consent Forms",
                            icon: "doc.text",
                            color: .blue
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    
                    NavigationLink(destination: EmergencyContactsView().environmentObject(safetyService)) {
                        ActionCard(
                            title: "Emergency Contacts",
                            icon: "phone.fill",
                            color: .red
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Supporting Views
struct StatusCard: View {
    let title: String
    let value: String
    let total: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("of \(total)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ConsentRequirementRow: View {
    let consentType: ConsentRecord.ConsentType
    let hasConsent: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: hasConsent ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(hasConsent ? .green : .red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(consentType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(consentType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    SafetyComplianceView()
}

