//
//  FTCHUBApp.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
import Supabase
#if canImport(UIKit)
import GoogleSignIn
#endif

@main
struct FTCHUBApp: App {
    @StateObject private var authService = AuthService()
    
    init() {
        TelemetryService.shared.configure()
        // Pre-initialize ResourcesService at app startup for instant resource availability
        _ = ResourcesService.shared

        #if canImport(UIKit)
        GoogleSignInHelper.configureIfNeeded()
        #endif
        
        // Configure navigation bar appearance for consistent styling across all views
        configureNavigationBarAppearance()
    }
    
    private func configureNavigationBarAppearance() {
        #if canImport(UIKit)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Use dynamic colors that adapt to light/dark mode
        appearance.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // cardBackground dark
            } else {
                return UIColor.white // cardBackground light
            }
        }
        
        appearance.shadowColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 0.3) // border dark
            } else {
                return UIColor(red: 0.88, green: 0.88, blue: 0.89, alpha: 0.3) // border light
            }
        }
        
        // Title text color
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // textPrimary dark
                } else {
                    return UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0) // textPrimary light
                }
            }
        ]
        
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // textPrimary dark
                } else {
                    return UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0) // textPrimary light
                }
            }
        ]
        
        // Apply to all navigation bar appearances
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure Tab Bar Appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
          tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        
        // Active and inactive tab colors
        let activeColor = UIColor(red: 0.91, green: 0.64, blue: 0.35, alpha: 1.0) // #E8A45A
        let inactiveColor = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0) // gray-500 approx
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = activeColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: activeColor]
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = inactiveColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: inactiveColor]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .withToast()
                .orientationReader()
                .detectLandscape()
                .onAppear {
                    // Suppress navigation bar warnings during orientation changes
                    if #available(iOS 16.0, *) {
                        // NavigationStack handles orientation changes better than NavigationView
                    }
                }
                .onOpenURL { url in
                    Task { @MainActor in
                        #if canImport(UIKit)
                        if GoogleSignInHelper.handleURL(url) {
                            return
                        }
                        #endif

                        // Phase 5: tab deep links (no auth tokens) — handled before Supabase auth URL parsing.
                        if url.scheme?.lowercased() == "ftchub",
                           url.host?.lowercased() == "tab" {
                            var path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
                            if path.isEmpty { path = "team" }
                            NotificationCenter.default.post(
                                name: .ftchubMainTabDeeplink,
                                object: nil,
                                userInfo: ["path": path]
                            )
                            TelemetryService.shared.logEvent("phase5_deeplink_tab", parameters: ["path": path])
                            return
                        }
                        
                        do {
                            // Get full URL string - absoluteString already includes hash fragment
                            let fullURLString = url.absoluteString
                            let fragment = url.fragment ?? ""
                            
                            DeepLinkLogger.logURL(url)
                            DeepLinkLogger.log("Deep link received (auth callback path)")
                        
                        // Check if this is an auth callback URL
                        let isAuthCallback = (url.scheme == "ftchub") || fullURLString.contains("auth-callback")
                        DeepLinkLogger.log(" isAuthCallback: \(isAuthCallback)")
                        
                        // Parse URL components for better detection
                        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                            DeepLinkLogger.log(" Failed to parse URL components")
                            return
                        }
                        
                        // Check query parameters
                        let queryParams = components.queryItems ?? []
                        let queryType = queryParams.first(where: { $0.name == "type" })?.value
                        let hasCode = queryParams.contains(where: { $0.name == "code" })
                        
                        // Parse hash fragment parameters (Supabase often puts tokens here)
                        var hashParams: [URLQueryItem] = []
                        var hashType: String? = nil
                        if !fragment.isEmpty {
                            let hashString = fragment.hasPrefix("#") ? String(fragment.dropFirst()) : fragment
                            if let hashComponents = URLComponents(string: "?\(hashString)") {
                                hashParams = hashComponents.queryItems ?? []
                                hashType = hashParams.first(where: { $0.name == "type" })?.value
                            }
                        }
                        
                        // Check hash fragment for recovery indicators
                        let hashContainsRecovery = fragment.contains("type=recovery") || 
                                                   fragment.contains("type%3Drecovery") ||
                                                   fragment.contains("recovery") ||
                                                   hashType?.lowercased() == "recovery"
                        let hashContainsAccessToken = fragment.contains("access_token") || 
                                                      fragment.contains("access_token=") ||
                                                      hashParams.contains(where: { $0.name == "access_token" })
                        let hashContainsSignup = fragment.contains("type=signup") || 
                                               fragment.contains("type%3Dsignup") ||
                                               fragment.contains("signup") ||
                                               hashType?.lowercased() == "signup"
                        let hashContainsCode = fragment.contains("code=") || hashParams.contains(where: { $0.name == "code" })
                        
                        // Check for password reset FIRST (before verification)
                        // Password reset URLs typically have:
                        // 1. type=recovery in query parameters or hash fragment
                        // 2. A "code" parameter (Supabase exchanges this for a recovery session)
                        // 3. access_token in hash with recovery type
                        let lowercasedURL = fullURLString.lowercased()
                        
                        // Enhanced password reset detection - check multiple indicators
                        let isPasswordReset = queryType == "recovery" ||
                                            queryType?.lowercased() == "recovery" ||
                                            hashType?.lowercased() == "recovery" ||
                                            lowercasedURL.contains("type=recovery") ||
                                            lowercasedURL.contains("type%3drecovery") ||
                                            lowercasedURL.contains("#type=recovery") ||
                                            (hashContainsRecovery && (hashContainsAccessToken || hashContainsCode)) ||
                                            // If URL has "code" parameter and is auth-callback (and not signup), likely password reset
                                            (hasCode && isAuthCallback && !hashContainsSignup && !lowercasedURL.contains("signup")) ||
                                            // Check for password reset keywords in URL
                                            (lowercasedURL.contains("password") && lowercasedURL.contains("reset")) ||
                                            // Check for recovery token in URL
                                            (lowercasedURL.contains("recovery") && (hashContainsAccessToken || hashContainsCode))
                        
                        // Check for email verification
                        let isVerificationURL = queryType == "signup" ||
                                              fullURLString.contains("type=signup") ||
                                              fullURLString.contains("token_hash") ||
                                              fullURLString.contains("verify") ||
                                              hashContainsSignup
                        
                        DeepLinkLogger.log("URL analysis: isAuthCallback=\(isAuthCallback) isPasswordReset=\(isPasswordReset) isVerificationURL=\(isVerificationURL)")
                        
                        // Store email from URL if available before handling
                        let emailFromURL = Self.extractEmailFromURL(url)
                        
                        // Handle the auth URL - this processes Supabase auth callbacks
                        // Note: handle() processes the URL and extracts tokens from hash fragments
                        // It may not throw, but errors can occur during session establishment
                        do {
                            SupabaseService.shared.client.auth.handle(url)
                            DeepLinkLogger.log(" Auth URL handled successfully")
                            
                            // Small delay to let auth handle complete and session to be established
                            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds - longer delay for password reset
                        } catch {
                            DeepLinkLogger.log(" Warning during auth.handle (non-fatal): \(error.localizedDescription)")
                            // Continue processing even if handle had issues - session might still be established
                        }
                        
                        // FALLBACK: After handling URL, check if we have a recovery session
                        // This helps detect password reset even if URL doesn't have explicit indicators
                        var detectedPasswordReset = isPasswordReset
                        if !detectedPasswordReset && isAuthCallback && hasCode {
                            // Check if we have a session after handling the code
                            do {
                                let session = try await SupabaseService.shared.client.auth.session
                                let user = session.user
                                DeepLinkLogger.log(" Checking session type after code exchange...")
                                DeepLinkLogger.log("- User ID: \(user.id)")
                                DeepLinkLogger.log("- Email: \(user.email ?? "none")")
                                
                                // If we have a session but user is not fully authenticated (no profile loaded),
                                // and it's not a signup, it's likely a password reset recovery session
                                // Recovery sessions allow password updates
                                if !hashContainsSignup && !lowercasedURL.contains("signup") {
                                    DeepLinkLogger.log("- Detected potential password reset session (code parameter + auth-callback)")
                                    detectedPasswordReset = true
                                }
                            } catch {
                                DeepLinkLogger.log("- No session found after code exchange")
                            }
                        }
                        
                        // Handle different types of redirects - CHECK PASSWORD RESET FIRST
                        if detectedPasswordReset {
                            DeepLinkLogger.log(" Checking if password reset was successful")
                            
                            // Check if we have a valid session (user is authenticated/verified)
                            do {
                                // Add a small delay to ensure auth.handle has fully processed
                                // Password reset URLs need more time to establish the recovery session
                                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second for password reset
                                
                                let session = try await SupabaseService.shared.client.auth.session
                                let user = session.user
                                
                                DeepLinkLogger.log(" Session found - user is authenticated for password reset")
                                DeepLinkLogger.log(" Email: \(user.email ?? "unknown")")
                                DeepLinkLogger.log(" Email verified: \(user.emailConfirmedAt != nil ? "YES" : "NO")")
                                
                                // SECURITY CHECK 1: Email must be verified
                                guard user.emailConfirmedAt != nil else {
                                    DeepLinkLogger.log(" Password reset BLOCKED: Email not verified")
                                    
                                    // Sign out the temporary session
                                    try? await SupabaseService.shared.client.auth.signOut()
                                    
                                    // Show error message to user
                                    await MainActor.run {
                                        authService.isShowingPasswordResetForm = false
                                        authService.isShowingEmailVerification = false
                                        authService.isShowingSignUpSuccess = false
                                        authService.isShowingPasswordResetSuccess = false
                                        authService.errorMessage = "Password reset is only available for verified accounts. Please verify your email address first by clicking the verification link sent to your inbox."
                                    }
                                    
                                    return
                                }
                                
                                // SECURITY CHECK 2: Database field must allow password reset
                                // Load user profile to check password_reset_verified field
                                // Note: If migration hasn't been run, field won't exist - we'll allow reset if email is verified
                                var allowPasswordReset = true
                                var databaseCheckFailed = false
                                
                                do {
                                    DeepLinkLogger.log(" Attempting to load profile from database for user: \(user.id)")
                                    let profile: Profile = try await SupabaseService.shared.client
                                        .from("profiles")
                                        .select()
                                        .eq("id", value: user.id)
                                        .single()
                                        .execute()
                                        .value
                                    
                                    DeepLinkLogger.log(" Profile loaded successfully")
                                    
                                    // Check if password_reset_verified field exists and is set
                                    // If field is nil, it means either:
                                    // 1. Migration hasn't been run (field doesn't exist in DB)
                                    // 2. Field exists but is NULL
                                    // In both cases, we'll default to allowing reset if email is verified
                                    if let passwordResetVerified = profile.passwordResetVerified {
                                        DeepLinkLogger.log(" password_reset_verified field value: \(passwordResetVerified)")
                                        if !passwordResetVerified {
                                            DeepLinkLogger.log(" Password reset BLOCKED: password_reset_verified is false")
                                            allowPasswordReset = false
                                        } else {
                                            DeepLinkLogger.log(" password_reset_verified is true")
                                        }
                                    } else {
                                        DeepLinkLogger.log("password_reset_verified is nil — blocking reset until profile flag is set")
                                        allowPasswordReset = false
                                    }
                                    
                                } catch {
                                    DeepLinkLogger.log("Could not load profile for password reset check")
                                    databaseCheckFailed = true
                                    allowPasswordReset = false
                                }
                                
                                // If database check explicitly blocked password reset, show error
                                if !allowPasswordReset {
                                    DeepLinkLogger.log(" Password reset BLOCKED by database check")
                                    
                                    // Sign out the temporary session
                                    try? await SupabaseService.shared.client.auth.signOut()
                                    
                                    // Show error message to user
                                    await MainActor.run {
                                        authService.isShowingPasswordResetForm = false
                                        authService.isShowingEmailVerification = false
                                        authService.isShowingSignUpSuccess = false
                                        authService.isShowingPasswordResetSuccess = false
                                        authService.errorMessage = "Password reset is not enabled for your account. Please contact your team administrator to enable password reset."
                                    }
                                    
                                    return
                                }
                                
                                if databaseCheckFailed {
                                    DeepLinkLogger.log("Password reset blocked — profile verification required")
                                } else {
                                    DeepLinkLogger.log("Password reset allowed after verification checks")
                                }
                                
                                // User is verified/authenticated - show password reset form
                                DeepLinkLogger.log(" Setting state to show password reset form...")
                                await MainActor.run {
                                    // Clear any other states first
                                    DeepLinkLogger.log("- Clearing other states...")
                                    authService.isShowingEmailVerification = false
                                    authService.isShowingSignUpSuccess = false
                                    authService.isShowingPasswordResetSuccess = false
                                    authService.errorMessage = nil // Clear any previous errors
                                    
                                    // IMPORTANT: Set isAuthenticated to false to ensure ContentView
                                    // shows the password reset form instead of authenticated views
                                    // The user is temporarily authenticated by Supabase for password reset,
                                    // but we don't want to show the main app view
                                    DeepLinkLogger.log("- Setting isAuthenticated = false")
                                    authService.isAuthenticated = false
                                    
                                    // Show password reset form to set new password
                                    DeepLinkLogger.log("- Setting isShowingPasswordResetForm = true")
                                    authService.isShowingPasswordResetForm = true
                                    
                                    DeepLinkLogger.log(" State updated:")
                                    DeepLinkLogger.log("- isShowingPasswordResetForm: \(authService.isShowingPasswordResetForm)")
                                    DeepLinkLogger.log("- isAuthenticated: \(authService.isAuthenticated)")
                                    DeepLinkLogger.log("- isShowingEmailVerification: \(authService.isShowingEmailVerification)")
                                }
                                
                                // Give SwiftUI time to process the state change
                                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                                
                                // Verify state was set correctly
                                await MainActor.run {
                                    DeepLinkLogger.log(" Final state verification:")
                                    DeepLinkLogger.log("- isShowingPasswordResetForm: \(authService.isShowingPasswordResetForm)")
                                    DeepLinkLogger.log("- isAuthenticated: \(authService.isAuthenticated)")
                                    
                                    if !authService.isShowingPasswordResetForm {
                                        DeepLinkLogger.log(" ERROR: isShowingPasswordResetForm is still false after setting!")
                                    } else {
                                        DeepLinkLogger.log(" Password reset form should now be visible")
                                    }
                                }
                                
                                DeepLinkLogger.log("═══════════════════════════════════════")
                                return
                            } catch let sessionError {
                                DeepLinkLogger.log(" No valid session found - password reset link may be invalid or expired")
                                DeepLinkLogger.log("Error: \(sessionError.localizedDescription)")
                                
                                // Try to get more details about the error
                                if let nsError = sessionError as NSError? {
                                    DeepLinkLogger.log("Error domain: \(nsError.domain)")
                                    DeepLinkLogger.log("Error code: \(nsError.code)")
                                    DeepLinkLogger.log("Error userInfo: \(nsError.userInfo)")
                                }
                                
                                // Check if it's a sessionMissing error (expected if link isn't processed yet)
                                let errorString = sessionError.localizedDescription.lowercased()
                                if errorString.contains("sessionMissing") || errorString.contains("no session") {
                                    // Session might not be established yet - try one more time after a delay
                                    DeepLinkLogger.log(" Session missing - retrying after delay...")
                                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                                    
                                    do {
                                        let retrySession = try await SupabaseService.shared.client.auth.session
                                        let retryUser = retrySession.user
                                        DeepLinkLogger.log(" Session found on retry - continuing with password reset")
                                        
                                        // If we got here, we have a session - continue with the password reset flow
                                        // This will skip the earlier session check and go directly to showing the form
                                        // We'll handle this by setting the flag and continuing
                                        await MainActor.run {
                                            authService.isAuthenticated = false
                                            authService.isShowingPasswordResetForm = true
                                            authService.errorMessage = nil
                                        }
                                        return
                                    } catch {
                                        // Still no session after retry
                                        DeepLinkLogger.log(" Still no session after retry")
                                    }
                                }
                                
                                // No session = not verified, show error
                                await MainActor.run {
                                    authService.isShowingPasswordResetForm = false
                                    authService.isShowingEmailVerification = false
                                    authService.isShowingSignUpSuccess = false
                                    authService.isShowingPasswordResetSuccess = false
                                    authService.errorMessage = "Unable to process password reset link. The link may be invalid, expired, or already used. Please request a new password reset link."
                                }
                                return
                            }
                        }
                        
                        // IMPORTANT: Only check auth status if we didn't handle password reset
                        // Password reset returns early, so this won't run for password reset
                        // For verification, check auth status first
                        if !detectedPasswordReset {
                            await authService.checkAuthStatus()
                            
                            // After OAuth callback, check if user is authenticated and has profile
                            // If authenticated but no profile, create one from OAuth data
                            if authService.isAuthenticated && authService.currentUser == nil {
                                // User authenticated via OAuth but profile doesn't exist
                                // Try to create profile from OAuth user data
                                do {
                                    let session = try await SupabaseService.shared.client.auth.session
                                    let user = session.user
                                    
                                    // Extract name from user metadata (OAuth providers may provide this)
                                    // userMetadata values are AnyJSON, need to extract string properly
                                    let fullNameValue = user.userMetadata["full_name"] ?? user.userMetadata["name"]
                                    let fullName: String
                                    if let jsonValue = fullNameValue {
                                        // Extract string from AnyJSON using pattern matching
                                        switch jsonValue {
                                        case .string(let str):
                                            fullName = str
                                        default:
                                            // Try to get string representation
                                            fullName = String(describing: jsonValue).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                                        }
                                    } else {
                                        fullName = ""
                                    }
                                    let nameParts = fullName.split(separator: " ").map(String.init)
                                    let extractedFirstName = nameParts.first ?? ""
                                    let extractedLastName = nameParts.dropFirst().joined(separator: " ")
                                    
                                    // Create profile via RPC
                                    _ = try await SupabaseService.shared.client.rpc("create_user_profile", params: [
                                        "p_email": user.email ?? "",
                                        "p_first_name": extractedFirstName,
                                        "p_last_name": extractedLastName,
                                        "p_user_id": user.id.uuidString
                                    ]).execute()
                                    
                                    // Reload profile
                                    await authService.checkAuthStatus()
                                } catch {
                                    DeepLinkLogger.log(" Failed to create profile for OAuth user: \(error)")
                                    // Profile might already exist, try to load it
                                    await authService.checkAuthStatus()
                                }
                            }
                        }
                        
                        if isVerificationURL {
                            DeepLinkLogger.log(" Showing email verification view")
                            // Show email verification view
                            var email = emailFromURL ?? authService.verificationEmail
                            
                            // If still no email, try to get from current session
                            if email.isEmpty {
                                if let session = try? await SupabaseService.shared.client.auth.session {
                                    email = session.user.email ?? ""
                                }
                            }
                            
                            if !email.isEmpty {
                                authService.verificationEmail = email
                            }
                            // Always show verification view when verification URL is clicked
                            authService.isShowingEmailVerification = true
                        } else if isAuthCallback && !detectedPasswordReset {
                            // Generic auth callback - could be OAuth or email verification
                            // If user is authenticated, don't show verification view
                            if authService.isAuthenticated {
                                DeepLinkLogger.log(" OAuth authentication successful")
                                // User is authenticated, no need to show verification
                            } else {
                                // Show verification view for email verification
                            var email = emailFromURL ?? authService.verificationEmail
                            if email.isEmpty {
                                if let session = try? await SupabaseService.shared.client.auth.session {
                                    email = session.user.email ?? ""
                                }
                            }
                            if !email.isEmpty {
                                authService.verificationEmail = email
                            }
                            authService.isShowingEmailVerification = true
                            }
                        }
                        } catch {
                            // Catch any unexpected errors during URL processing
                            DeepLinkLogger.log(" ERROR PROCESSING URL ")
                            DeepLinkLogger.log("Error: \(error.localizedDescription)")
                            if let nsError = error as NSError? {
                                DeepLinkLogger.log("Domain: \(nsError.domain)")
                                DeepLinkLogger.log("Code: \(nsError.code)")
                                DeepLinkLogger.log("UserInfo: \(nsError.userInfo)")
                            }
                            
                            // Show a helpful error message to the user
                            await MainActor.run {
                                authService.errorMessage = "Unable to process the link. Please ensure you're using a valid password reset link. If the problem persists, try requesting a new password reset link."
                            }
                        }
                    }
                }
                .task {
                    await authService.checkAuthStatus()
                }
        }
    }
    
    // Helper function to extract email from URL query parameters
    static private func extractEmailFromURL(_ url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        // Check for email in query parameters
        return queryItems.first(where: { $0.name == "email" })?.value
    }
}
