//
//  ConsentManagementView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import SwiftUI

struct ConsentManagementView: View {
    @EnvironmentObject var safetyService: SafetyService
    @State private var selectedConsent: ConsentRecord? = nil
    
    var body: some View {
        List {
            ForEach(ConsentRecord.ConsentType.allCases, id: \.self) { type in
                Section(header: Text(type.displayName)) {
                    let consents = safetyService.consentRecords.filter { $0.consentType == type }
                    
                    if consents.isEmpty {
                        Text("No consent record")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(consents) { consent in
                            ConsentRow(consent: consent)
                                .onTapGesture {
                                    selectedConsent = consent
                                }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedConsent) { consent in
            ConsentDetailView(consent: consent)
        }
    }
}

struct ConsentRow: View {
    let consent: ConsentRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(consent.parentName)
                    .font(.headline)
                
                Text(consent.relationship)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Given: \(consent.consentDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if consent.isValid {
                    Label("Valid", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if consent.isExpired {
                    Label("Expired", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Label("Pending", systemImage: "clock.badge.exclamationmark")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct ConsentDetailView: View {
    let consent: ConsentRecord
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Parent/Guardian Information") {
                    LabeledContent("Name", value: consent.parentName)
                    LabeledContent("Relationship", value: consent.relationship)
                    LabeledContent("Email", value: consent.parentEmail)
                    if let phone = consent.parentPhone {
                        LabeledContent("Phone", value: phone)
                    }
                }
                
                Section("Consent Details") {
                    LabeledContent("Type", value: consent.consentType.displayName)
                    LabeledContent("Status", value: consent.isValid ? "Valid" : (consent.verified ? "Pending Verification" : "Not Verified"))
                    LabeledContent("Date Given", value: consent.consentDate.formatted(date: .long, time: .omitted))
                    
                    if let expirationDate = consent.expirationDate {
                        LabeledContent("Expires", value: expirationDate.formatted(date: .long, time: .omitted))
                    }
                    
                    if let verificationMethod = consent.verificationMethod {
                        LabeledContent("Verification Method", value: verificationMethod.rawValue.capitalized)
                    }
                }
            }
            .navigationTitle("Consent Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct EmergencyContactsView: View {
    @EnvironmentObject var safetyService: SafetyService
    @State private var selectedContact: EmergencyContact? = nil
    
    var body: some View {
        List {
            if safetyService.emergencyContacts.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.fill.xmark")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No emergency contacts")
                            .font(.headline)
                        Text("Add at least one emergency contact")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(safetyService.emergencyContacts) { contact in
                    EmergencyContactRow(contact: contact)
                        .onTapGesture {
                            selectedContact = contact
                        }
                }
            }
        }
        .sheet(item: $selectedContact) { contact in
            EmergencyContactDetailView(contact: contact)
        }
    }
}

struct EmergencyContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.headline)
                    if contact.isPrimary {
                        Text("PRIMARY")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(contact.relationship)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Label(contact.primaryPhone, systemImage: "phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if contact.canPickup {
                Image(systemName: "car.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

struct EmergencyContactDetailView: View {
    let contact: EmergencyContact
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Information") {
                    LabeledContent("Name", value: contact.name)
                    LabeledContent("Relationship", value: contact.relationship)
                    LabeledContent("Primary Phone", value: contact.primaryPhone)
                    if let altPhone = contact.alternatePhone {
                        LabeledContent("Alternate Phone", value: altPhone)
                    }
                    if let email = contact.email {
                        LabeledContent("Email", value: email)
                    }
                }
                
                Section("Authorization") {
                    LabeledContent("Primary Contact", value: contact.isPrimary ? "Yes" : "No")
                    LabeledContent("Pickup Authorization", value: contact.canPickup ? "Yes" : "No")
                }
                
                if contact.medicalConditions != nil || contact.allergies != nil || contact.medications != nil {
                    Section("Medical Information") {
                        if let conditions = contact.medicalConditions {
                            LabeledContent("Conditions", value: conditions)
                        }
                        if let allergies = contact.allergies {
                            LabeledContent("Allergies", value: allergies)
                        }
                        if let medications = contact.medications {
                            LabeledContent("Medications", value: medications)
                        }
                    }
                }
                
                if let insurance = contact.insurance {
                    Section("Insurance") {
                        LabeledContent("Provider", value: insurance.provider)
                        LabeledContent("Policy Number", value: insurance.policyNumber)
                        if let groupNumber = insurance.groupNumber {
                            LabeledContent("Group Number", value: groupNumber)
                        }
                    }
                }
            }
            .navigationTitle("Emergency Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ConsentManagementView()
        .environmentObject(SafetyService.shared)
}

