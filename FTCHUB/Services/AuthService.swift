//
//  AuthService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: Profile?
    @Published var isAuthenticated = false
    @Published var isGuestMode = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var isShowingEmailVerification = false
    @Published var verificationEmail: String = ""
    @Published var isShowingSignUpSuccess = false
    @Published var signUpEmail: String = ""
    @Published var isShowingPasswordResetSuccess = false
    @Published var isShowingPasswordResetForm = false
    
    private let supabase = SupabaseService.shared.client
    
    // MARK: - Guest Mode
    func enableGuestMode() {
        enterGuestMode()
    }

    func enterGuestMode() {
        isShowingSignUpSuccess = false
        isShowingEmailVerification = false
        isShowingPasswordResetForm = false
        isShowingPasswordResetSuccess = false
        isGuestMode = true
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
        infoMessage = nil
    }
    
    func disableGuestMode() {
        isGuestMode = false
    }
    
    var canAccessTeamFeatures: Bool {
        return isAuthenticated && !isGuestMode
    }
    
    init() {
        // Don't automatically check auth status in init to prevent preview crashes
        // Auth status will be checked when the app actually starts
        
        // Set up mock data for previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            self.currentUser = Profile.sample
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Authentication Status
    func checkAuthStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.session
            await loadUserProfile(userId: session.user.id)
        } catch {
            // sessionMissing is expected when user is not logged in - not an error
            if !error.localizedDescription.contains("sessionMissing") {
                DebugLog.log("Auth check failed: \(error)")
            }
            currentUser = nil
            isAuthenticated = false
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            let user = session.user
            
            // Check if email is verified
            guard user.emailConfirmedAt != nil else {
                // User is not verified - sign them out and show error
                try? await supabase.auth.signOut()
                errorMessage = "Please verify your email address before signing in. Check your inbox for the verification link."
                throw NSError(domain: "AuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Email not verified"])
            }
            
            // Email is verified - proceed with loading profile
            await loadUserProfile(userId: user.id)
            
            // Disable guest mode on successful sign in
            disableGuestMode()
            
            // Check if profile was loaded successfully
            if currentUser == nil {
                // Profile not found - show generic error message for security
                try? await supabase.auth.signOut()
                errorMessage = "Incorrect username or password."
                isAuthenticated = false
                throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
            }
        } catch {
            // If error is already set (from email verification check or profile check), don't override it
            if errorMessage == nil {
                // For security, show generic error message instead of actual error details
                errorMessage = "Incorrect username or password."
            }
            throw error
        }
    }
    

    // MARK: - OAuth Sign-In
    #if canImport(UIKit)
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let credentials = try await GoogleSignInHelper.signIn(presenting: viewController)
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .google,
                    idToken: credentials.idToken,
                    accessToken: credentials.accessToken
                )
            )
            await finishOAuthSignIn(session: session)
        } catch let error as GoogleSignInHelper.Error {
            if case .cancelled = error { return }
            errorMessage = error.localizedDescription
            throw error
        } catch {
            errorMessage = oauthErrorMessage(for: error)
            throw error
        }
    }
    #endif

    func completeAppleSignIn(idToken: String, nonce: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            await finishOAuthSignIn(session: session)
        } catch {
            errorMessage = oauthErrorMessage(for: error)
            throw error
        }
    }

    private func finishOAuthSignIn(session: Session) async {
        await ensureOAuthProfile(for: session.user)
        await loadUserProfile(userId: session.user.id)
    }

    private func ensureOAuthProfile(for user: User) async {
        do {
            let existing: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: user.id)
                .execute()
                .value
            if !existing.isEmpty { return }

            var firstName = ""
            var lastName = ""
            let fullNameValue = user.userMetadata["full_name"] ?? user.userMetadata["name"]
            if case .string(let fullName) = fullNameValue {
                let parts = fullName.split(separator: " ").map(String.init)
                firstName = parts.first ?? ""
                lastName = parts.dropFirst().joined(separator: " ")
            }

            _ = try await supabase.rpc("create_user_profile", params: [
                "p_email": user.email ?? "",
                "p_first_name": firstName,
                "p_last_name": lastName,
                "p_user_id": user.id.uuidString
            ]).execute()
        } catch {
            DebugLog.log("OAuth profile ensure failed: \(error.localizedDescription)", category: "Auth")
        }
    }

    private func oauthErrorMessage(for error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("provider is not enabled") {
            return "This sign-in method is not enabled yet. Please use email sign-in or contact support."
        }
        if message.contains("unacceptable audience") || message.contains("invalid claim") {
            return "Google Sign-In is misconfigured. Add your Web OAuth client ID to Secrets.plist and configure the Google provider in Supabase."
        }
        if message.contains("nonce") {
            return "Google Sign-In failed token validation. Enable \"Skip nonce check\" for Google in the Supabase dashboard."
        }
        return "Sign-in failed. Please try again."
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Sanitize email
        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let redirectURL = Config.emailVerificationSuccessURL
        
        do {
            // Sign up user with email redirect URL for verification
            // The redirect URL should point to your hosted email-verification-success.html page
            // You need to host this file and update the URL in Supabase dashboard > Authentication > URL Configuration
            let session = try await supabase.auth.signUp(
                email: sanitizedEmail,
                password: password,
                redirectTo: URL(string: redirectURL)
            )
            let user = session.user
            
            DebugLog.log(" SignUp completed for user: \(user.id), email verified: \(user.emailConfirmedAt != nil)")
            
            // CRITICAL: ALWAYS ensure verification email is sent if user is not verified
            // This is especially important when an account was deleted but auth user still exists
            // Supabase might not automatically send email for existing users
            if user.emailConfirmedAt == nil {
                DebugLog.log(" User email not verified - forcing verification email to be sent")
                DebugLog.log(" Email: \(sanitizedEmail)")
                DebugLog.log(" Redirect URL: \(redirectURL)")
                
                // Wait a moment to ensure signUp transaction is complete
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second - longer wait
                
                var emailSent = false
                var lastError: Error?
                var allErrors: [String] = []
                
                // Method 1: Try resend with signup type (most reliable)
                if !emailSent {
                    do {
                        DebugLog.log(" Method 1: Attempting resend with signup type...")
                        try await supabase.auth.resend(
                            email: sanitizedEmail,
                            type: .signup
                        )
                        DebugLog.log(" Method 1 SUCCESS: Verification email sent via resend")
                        emailSent = true
                    } catch let error1 {
                        let errorMsg = "Method 1 failed: \(error1.localizedDescription)"
                        DebugLog.log(" \(errorMsg)")
                        allErrors.append(errorMsg)
                        lastError = error1
                        
                        // Log detailed error info
                        if let nsError = error1 as NSError? {
                            DebugLog.log("   Error domain: \(nsError.domain)")
                            DebugLog.log("   Error code: \(nsError.code)")
                            DebugLog.log("   Error userInfo: \(nsError.userInfo)")
                        }
                    }
                }
                
                // Method 2: Try signUp again with email confirmation disabled temporarily
                // This sometimes forces Supabase to send the email
                if !emailSent {
                    do {
                        DebugLog.log(" Method 2: Attempting signUp retry to trigger email...")
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                        let _ = try await supabase.auth.signUp(
                            email: sanitizedEmail,
                            password: password,
                            redirectTo: URL(string: redirectURL)
                        )
                        DebugLog.log(" Method 2 SUCCESS: Verification email triggered via signUp retry")
                        emailSent = true
                    } catch let error2 {
                        let errorMsg = "Method 2 failed: \(error2.localizedDescription)"
                        DebugLog.log(" \(errorMsg)")
                        allErrors.append(errorMsg)
                        lastError = error2
                    }
                }
                
                // Method 3: Try resend with email change type (as last resort)
                if !emailSent {
                    do {
                        DebugLog.log(" Method 3: Attempting resend with email change type...")
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                        try await supabase.auth.resend(
                            email: sanitizedEmail,
                            type: .emailChange
                        )
                        DebugLog.log(" Method 3 SUCCESS: Verification email sent via email change resend")
                        emailSent = true
                    } catch let error3 {
                        let errorMsg = "Method 3 failed: \(error3.localizedDescription)"
                        DebugLog.log(" \(errorMsg)")
                        allErrors.append(errorMsg)
                        lastError = error3
                    }
                }
                
                // Final summary
                if !emailSent {
                    DebugLog.log(" ALL EMAIL SENDING METHODS FAILED ")
                    DebugLog.log(" Email address: \(sanitizedEmail)")
                    DebugLog.log(" Redirect URL: \(redirectURL)")
                    DebugLog.log(" All errors:")
                    for (index, error) in allErrors.enumerated() {
                        DebugLog.log("   \(index + 1). \(error)")
                    }
                    if let finalError = lastError {
                        DebugLog.log(" Final error details: \(finalError)")
                    }
                    DebugLog.log("")
                    DebugLog.log(" DIAGNOSTIC STEPS:")
                    DebugLog.log("1. Check Supabase Dashboard → Authentication → Settings")
                    DebugLog.log("   - Ensure 'Enable Email Signup' is ON")
                    DebugLog.log("   - Ensure 'Enable Email Confirmations' is ON")
                    DebugLog.log("   - Check SMTP settings (default has rate limits)")
                    DebugLog.log("2. Check Supabase Dashboard → Authentication → Logs")
                    DebugLog.log("   - Look for email sending errors")
                    DebugLog.log("   - Check for rate limit errors")
                    DebugLog.log("3. Verify redirect URL is added to:")
                    DebugLog.log("   - Supabase Dashboard → Authentication → URL Configuration → Redirect URLs")
                    DebugLog.log("4. Check email spam folder")
                    DebugLog.log("5. Try with different email address")
                    DebugLog.log("6. Check Supabase auth logs for delivery errors")
                    DebugLog.log("")
                    // Continue anyway - profile creation is more important
                    // User can request email resend from the signup success screen
                } else {
                    DebugLog.log(" Verification email successfully sent via one of the methods ")
                }
            } else {
                DebugLog.log(" User email is already verified")
            }
            
            // Create profile using RPC function (bypasses RLS with SECURITY DEFINER)
            // This works even if the user isn't fully authenticated yet (e.g., email verification pending)
            // Note: RPC params must be strings, but the SQL function accepts UUID and converts it
            do {
                // PostgREST orders parameters alphabetically, so match the function signature order
                _ = try await supabase.rpc("create_user_profile", params: [
                    "p_email": email,
                    "p_first_name": firstName,
                    "p_last_name": lastName,
                    "p_user_id": user.id.uuidString  // Convert to string for RPC params
                ]).execute()
                
                DebugLog.log(" Profile created via RPC function for user: \(user.id)")
                
                // Always show signup success view - don't auto-authenticate
                // User must verify email before they can sign in
                await MainActor.run {
                    isShowingSignUpSuccess = true
                    signUpEmail = sanitizedEmail
                    errorMessage = nil
                    // Don't set isAuthenticated = true - user needs to verify email first
                }
                return  // Success - show signup success view
            } catch let rpcError {
                // If RPC fails, log the error and try direct insert (might work if user is authenticated)
                DebugLog.log(" RPC function failed: \(rpcError)")
                DebugLog.log(" Error details: \(rpcError.localizedDescription)")
                if let nsError = rpcError as NSError? {
                    DebugLog.log(" Error domain: \(nsError.domain), code: \(nsError.code)")
                    DebugLog.log(" Error userInfo: \(nsError.userInfo)")
                }
                do {
                    let profile = Profile(
                        id: user.id,
                        teamId: nil,
                        role: .readonly,
                        teamRole: nil,
                        firstName: firstName,
                        lastName: lastName,
                        email: email,
                        phone: nil,
                        grade: nil,
                        memberRole: nil,
                        experienceBadges: [],
                        emergencyContactName: nil,
                        emergencyContactPhone: nil,
                        passwordResetVerified: false,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    try await supabase
                        .from("profiles")
                        .insert(profile)
                        .execute()
                    
                    DebugLog.log(" Profile inserted directly for user: \(user.id)")
                    
                    // Always show signup success view - don't auto-authenticate
                    await MainActor.run {
                        isShowingSignUpSuccess = true
                        signUpEmail = sanitizedEmail
                        errorMessage = nil
                    }
                    return  // Success - show signup success view
                } catch let insertError {
                    // If both fail, wait for trigger to create it, then update it
                    DebugLog.log(" Direct insert also failed, waiting for trigger: \(insertError.localizedDescription)")
                    
                    // Wait a bit for the trigger to create the profile
                    try await Task.sleep(nanoseconds: 1_500_000_000) // Wait 1.5 seconds for trigger
                    
                    // Try to update the profile with first_name and last_name
                    // Use a simple update that only sets the names (works with RLS)
                    do {
                        try await supabase
                            .from("profiles")
                            .update([
                                "first_name": firstName,
                                "last_name": lastName
                            ])
                            .eq("id", value: user.id)
                            .execute()
                        
                        DebugLog.log(" Profile names updated after trigger creation")
                        
                        // Load the updated profile
                        await loadUserProfile(userId: user.id)
                        
                        if currentUser == nil {
                            // If still not found, try one more time after a longer wait
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                            await loadUserProfile(userId: user.id)
                        }
                        
                        DebugLog.log(" Profile names updated after trigger creation")
                    } catch let updateError {
                        DebugLog.log(" Failed to update profile names: \(updateError.localizedDescription)")
                        // Continue anyway - profile exists, names can be updated later
                    }
                    
                    // Always show signup success view - don't auto-authenticate
                    await MainActor.run {
                        isShowingSignUpSuccess = true
                        signUpEmail = sanitizedEmail
                        errorMessage = nil
                    }
                    return  // Success - show signup success view
                }
            }
        } catch let signUpError {
            // Check if error is due to user already existing
            let errorString = signUpError.localizedDescription.lowercased()
            if errorString.contains("user already registered") || 
               errorString.contains("already exists") ||
               errorString.contains("already registered") ||
               errorString.contains("email address is already registered") {
                // User already exists - try multiple methods to send verification email
                DebugLog.log(" User already exists error - attempting to send verification email with multiple methods")
                
                var emailSent = false
                var lastError: Error?
                
                // Wait a moment before trying
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Method 1: Try resend with signup type
                if !emailSent {
                    do {
                        DebugLog.log(" Method 1: Attempting resend with signup type...")
                        try await supabase.auth.resend(
                            email: sanitizedEmail,
                            type: .signup
                        )
                        DebugLog.log(" Verification email sent via resend (method 1)")
                        emailSent = true
                    } catch let error1 {
                        DebugLog.log(" Method 1 failed: \(error1.localizedDescription)")
                        lastError = error1
                    }
                }
                
                // Method 2: Try signUp again (sometimes triggers email even if user exists)
                if !emailSent {
                    do {
                        DebugLog.log(" Method 2: Attempting signUp retry...")
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        let _ = try await supabase.auth.signUp(
                            email: sanitizedEmail,
                            password: password,
                            redirectTo: URL(string: redirectURL)
                        )
                        DebugLog.log(" Verification email triggered via signUp retry (method 2)")
                        emailSent = true
                    } catch let error2 {
                        DebugLog.log(" Method 2 failed: \(error2.localizedDescription)")
                        lastError = error2
                    }
                }
                
                // Method 3: Try resend with email change type
                if !emailSent {
                    do {
                        DebugLog.log(" Method 3: Attempting resend with email change type...")
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        try await supabase.auth.resend(
                            email: sanitizedEmail,
                            type: .emailChange
                        )
                        DebugLog.log(" Verification email sent via email change resend (method 3)")
                        emailSent = true
                    } catch let error3 {
                        DebugLog.log(" Method 3 failed: \(error3.localizedDescription)")
                        lastError = error3
                    }
                }
                
                if emailSent {
                    DebugLog.log(" Verification email successfully sent via one of the methods")
                } else {
                    DebugLog.log(" All methods failed. Last error: \(lastError?.localizedDescription ?? "unknown")")
                }
                
                // Show signup success view regardless - user should check their email
                // Even if all methods failed, the user might have received an email
                await MainActor.run {
                    isShowingSignUpSuccess = true
                    signUpEmail = sanitizedEmail
                    errorMessage = nil
                }
                return  // Success - show signup success view
            } else {
                // Other error - show it
                errorMessage = signUpError.localizedDescription
                throw signUpError
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            disableGuestMode() // Ensure guest mode is also disabled on sign out
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // Use the app deep link scheme for password reset redirect
        // This ensures the link opens directly in the app when clicked from email
        // Format: ftchub://auth-callback?type=recovery&code=...
        let redirectURL = Config.supabaseEmailRedirectURL
        
        do {
            try await supabase.auth.resetPasswordForEmail(
                email,
                redirectTo: URL(string: redirectURL)
            )
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Update Password
    func updatePassword(newPassword: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Email Verification
    func resendEmailVerification(email: String) async throws {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }
        
        let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        do {
            try await supabase.auth.resend(
                email: sanitizedEmail,
                type: .signup
            )
            infoMessage = "Verification email sent to \(sanitizedEmail). Please check your inbox."
        } catch {
            errorMessage = "Failed to resend verification email. Please try again."
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func loadUserProfile(userId: UUID) async {
        do {
            let response: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            guard let profile = response.first else {
                DebugLog.log(" Profile not found for user ID: \(userId)")
                // Don't set error message here if we're just verifying - only if it's a critical load
                // For signup scenarios, the profile might exist but not be readable yet due to RLS
                if currentUser == nil {
                    // Check if this might be a signup scenario - don't show error, just log it
                    DebugLog.log(" Profile not found - might be a signup scenario where profile exists but isn't readable yet")
                    // Don't set errorMessage here - let the caller handle it
                    isAuthenticated = false
                }
                return
            }
            
            DebugLog.log(" Profile loaded successfully for user: \(userId)")
            
            // If email is verified but password_reset_verified is not set, update it
            // This ensures password reset is enabled for verified users
            if let session = try? await supabase.auth.session,
               session.user.emailConfirmedAt != nil,
               profile.passwordResetVerified != true {
                DebugLog.log(" Email is verified but password_reset_verified is not true - updating profile")
                do {
                    try await supabase
                        .from("profiles")
                        .update(["password_reset_verified": true])
                        .eq("id", value: userId)
                        .execute()
                    
                    // Reload profile to get updated value
                    let updatedResponse: [Profile] = try await supabase
                        .from("profiles")
                        .select()
                        .eq("id", value: userId)
                        .execute()
                        .value
                    
                    if let updatedProfile = updatedResponse.first {
                        DebugLog.log(" Updated password_reset_verified to true")
                        currentUser = updatedProfile
                    } else {
                        currentUser = profile
                    }
                } catch {
                    DebugLog.log(" Failed to update password_reset_verified: \(error)")
                    // Continue with existing profile even if update fails
                    currentUser = profile
                }
            } else {
                currentUser = profile
            }
            
            // Disable guest mode on successful authentication
            disableGuestMode()
            isAuthenticated = true
            errorMessage = nil
        } catch {
            let errorString = error.localizedDescription
            DebugLog.log(" Failed to load profile for user \(userId): \(errorString)")
            
            // Only set error if we don't already have a current user
            // This prevents overwriting a valid profile with an error
            if currentUser == nil {
                errorMessage = "Failed to load user profile: \(errorString)"
                isAuthenticated = false
            } else {
                // If we already have a profile, this is just a verification failure
                // Log it but don't break the user's session
                DebugLog.log(" Profile verification failed, but user is already authenticated")
            }
        }
    }
    
    // MARK: - Profile Updates
    func updateProfile(_ profile: Profile) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("profiles")
                .update(profile)
                .eq("id", value: profile.id)
                .execute()
            
            currentUser = profile
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Refresh Profile
    func refreshCurrentProfile() async {
        guard let userId = supabase.auth.currentUser?.id else { return }
        await loadUserProfile(userId: userId)
    }
    
    // MARK: - Account Deletion
    func deleteAccount() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        guard let userId = supabase.auth.currentUser?.id else {
            errorMessage = "You must be signed in to delete your account."
            throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        do {
            // Delete user profile and associated data from database
            try await supabase
                .from("profiles")
                .delete()
                .eq("id", value: userId)
                .execute()
            
            DebugLog.log(" Profile deleted successfully for user: \(userId)")
        
            // Delete local storage data
            LocalStorage.shared.clearAllData()
            
            // Clear all app storage flags including onboarding
            UserDefaults.standard.removeObject(forKey: "ftchub.hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "ftchub.legalConsentAccepted")
            
            // Try to delete auth user via Edge Function (if configured)
            // This allows automatic cleanup without manual dashboard deletion
            do {
                try await deleteAuthUserViaEdgeFunction(userId: userId)
                DebugLog.log(" Auth user deleted via Edge Function")
            } catch {
                // If Edge Function fails or isn't configured, continue with sign out
                // User will need to manually delete auth user from dashboard if they want to re-register
                DebugLog.log(" Edge Function deletion failed (this is OK if not configured): \(error.localizedDescription)")
                // Don't throw - allow deletion to continue
            }
            
            // Sign out (this must happen even if Edge Function fails)
            try await supabase.auth.signOut()
            
            // Clear all state
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Edge Function Helpers
    /// Deletes the auth user via Supabase Edge Function
    /// This requires the Edge Function to be deployed and configured
    /// If the Edge Function is not available, this will fail gracefully
    private func deleteAuthUserViaEdgeFunction(userId: UUID) async throws {
        // Get the current session token for authentication
        guard let session = try? await supabase.auth.session else {
            throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])
        }
        
        // Call the Edge Function
        let functionURL = "\(Config.supabaseURL)/functions/v1/delete-auth-user"
        
        guard let url = URL(string: functionURL) else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Edge Function URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let requestBody = ["userId": userId.uuidString]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
}
