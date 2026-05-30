//
//  InputValidator.swift
//  FTCHUB
//
//  Schema-style input validation for user-supplied data before network calls.
//  OWASP: reject invalid types, enforce length limits, trim and sanitize text.
//

import Foundation

enum ValidationError: LocalizedError {
    case invalidField(String)
    case tooManyFields(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidField(let message): return message
        case .tooManyFields(let message): return message
        }
    }
}

enum InputValidator {
    
    // MARK: - JSON key allowlists (reject unexpected fields in JSONB payloads)
    
    static func rejectUnknownKeys(
        in jsonObject: [String: Any],
        allowedKeys: Set<String>,
        context: String
    ) throws {
        let unknown = Set(jsonObject.keys).subtracting(allowedKeys)
        guard unknown.isEmpty else {
            throw ValidationError.tooManyFields(
                "Unexpected fields in \(context): \(unknown.sorted().joined(separator: ", "))"
            )
        }
    }
    
    // MARK: - Auth
    
    struct SignInInput {
        let email: String
        let password: String
        
        init(email: String, password: String) throws {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard SecurityUtils.validateEmail(trimmedEmail) else {
                throw ValidationError.invalidField("Please enter a valid email address.")
            }
            guard !password.isEmpty, password.count <= 128 else {
                throw ValidationError.invalidField("Password is invalid.")
            }
            self.email = trimmedEmail
            self.password = password
        }
    }
    
    struct SignUpInput {
        let email: String
        let password: String
        let firstName: String
        let lastName: String
        
        init(email: String, password: String, firstName: String, lastName: String) throws {
            let signIn = try SignInInput(email: email, password: password)
            let strength = SecurityUtils.validatePasswordStrength(signIn.password)
            guard strength.isValid else {
                throw ValidationError.invalidField(strength.issues.first ?? "Password does not meet requirements.")
            }
            self.email = signIn.email
            self.password = signIn.password
            self.firstName = try PersonNameInput.validate(firstName, fieldName: "First name")
            self.lastName = try PersonNameInput.validate(lastName, fieldName: "Last name")
        }
    }
    
    struct PasswordResetInput {
        let email: String
        
        init(email: String) throws {
            self.email = try SignInInput(email: email, password: "placeholder").email
        }
    }
    
    // MARK: - Profile / person names
    
    enum PersonNameInput {
        static func validate(_ raw: String, fieldName: String, maxLength: Int = 80) throws -> String {
            let trimmed = SecurityUtils.sanitizeInput(raw, maxLength: maxLength)
            guard !trimmed.isEmpty else {
                throw ValidationError.invalidField("\(fieldName) is required.")
            }
            guard trimmed.count <= maxLength else {
                throw ValidationError.invalidField("\(fieldName) must be \(maxLength) characters or fewer.")
            }
            return trimmed
        }
    }
    
    // MARK: - Team
    
    struct TeamCreateInput {
        let name: String
        let teamNumber: String
        let school: String?
        let city: String?
        let state: String?
        
        init(
            name: String,
            teamNumber: String,
            school: String? = nil,
            city: String? = nil,
            state: String? = nil
        ) throws {
            let trimmedName = SecurityUtils.sanitizeInput(name, maxLength: 200)
            guard !trimmedName.isEmpty else {
                throw ValidationError.invalidField("Team name is required.")
            }
            let trimmedNumber = teamNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            guard SecurityUtils.validateTeamNumber(trimmedNumber) else {
                throw ValidationError.invalidField("Team number must be 1–10 letters or digits.")
            }
            self.name = trimmedName
            self.teamNumber = trimmedNumber
            self.school = school.map { SecurityUtils.sanitizeInput($0, maxLength: 200) }.flatMap { $0.isEmpty ? nil : $0 }
            self.city = city.map { SecurityUtils.sanitizeInput($0, maxLength: 100) }.flatMap { $0.isEmpty ? nil : $0 }
            self.state = state.map { SecurityUtils.sanitizeInput($0, maxLength: 50) }.flatMap { $0.isEmpty ? nil : $0 }
        }
    }
    
    struct InviteCodeInput {
        let code: String
        
        init(_ raw: String) throws {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard InviteCodeGenerator.isValid(trimmed) else {
                throw ValidationError.invalidField("Invite code format is invalid.")
            }
            self.code = trimmed
        }
    }
    
    // MARK: - Scouting
    
    struct ScoutingReportInput {
        let notes: String?
        let teamNumber: String?
        
        init(notes: String?, teamNumber: String? = nil) throws {
            if let notes {
                let sanitized = SecurityUtils.sanitizeInput(notes, maxLength: 10_000)
                self.notes = sanitized.isEmpty ? nil : sanitized
            } else {
                self.notes = nil
            }
            if let teamNumber {
                let trimmed = teamNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                guard SecurityUtils.validateTeamNumber(trimmed) else {
                    throw ValidationError.invalidField("Invalid team number.")
                }
                self.teamNumber = trimmed
            } else {
                self.teamNumber = nil
            }
        }
    }
    
    static let scoutingTemplateDataMaxBytes = 50_000
    
    static func validateScoutingTemplateDataSize(_ data: Data) throws {
        guard data.count <= scoutingTemplateDataMaxBytes else {
            throw ValidationError.invalidField("Scouting template data is too large.")
        }
    }
    
    // MARK: - Content moderation
    
    struct ContentReportInput {
        let description: String?
        
        init(description: String?) throws {
            if let description {
                let sanitized = SecurityUtils.sanitizeInput(description, maxLength: 2000)
                self.description = sanitized.isEmpty ? nil : sanitized
            } else {
                self.description = nil
            }
        }
    }
    
    // MARK: - Finance
    
    struct MoneyAmountInput {
        let amount: Decimal
        
        init(amount: Decimal) throws {
            guard amount >= 0, amount <= 9_999_999.99 else {
                throw ValidationError.invalidField("Amount must be between 0 and 9,999,999.99.")
            }
            self.amount = amount
        }
    }
    
    struct VendorNameInput {
        let name: String
        
        init(_ raw: String) throws {
            let trimmed = SecurityUtils.sanitizeInput(raw, maxLength: 200)
            guard !trimmed.isEmpty else {
                throw ValidationError.invalidField("Vendor name is required.")
            }
            self.name = trimmed
        }
    }
    
    struct FinanceNotesInput {
        let notes: String?
        
        init(_ raw: String?) throws {
            if let raw {
                let trimmed = SecurityUtils.sanitizeInput(raw, maxLength: 2000)
                self.notes = trimmed.isEmpty ? nil : trimmed
            } else {
                self.notes = nil
            }
        }
    }
    
    // MARK: - Consent
    
    struct ConsentRecordInput {
        let parentName: String
        let parentEmail: String
        let parentPhone: String?
        
        init(parentName: String, parentEmail: String, parentPhone: String?) throws {
            self.parentName = try PersonNameInput.validate(parentName, fieldName: "Parent name", maxLength: 200)
            let email = parentEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard SecurityUtils.validateEmail(email) else {
                throw ValidationError.invalidField("Parent email is invalid.")
            }
            self.parentEmail = email
            if let phone = parentPhone, !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let sanitized = SecurityUtils.sanitizeInput(phone, maxLength: 30)
                self.parentPhone = sanitized
            } else {
                self.parentPhone = nil
            }
        }
    }
}
