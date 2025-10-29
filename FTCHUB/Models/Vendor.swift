//
//  Vendor.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/28/25.
//

import Foundation

struct Vendor: Identifiable, Codable {
    let id: UUID
    let teamId: UUID
    let name: String
    let contactPerson: String?
    let email: String?
    let phone: String?
    let website: String?
    let address: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, website, address, notes
        case teamId = "team_id"
        case contactPerson = "contact_person"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static let sampleVendors: [Vendor] = [
        Vendor(
            id: UUID(),
            teamId: UUID(),
            name: "REV Robotics",
            contactPerson: "Sales Team",
            email: "sales@revrobotics.com",
            phone: "(512) 555-0100",
            website: "https://www.revrobotics.com",
            address: "Austin, TX",
            notes: "Primary parts supplier",
            createdAt: Date().addingTimeInterval(-86400 * 60),
            updatedAt: Date()
        ),
        Vendor(
            id: UUID(),
            teamId: UUID(),
            name: "TETRIX",
            contactPerson: "Customer Service",
            email: "support@tetrix.com",
            phone: "(800) 555-0200",
            website: "https://www.pitsco.com/tetrix",
            address: "Pittsburg, KS",
            notes: "Alternative parts supplier",
            createdAt: Date().addingTimeInterval(-86400 * 45),
            updatedAt: Date()
        ),
        Vendor(
            id: UUID(),
            teamId: UUID(),
            name: "Local Hardware Store",
            contactPerson: "John Smith",
            email: "john@hardware.com",
            phone: "(555) 123-4567",
            website: nil,
            address: "123 Main St, Local City",
            notes: "Quick local purchases",
            createdAt: Date().addingTimeInterval(-86400 * 30),
            updatedAt: Date()
        )
    ]
}

