//
//  ConsentRecord.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation

struct ConsentRecord: Identifiable, Codable {
    let id: UUID
    let studentId: UUID
    let parentName: String
    let parentEmail: String
    let parentPhone: String?
    let relationship: String // Parent, Guardian, etc.
    let consentType: ConsentType
    let consentGiven: Bool
    let consentDate: Date?
    let expirationDate: Date?
    let signature: String? // Base64 encoded signature image
    let ipAddress: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case studentId = "student_id"
        case parentName = "parent_name"
        case parentEmail = "parent_email"
        case parentPhone = "parent_phone"
        case relationship
        case consentType = "consent_type"
        case consentGiven = "consent_given"
        case consentDate = "consent_date"
        case expirationDate = "expiration_date"
        case signature
        case ipAddress = "ip_address"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < Date()
    }
    
    var isValid: Bool {
        consentGiven && !isExpired
    }
    
    static let sample = ConsentRecord(
        id: UUID(),
        studentId: UUID(),
        parentName: "Jane Smith",
        parentEmail: "jane.smith@email.com",
        parentPhone: "(555) 123-4567",
        relationship: "Parent",
        consentType: .dataCollection,
        consentGiven: true,
        consentDate: Date().addingTimeInterval(-86400 * 30),
        expirationDate: Date().addingTimeInterval(86400 * 335), // ~1 year
        signature: nil,
        ipAddress: "192.168.1.1",
        notes: nil,
        createdAt: Date().addingTimeInterval(-86400 * 30),
        updatedAt: Date()
    )
}

enum ConsentType: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case dataCollection = "data_collection"
    case photoVideo = "photo_video"
    case transportation = "transportation"
    case medicalEmergency = "medical_emergency"
    case competition = "competition"
    
    var displayName: String {
        switch self {
        case .dataCollection: return "Data Collection & Storage"
        case .photoVideo: return "Photo & Video Release"
        case .transportation: return "Transportation"
        case .medicalEmergency: return "Medical Emergency"
        case .competition: return "Competition Participation"
        }
    }
    
    var description: String {
        switch self {
        case .dataCollection:
            return "Consent to collect and store student information including name, contact details, and team activities."
        case .photoVideo:
            return "Permission to take and use photos/videos of the student for team promotion and documentation."
        case .transportation:
            return "Authorization for team-organized transportation to events and competitions."
        case .medicalEmergency:
            return "Permission to seek medical care in case of emergency during team activities."
        case .competition:
            return "Consent for student participation in FTC competitions and related events."
        }
    }
    
    var isRequired: Bool {
        switch self {
        case .dataCollection, .competition: return true
        case .photoVideo, .transportation, .medicalEmergency: return false
        }
    }
}

