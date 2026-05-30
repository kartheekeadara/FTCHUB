//
//  ConsentRecord.swift
//  FTCHUB
//
//  Created for COPPA Compliance
//

import Foundation

struct ConsentRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let parentName: String
    let parentEmail: String
    let parentPhone: String?
    let relationship: String // "parent", "guardian", "legal_guardian"
    let consentType: ConsentType
    let consentDate: Date
    let expirationDate: Date?
    let verified: Bool
    let verificationMethod: VerificationMethod?
    let createdAt: Date
    let updatedAt: Date
    
    enum ConsentType: String, Codable, CaseIterable {
        case coppa = "coppa" // COPPA parental consent
        case dataCollection = "data_collection"
        case thirdPartySharing = "third_party_sharing"
        case location = "location"
        
        var displayName: String {
            switch self {
            case .coppa: return "COPPA Parental Consent"
            case .dataCollection: return "Data Collection"
            case .thirdPartySharing: return "Third Party Sharing"
            case .location: return "Location Services"
            }
        }
        
        var description: String {
            switch self {
            case .coppa: return "Required for users under 13"
            case .dataCollection: return "Permission to collect data"
            case .thirdPartySharing: return "Permission to share with partners"
            case .location: return "Permission to use location"
            }
        }
    }
    
    enum VerificationMethod: String, Codable {
        case email = "email"
        case phone = "phone"
        case signature = "signature"
        case inPerson = "in_person"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case parentName = "parent_name"
        case parentEmail = "parent_email"
        case parentPhone = "parent_phone"
        case relationship
        case consentType = "consent_type"
        case consentDate = "consent_date"
        case expirationDate = "expiration_date"
        case verified
        case verificationMethod = "verification_method"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() > expiration
    }
    
    var isValid: Bool {
        return verified && !isExpired
    }
}
