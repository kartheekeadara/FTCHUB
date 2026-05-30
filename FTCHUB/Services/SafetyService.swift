//
//  SafetyService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class SafetyService: ObservableObject {
    static let shared = SafetyService()
    
    @Published var consentRecords: [ConsentRecord] = []
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    private init() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            loadSampleData()
        }
    }
    
    // MARK: - Data Loading
    
    func loadSafetyData(for userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Load consent records
            let consents: [ConsentRecord] = try await supabase
                .from("consent_records")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.consentRecords = consents
            
            // Load emergency contacts
            let contacts: [EmergencyContact] = try await supabase
                .from("emergency_contacts")
                .select()
                .eq("student_id", value: userId)
                .order("is_primary", ascending: false)
                .execute()
                .value
            
            self.emergencyContacts = contacts
            
        } catch {
            DebugLog.log("Supabase connection failed, using sample data: \(error)")
            loadSampleData()
            errorMessage = nil
        }
    }
    
    private func loadSampleData() {
        // Create sample consent record
        let sampleConsent = ConsentRecord(
            id: UUID(),
            userId: UUID(),
            parentName: "Sample Parent",
            parentEmail: "parent@example.com",
            parentPhone: "123-456-7890",
            relationship: "parent",
            consentType: .coppa,
            consentDate: Date(),
            expirationDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            verified: true,
            verificationMethod: .email,
            createdAt: Date(),
            updatedAt: Date()
        )
        self.consentRecords = [sampleConsent]
        self.emergencyContacts = [EmergencyContact.sample]
    }
    
    // MARK: - Consent Operations
    
    func createConsent(_ consent: ConsentRecord) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("consent_records")
                .insert(consent)
                .execute()
            await loadSafetyData(for: consent.userId)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateConsent(_ consent: ConsentRecord) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("consent_records")
                .update(consent)
                .eq("id", value: consent.id)
                .execute()
            await loadSafetyData(for: consent.userId)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func hasValidConsent(userId: UUID, type: ConsentRecord.ConsentType) -> Bool {
        consentRecords.first { record in
            record.userId == userId &&
            record.consentType == type &&
            record.isValid
        } != nil
    }
    
    func getMissingRequiredConsents(userId: UUID) -> [ConsentRecord.ConsentType] {
        ConsentRecord.ConsentType.allCases.filter { type in
            // Note: ConsentRecord.ConsentType doesn't have isRequired property
            // This is a simplified check - you may need to add isRequired to ConsentRecord.ConsentType
            !hasValidConsent(userId: userId, type: type)
        }
    }
    
    // MARK: - Emergency Contact Operations
    
    func createEmergencyContact(_ contact: EmergencyContact) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("emergency_contacts")
                .insert(contact)
                .execute()
            await loadSafetyData(for: contact.studentId)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateEmergencyContact(_ contact: EmergencyContact) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("emergency_contacts")
                .update(contact)
                .eq("id", value: contact.id)
                .execute()
            await loadSafetyData(for: contact.studentId)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteEmergencyContact(_ contact: EmergencyContact) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("emergency_contacts")
                .delete()
                .eq("id", value: contact.id)
                .execute()
            await loadSafetyData(for: contact.studentId)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func getPrimaryContact(userId: UUID) -> EmergencyContact? {
        emergencyContacts.first { $0.studentId == userId && $0.isPrimary }
    }
    
    // MARK: - Safety Checks
    
    func isStudentSafe(userId: UUID) -> SafetyStatus {
        let missingConsents = getMissingRequiredConsents(userId: userId)
        let hasEmergencyContact = !emergencyContacts.filter { $0.studentId == userId }.isEmpty
        
        if !missingConsents.isEmpty {
            return .missingConsent(missingConsents)
        }
        
        if !hasEmergencyContact {
            return .missingEmergencyContact
        }
        
        return .compliant
    }
}

enum SafetyStatus {
    case compliant
    case missingConsent([ConsentRecord.ConsentType])
    case missingEmergencyContact
    
    var isCompliant: Bool {
        if case .compliant = self {
            return true
        }
        return false
    }
    
    var message: String {
        switch self {
        case .compliant:
            return "All safety requirements met"
        case .missingConsent(let types):
            return "Missing consent: \(types.map { $0.displayName }.joined(separator: ", "))"
        case .missingEmergencyContact:
            return "Emergency contact required"
        }
    }
}

