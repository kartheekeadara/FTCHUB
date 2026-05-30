//
//  ConsentService.swift
//  FTCHUB
//
//  Created for COPPA Compliance
//

import Foundation
import Supabase
import Combine

@MainActor
class ConsentService: ObservableObject {
    static let shared = ConsentService()
    
    @Published var consentRecords: [ConsentRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Load Consent Records
    func loadConsentRecords(for userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let records: [ConsentRecord] = try await supabase
                .from("consent_records")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            consentRecords = records
        } catch {
            errorMessage = "Failed to load consent records: \(error.localizedDescription)"
            TelemetryService.shared.logError(error, context: ["action": "load_consent_records"])
        }
    }
    
    // MARK: - Create Consent Record
    func createConsentRecord(
        userId: UUID,
        parentName: String,
        parentEmail: String,
        parentPhone: String?,
        relationship: String,
        consentType: ConsentRecord.ConsentType,
        verificationMethod: ConsentRecord.VerificationMethod
    ) async throws -> ConsentRecord {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let validated = try InputValidator.ConsentRecordInput(
            parentName: parentName,
            parentEmail: parentEmail,
            parentPhone: parentPhone
        )
        let sanitizedParentName = validated.parentName
        let sanitizedRelationship = SecurityUtils.sanitizeInput(relationship, maxLength: 50)
        guard ["parent", "guardian", "legal_guardian"].contains(sanitizedRelationship.lowercased()) else {
            throw ConsentError.invalidRelationship
        }
        
        // Calculate expiration date (1 year from now for COPPA)
        let expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        
        let consentRecord = ConsentRecord(
            id: UUID(),
            userId: userId,
            parentName: sanitizedParentName,
            parentEmail: validated.parentEmail,
            parentPhone: validated.parentPhone,
            relationship: sanitizedRelationship,
            consentType: consentType,
            consentDate: Date(),
            expirationDate: expirationDate,
            verified: false, // Will be verified via email/phone
            verificationMethod: verificationMethod,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await supabase
                .from("consent_records")
                .insert(consentRecord)
                .execute()
            
            // Send verification email to parent
            try await sendVerificationEmail(to: parentEmail, for: consentRecord)
            
            consentRecords.append(consentRecord)
            return consentRecord
        } catch {
            errorMessage = "Failed to create consent record: \(error.localizedDescription)"
            TelemetryService.shared.logError(error, context: ["action": "create_consent_record"])
            throw error
        }
    }
    
    // MARK: - Verify Consent
    func verifyConsent(consentId: UUID, verificationCode: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // In a real implementation, you would verify the code
        // For now, we'll mark as verified (you should implement proper verification)
        
        do {
            // Load the existing record first to get the user ID
            let existingRecords: [ConsentRecord] = try await supabase
                .from("consent_records")
                .select()
                .eq("id", value: consentId)
                .execute()
                .value
            
            guard let existingRecord = existingRecords.first else {
                throw ConsentError.consentNotFound
            }
            
            // Create update struct with only the fields we want to update
            struct ConsentVerificationUpdate: Codable {
                let verified: Bool
                let updated_at: String
                
                enum CodingKeys: String, CodingKey {
                    case verified
                    case updated_at
                }
            }
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let update = ConsentVerificationUpdate(
                verified: true,
                updated_at: formatter.string(from: Date())
            )
            
            try await supabase
                .from("consent_records")
                .update(update)
                .eq("id", value: consentId)
                .execute()
            
            // Reload records to get updated data
            await loadConsentRecords(for: existingRecord.userId)
        } catch {
            errorMessage = "Failed to verify consent: \(error.localizedDescription)"
            TelemetryService.shared.logError(error, context: ["action": "verify_consent"])
            throw error
        }
    }
    
    // MARK: - Check if User Has Valid Consent
    func hasValidConsent(userId: UUID, consentType: ConsentRecord.ConsentType) async -> Bool {
        await loadConsentRecords(for: userId)
        
        return consentRecords.contains { record in
            record.userId == userId &&
            record.consentType == consentType &&
            record.isValid
        }
    }
    
    // MARK: - Private Methods
    private func sendVerificationEmail(to email: String, for consent: ConsentRecord) async throws {
        // In a real implementation, you would send an email via Supabase Edge Function
        // or email service (SendGrid, AWS SES, etc.)
        // For now, we'll log it
        TelemetryService.shared.logEvent("consent_verification_email_sent", parameters: [
            "email": email,
            "consent_id": consent.id.uuidString
        ])
        
        // TODO: Implement actual email sending via Supabase Edge Function
        // This should send a verification link/code to the parent
    }
}

// MARK: - Consent Errors
enum ConsentError: LocalizedError {
    case invalidEmail
    case invalidName
    case invalidPhone
    case invalidRelationship
    case consentNotFound
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid parent/guardian email address."
        case .invalidName:
            return "Parent/guardian name is required."
        case .invalidPhone:
            return "Please enter a valid phone number."
        case .invalidRelationship:
            return "Please select a valid relationship (parent, guardian, or legal guardian)."
        case .consentNotFound:
            return "Consent record not found."
        case .verificationFailed:
            return "Consent verification failed. Please try again."
        }
    }
}

