//
//  PasswordStrength.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import Foundation
import SwiftUI

enum PasswordStrength {
    case weak
    case fair
    case good
    case strong
    case amazing
    
    var displayName: String {
        switch self {
        case .weak: return "Weak! Add Strength!"
        case .fair: return "Fair"
        case .good: return "Good"
        case .strong: return "Strong"
        case .amazing: return "Amazing!"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return DesignSystem.Colors.error
        case .fair: return DesignSystem.Colors.warning
        case .good: return DesignSystem.Colors.success.opacity(0.7)
        case .strong: return DesignSystem.Colors.success
        case .amazing: return DesignSystem.Colors.success
        }
    }
    
    var progress: Double {
        switch self {
        case .weak: return 0.2
        case .fair: return 0.4
        case .good: return 0.6
        case .strong: return 0.8
        case .amazing: return 1.0
        }
    }
    
    static func calculate(_ password: String) -> PasswordStrength {
        guard !password.isEmpty else { return .weak }
        
        var score = 0
        
        // Length check
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        
        // Character variety
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }
        
        switch score {
        case 0...1: return .weak
        case 2: return .fair
        case 3...4: return .good
        case 5...6: return .strong
        default: return .amazing
        }
    }
}

extension CharacterSet {
    static var lowercaseLetters: CharacterSet {
        return CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz")
    }
    
    static var uppercaseLetters: CharacterSet {
        return CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }
}


