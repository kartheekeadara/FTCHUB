//
//  Secrets.swift
//  FTCHUB
//
//  Created by GPT-5 Codex on 11/8/25.
//

import Foundation

enum SecretKey: String, CaseIterable {
    case supabaseURL = "SUPABASE_URL"
    case supabaseAnonKey = "SUPABASE_ANON_KEY"
    case supabaseEmailRedirectURL = "SUPABASE_EMAIL_REDIRECT_URL"
    case emailVerificationSuccessURL = "EMAIL_VERIFICATION_SUCCESS_URL"
    case passwordResetRedirectURL = "PASSWORD_RESET_REDIRECT_URL"
    case partsCatalogManifestURL = "PARTS_CATALOG_MANIFEST_URL"
    case partsCatalogBaseImageURL = "PARTS_CATALOG_BASE_IMAGE_URL"
    case googleIOSClientID = "GOOGLE_IOS_CLIENT_ID"
    case googleWebClientID = "GOOGLE_WEB_CLIENT_ID"
    case orangeAllianceAPIKey = "ORANGE_ALLIANCE_API_KEY"
}

enum Secrets {
    private static let environment = ProcessInfo.processInfo.environment
    private static let infoDictionary = Bundle.main.infoDictionary
    private static let plistPayload: [String: Any]? = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let payload = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        return payload
    }()
    
    static func value(_ key: SecretKey, fallback: String? = nil) -> String {
        if let resolved = resolve(key) {
            return resolved
        }
        if let fallback = fallback {
            return fallback
        }
        fatalError("Missing value for secret key '\(key.rawValue)'. Provide it via environment variables, Info.plist, or Secrets.plist.")
    }
    
    static func require(_ key: SecretKey) -> String {
        guard let resolved = resolve(key) else {
            fatalError("Secrets.require(_: ) failed – no value supplied for '\(key.rawValue)'.")
        }
        return resolved
    }

    static func optionalValue(_ key: SecretKey) -> String? {
        resolve(key)
    }
    
    private static func resolve(_ key: SecretKey) -> String? {
        if let env = environment[key.rawValue], env.isEmpty == false {
            return env
        }
        
        if let info = infoDictionary?[key.rawValue] as? String, info.isEmpty == false {
            return info
        }
        
        if let plist = plistPayload?[key.rawValue] as? String, plist.isEmpty == false {
            return plist
        }
        
        return nil
    }
}

