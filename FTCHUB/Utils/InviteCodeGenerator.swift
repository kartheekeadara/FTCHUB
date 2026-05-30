//
//  InviteCodeGenerator.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

struct InviteCodeGenerator {
    static func generate() -> String {
        // Generate an 8-10 character alphanumeric code (randomly 8, 9, or 10 characters)
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Removed confusing characters (0, O, I, 1)
        let codeLength = Int.random(in: 8...10) // Random length between 8 and 10
        
        return String((0..<codeLength).map { _ in
            characters.randomElement()!
        })
    }
    
    static func isValid(_ code: String) -> Bool {
        // Check if code is 6-10 characters and contains only valid characters (more flexible)
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 6 && trimmed.count <= 10 else { return false }
        let validCharacters = CharacterSet(charactersIn: "ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return trimmed.uppercased().unicodeScalars.allSatisfy { validCharacters.contains($0) }
    }
}

