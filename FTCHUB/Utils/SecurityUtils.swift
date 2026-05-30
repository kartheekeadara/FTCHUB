//
//  SecurityUtils.swift
//  FTCHUB
//
//  Created for Security Hardening
//

import Foundation
import Security

/// Security utilities for input validation, sanitization, and security checks
enum SecurityUtils {
    
    // MARK: - Input Validation
    
    /// Validates and sanitizes email addresses
    static func validateEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Sanitizes string input to prevent injection attacks
    static func sanitizeInput(_ input: String, maxLength: Int = 1000) -> String {
        var sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove potentially dangerous characters
        sanitized = sanitized.replacingOccurrences(of: "<", with: "&lt;")
        sanitized = sanitized.replacingOccurrences(of: ">", with: "&gt;")
        sanitized = sanitized.replacingOccurrences(of: "\"", with: "&quot;")
        sanitized = sanitized.replacingOccurrences(of: "'", with: "&#x27;")
        sanitized = sanitized.replacingOccurrences(of: "/", with: "&#x2F;")
        
        // Enforce max length
        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
        }
        
        return sanitized
    }
    
    /// Validates team number format (alphanumeric, 1-10 characters)
    static func validateTeamNumber(_ number: String) -> Bool {
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 10 else { return false }
        return trimmed.allSatisfy { $0.isLetter || $0.isNumber }
    }
    
    /// Validates UUID string format
    static func validateUUID(_ uuidString: String) -> Bool {
        return UUID(uuidString: uuidString) != nil
    }
    
    /// Validates numeric input
    static func validateNumeric(_ value: String, min: Double? = nil, max: Double? = nil) -> Bool {
        guard let num = Double(value) else { return false }
        if let min = min, num < min { return false }
        if let max = max, num > max { return false }
        return true
    }
    
    /// Validates URL format and ensures HTTPS
    static func validateHTTPSURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        guard url.scheme == "https" else { return false }
        return true
    }
    
    // MARK: - File Validation
    
    /// Validates file size (in bytes)
    static func validateFileSize(_ data: Data, maxSize: Int = 10 * 1024 * 1024) -> Bool {
        return data.count <= maxSize && data.count > 0
    }
    
    /// Validates image file type
    static func validateImageType(_ data: Data) -> Bool {
        // Check for common image file signatures
        guard data.count >= 4 else { return false }
        
        let bytes = [UInt8](data.prefix(4))
        
        // JPEG: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return true
        }
        
        // PNG: 89 50 4E 47
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return true
        }
        
        // GIF: 47 49 46 38
        if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38 {
            return true
        }
        
        return false
    }
    
    /// Validates MIME type for uploads
    static func validateMIMEType(_ mimeType: String, allowedTypes: [String]) -> Bool {
        return allowedTypes.contains(mimeType.lowercased())
    }
    
    // MARK: - Authorization
    
    /// Verifies user belongs to the specified team
    static func verifyTeamMembership(userTeamId: UUID?, requestedTeamId: UUID) -> Bool {
        guard let userTeamId = userTeamId else { return false }
        return userTeamId == requestedTeamId
    }
    
    /// Verifies user has required role
    static func verifyRole(userRole: UserRole?, requiredRoles: [UserRole]) -> Bool {
        guard let userRole = userRole else { return false }
        return requiredRoles.contains(userRole)
    }
    
    // MARK: - URL Validation
    
    /// Ensures Supabase URL uses HTTPS
    static func validateSupabaseURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        guard url.scheme == "https" else { return false }
        // Ensure it's a Supabase URL
        guard url.host?.contains("supabase.co") == true || url.host?.contains("supabase.io") == true else {
            return false
        }
        return true
    }
    
    // MARK: - Secure Logging
    
    /// Sanitizes error messages before logging to prevent sensitive data exposure
    static func sanitizeForLogging(_ message: String) -> String {
        var sanitized = message
        
        // Remove potential sensitive patterns
        let patterns = [
            #"(?i)password\s*[:=]\s*\S+"#,
            #"(?i)token\s*[:=]\s*\S+"#,
            #"(?i)key\s*[:=]\s*\S+"#,
            #"(?i)secret\s*[:=]\s*\S+"#,
            #"https?://[^\s]+"#  // URLs
        ]
        
        for pattern in patterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "[REDACTED]",
                options: .regularExpression
            )
        }
        
        return sanitized
    }
    
    // MARK: - Secure Storage (Keychain)
    
    /// Securely stores a string value in the Keychain
    static func storeInKeychain(key: String, value: String, service: String = Bundle.main.bundleIdentifier ?? "com.ftchub.app") -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item if it exists
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieves a string value from the Keychain
    static func retrieveFromKeychain(key: String, service: String = Bundle.main.bundleIdentifier ?? "com.ftchub.app") -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Deletes a value from the Keychain
    static func deleteFromKeychain(key: String, service: String = Bundle.main.bundleIdentifier ?? "com.ftchub.app") -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Rate Limiting
    
    /// Simple rate limiting check (prevents brute force attacks)
    private static var rateLimitAttempts: [String: (count: Int, resetTime: Date)] = [:]
    private static let rateLimitQueue = DispatchQueue(label: "com.ftchub.ratelimit")
    
    static func checkRateLimit(identifier: String, maxAttempts: Int = 5, windowSeconds: Int = 300) -> Bool {
        return rateLimitQueue.sync {
            let now = Date()
            
            if let record = rateLimitAttempts[identifier] {
                // Reset if window expired
                if now > record.resetTime {
                    rateLimitAttempts[identifier] = (count: 1, resetTime: now.addingTimeInterval(TimeInterval(windowSeconds)))
                    return true
                }
                
                // Check if limit exceeded
                if record.count >= maxAttempts {
                    return false
                }
                
                // Increment count
                rateLimitAttempts[identifier] = (count: record.count + 1, resetTime: record.resetTime)
                return true
            } else {
                // First attempt
                rateLimitAttempts[identifier] = (count: 1, resetTime: now.addingTimeInterval(TimeInterval(windowSeconds)))
                return true
            }
        }
    }
    
    static func resetRateLimit(identifier: String) {
        rateLimitQueue.async {
            rateLimitAttempts.removeValue(forKey: identifier)
        }
    }
    
    // MARK: - Password Strength
    
    /// Validates password strength
    static func validatePasswordStrength(_ password: String) -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        if password.count < 8 {
            issues.append("Password must be at least 8 characters long")
        }
        
        if !password.contains(where: { $0.isUppercase }) {
            issues.append("Password must contain at least one uppercase letter")
        }
        
        if !password.contains(where: { $0.isLowercase }) {
            issues.append("Password must contain at least one lowercase letter")
        }
        
        if !password.contains(where: { $0.isNumber }) {
            issues.append("Password must contain at least one number")
        }
        
        if !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
            issues.append("Password must contain at least one special character")
        }
        
        return (issues.isEmpty, issues)
    }
    
    // MARK: - SQL Injection Prevention
    
    /// Sanitizes input for SQL queries (parameterized queries should be used instead)
    static func sanitizeForSQL(_ input: String) -> String {
        var sanitized = input
        // Remove SQL injection patterns
        let dangerous = ["'", "\"", ";", "--", "/*", "*/", "xp_", "sp_", "exec", "union", "select", "insert", "update", "delete", "drop", "create", "alter"]
        for pattern in dangerous {
            sanitized = sanitized.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        return sanitized
    }
}

