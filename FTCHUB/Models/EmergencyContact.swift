//
//  EmergencyContact.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation

struct EmergencyContact: Identifiable, Codable {
    let id: UUID
    let studentId: UUID
    let name: String
    let relationship: String
    let primaryPhone: String
    let alternatePhone: String?
    let email: String?
    let address: String?
    let isPrimary: Bool
    let canPickup: Bool
    let medicalConditions: String?
    let allergies: String?
    let medications: String?
    let insurance: InsuranceInfo?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case studentId = "student_id"
        case name, relationship
        case primaryPhone = "primary_phone"
        case alternatePhone = "alternate_phone"
        case email, address
        case isPrimary = "is_primary"
        case canPickup = "can_pickup"
        case medicalConditions = "medical_conditions"
        case allergies, medications, insurance, notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static let sample = EmergencyContact(
        id: UUID(),
        studentId: UUID(),
        name: "Jane Smith",
        relationship: "Parent",
        primaryPhone: "(555) 123-4567",
        alternatePhone: "(555) 987-6543",
        email: "jane.smith@email.com",
        address: "123 Main St, City, ST 12345",
        isPrimary: true,
        canPickup: true,
        medicalConditions: nil,
        allergies: "Peanuts",
        medications: nil,
        insurance: InsuranceInfo(
            provider: "Blue Cross",
            policyNumber: "ABC123456",
            groupNumber: "GRP789"
        ),
        notes: "Available 24/7",
        createdAt: Date(),
        updatedAt: Date()
    )
}

struct InsuranceInfo: Codable {
    let provider: String
    let policyNumber: String
    let groupNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case provider
        case policyNumber = "policy_number"
        case groupNumber = "group_number"
    }
}

