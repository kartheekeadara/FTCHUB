//
//  AuthService.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import Foundation
import Combine
import Supabase

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: Profile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseService.shared.client
    
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
            print("Auth check failed: \(error)")
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
            await loadUserProfile(userId: user.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.signUp(email: email, password: password)
            let user = session.user
            
            // Create profile
            let profile = Profile(
                id: user.id,
                teamId: nil,
                role: .readonly,
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: nil,
                grade: nil,
                memberRole: nil,
                experienceBadges: [],
                emergencyContactName: nil,
                emergencyContactPhone: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await supabase
                .from("profiles")
                .insert(profile)
                .execute()
            
            await loadUserProfile(userId: user.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
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
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            errorMessage = error.localizedDescription
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
                throw NSError(domain: "AuthService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
            }
            
            currentUser = profile
            isAuthenticated = true
            errorMessage = nil
        } catch {
            print("Failed to load profile: \(error)")
            errorMessage = "Failed to load user profile"
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
}
