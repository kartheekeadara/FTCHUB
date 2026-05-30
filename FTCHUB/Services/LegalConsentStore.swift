//
//  LegalConsentStore.swift
//  FTCHUB
//
//  Created by GPT-5 Codex on 11/9/25.
//

import Foundation

struct LegalConsentRecord: Codable {
    let userId: UUID?
    let acceptedAt: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: acceptedAt)
    }
}

enum LegalConsentStore {
    private static let storageKey = "ftchub.legalConsent.records"
    
    private static func identifier(for userId: UUID?) -> String {
        userId?.uuidString ?? "anonymous"
    }
    
    static func recordAcceptance(for userId: UUID?) -> LegalConsentRecord {
        let record = LegalConsentRecord(userId: userId, acceptedAt: Date())
        var payload = loadRecords()
        payload[identifier(for: userId)] = record
        saveRecords(payload)
        return record
    }
    
    static func revokeAcceptance(for userId: UUID?) {
        var payload = loadRecords()
        payload.removeValue(forKey: identifier(for: userId))
        saveRecords(payload)
    }
    
    static func currentRecord(for userId: UUID?) -> LegalConsentRecord? {
        loadRecords()[identifier(for: userId)]
    }
    
    private static func loadRecords() -> [String: LegalConsentRecord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return [:]
        }
        do {
            let decoded = try JSONDecoder().decode([String: LegalConsentRecord].self, from: data)
            return decoded
        } catch {
            UserDefaults.standard.removeObject(forKey: storageKey)
            TelemetryService.shared.logError(error, context: ["action": "legal_consent_load"])
            return [:]
        }
    }
    
    private static func saveRecords(_ records: [String: LegalConsentRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            TelemetryService.shared.logError(error, context: ["action": "legal_consent_save"])
        }
    }
}

