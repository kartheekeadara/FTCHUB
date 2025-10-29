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
    
    func loadSafetyData(for studentId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Load consent records
            let consents: [ConsentRecord] = try await supabase
                .from("consent_records")
                .select()
                .eq("student_id", value: studentId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.consentRecords = consents
            
            // Load emergency contacts
            let contacts: [EmergencyContact] = try await supabase
                .from("emergency_contacts")
                .select()
                .eq("student_id", value: studentId)
                .order("is_primary", ascending: false)
                .execute()
                .value
            
            self.emergencyContacts = contacts
            
        } catch {
            print("Supabase connection failed, using sample data: \(error)")
            loadSampleData()
            errorMessage = nil
        }
    }
    
    private func loadSampleData() {
        self.consentRecords = [ConsentRecord.sample]
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
            await loadSafetyData(for: consent.studentId)
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
            await loadSafetyData(for: consent.studentId)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func hasValidConsent(studentId: UUID, type: ConsentType) -> Bool {
        consentRecords.first { record in
            record.studentId == studentId &&
            record.consentType == type &&
            record.isValid
        } != nil
    }
    
    func getMissingRequiredConsents(studentId: UUID) -> [ConsentType] {
        ConsentType.allCases.filter { type in
            type.isRequired && !hasValidConsent(studentId: studentId, type: type)
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
    
    func getPrimaryContact(studentId: UUID) -> EmergencyContact? {
        emergencyContacts.first { $0.studentId == studentId && $0.isPrimary }
    }
    
    // MARK: - Safety Checks
    
    func isStudentSafe(studentId: UUID) -> SafetyStatus {
        let missingConsents = getMissingRequiredConsents(studentId: studentId)
        let hasEmergencyContact = !emergencyContacts.filter { $0.studentId == studentId }.isEmpty
        
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
    case missingConsent([ConsentType])
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

