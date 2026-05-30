//
//  Config.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation

struct Config {
    // MARK: - Remote Services
    static var supabaseURL: String { Secrets.require(.supabaseURL) }
    static var supabaseAnonKey: String { Secrets.require(.supabaseAnonKey) }
    static var supabaseEmailRedirectURL: String { Secrets.value(.supabaseEmailRedirectURL, fallback: "ftchub://auth-callback") }
    
    // MARK: - Email Verification
    // Host web/email-verification-success.html (see web/) and set EMAIL_VERIFICATION_SUCCESS_URL in Secrets.plist,
    // or use Supabase Storage public bucket "verification" with the default URL constructed below.
    static var emailVerificationSuccessURL: String {
        // First, try to get a custom URL from Secrets
        // If not set, use the default Supabase Storage URL
        let customURL = Secrets.value(.emailVerificationSuccessURL, fallback: "")
        
        // If a custom URL is provided and it's not empty, use it
        if !customURL.isEmpty && customURL != "" {
            return customURL
        }
        
        // Otherwise, construct Supabase Storage URL
        // Extract project ref from supabaseURL (e.g., "https://abc123.supabase.co" -> "abc123")
        let urlString = supabaseURL.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
        let projectRef = urlString.components(separatedBy: ".").first ?? "your-project"
        
        return "https://\(projectRef).supabase.co/storage/v1/object/public/verification/email-verification-success.html"
    }
    
    // MARK: - Password Reset
    // Password reset redirect URL - should point to hosted password-reset-redirect.html page
    // IMPORTANT: You must host the password-reset-redirect.html file and configure the URL here
    // 
    // Option 1: Use Supabase Storage (recommended)
    // 1. Create a public bucket named "verification" in Supabase Storage (or use existing)
    // 2. Upload web/password-reset-redirect.html to that bucket
    // 3. The URL will be: https://[project-ref].supabase.co/storage/v1/object/public/verification/password-reset-redirect.html
    //
    // Option 2: Use a custom domain
    // Set the URL in Secrets.plist with key "PASSWORD_RESET_REDIRECT_URL"
    static var passwordResetRedirectURL: String {
        // First, try to get a custom URL from Secrets
        let customURL = Secrets.value(.passwordResetRedirectURL, fallback: "")
        
        // If a custom URL is provided and it's not empty, use it
        if !customURL.isEmpty && customURL != "" {
            return customURL
        }
        
        // Otherwise, construct Supabase Storage URL
        // Extract project ref from supabaseURL (e.g., "https://abc123.supabase.co" -> "abc123")
        let urlString = supabaseURL.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
        let projectRef = urlString.components(separatedBy: ".").first ?? "your-project"
        
        return "https://\(projectRef).supabase.co/storage/v1/object/public/verification/password-reset-redirect.html"
    }
    
    // MARK: - Legal & Support URLs
    /// Canonical privacy policy (styled HTML). See https://uninetx.github.io/Email-Verification/privacy-policy
    static let privacyPolicyURL = URL(string: "https://uninetx.github.io/Email-Verification/privacy-policy")!

    // MARK: - App Metadata
    static let appName = "FTC HUB"
    static let minimumIOSVersion = "18.0"
    
    // MARK: - API Routing
    static var baseURL: String { supabaseURL }
    static let apiVersion = "v1"
    
    // MARK: - Parts Catalog (Remote Manifest)
    /// URL to the versioned parts catalog manifest JSON.
    /// Set PARTS_CATALOG_MANIFEST_URL in Secrets.plist or environment to override.
    static var partsCatalogManifestURL: String? {
        let url = Secrets.value(.partsCatalogManifestURL, fallback: "")
        return url.isEmpty ? nil : url
    }
    
    /// Optional base URL for resolving relative image paths in the catalog manifest.
    /// Set PARTS_CATALOG_BASE_IMAGE_URL in Secrets.plist or environment to override.
    static var partsCatalogBaseImageURL: String? {
        let url = Secrets.value(.partsCatalogBaseImageURL, fallback: "")
        return url.isEmpty ? nil : url
    }
    
    /// Native Google Sign-In iOS client ID from Secrets.plist.
    /// Must match `GOOGLE_IOS_CLIENT_ID` in Xcode build settings / FTCHUB-Info.plist.
    static var googleIOSClientID: String? {
        guard let value = Secrets.optionalValue(.googleIOSClientID) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Google OAuth Web client ID used as serverClientID for Supabase token exchange.
    static var googleWebClientID: String? {
        guard let value = Secrets.optionalValue(.googleWebClientID) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Reversed client ID URL scheme required for Google Sign-In redirect handling.
    static var googleIOSReversedClientID: String? {
        guard let clientID = googleIOSClientID,
              clientID.hasSuffix(".apps.googleusercontent.com") else {
            return nil
        }
        let suffix = String(clientID.dropLast(".apps.googleusercontent.com".count))
        return "com.googleusercontent.apps.\(suffix)"
    }
}
