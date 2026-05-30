//
//  ContentView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("ftchub.legalConsentAccepted") private var legalConsentAccepted = false
    @AppStorage("ftchub.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("ftchub.colorScheme") private var colorSchemePreference: String = "light"
    @State private var showingLegalConsent = false
    @State private var showingOnboarding = false
    
    var preferredColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "dark":
            return .dark
        case "light":
            return .light
        default:
            return nil // system
        }
    }
    
    var body: some View {
        Group {
            if authService.isShowingPasswordResetForm {
                SetNewPasswordView()
                    .environmentObject(authService)
                    .transition(.opacity)
                    .id("password-reset-form-\(authService.isShowingPasswordResetForm)")
            } else if authService.isShowingPasswordResetSuccess {
                PasswordResetSuccessView(email: authService.verificationEmail)
                    .environmentObject(authService)
                    .transition(.opacity)
            } else if authService.isShowingSignUpSuccess {
                SignUpSuccessView(email: authService.signUpEmail)
                    .environmentObject(authService)
                    .transition(.opacity)
            } else if authService.isShowingEmailVerification {
                EmailVerificationView(email: authService.verificationEmail)
                    .environmentObject(authService)
                    .transition(.opacity)
            } else if authService.isAuthenticated {
                // Only show onboarding for new accounts
                if !hasCompletedOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .environmentObject(authService)
                }
            } else if authService.isGuestMode {
                // Guest mode - show only resources
                MainTabView()
                    .environmentObject(authService)
            } else {
                WelcomeView()
                    .environmentObject(authService)
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: authService.isShowingPasswordResetForm)
        .animation(.easeInOut(duration: 0.3), value: authService.isShowingPasswordResetSuccess)
        .animation(.easeInOut(duration: 0.3), value: authService.isShowingEmailVerification)
        .animation(.easeInOut(duration: 0.3), value: authService.isGuestMode)
        .animation(.easeInOut(duration: 0.3), value: authService.isShowingSignUpSuccess)
        .task(id: authService.isAuthenticated) {
            updateLegalConsentPresentation(isAuthenticated: authService.isAuthenticated)
            if authService.isAuthenticated && !hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
        .task(id: legalConsentAccepted) {
            updateLegalConsentPresentation(isAuthenticated: authService.isAuthenticated)
        }
        .onAppear {
            updateLegalConsentPresentation(isAuthenticated: authService.isAuthenticated)
            if authService.isAuthenticated && !hasCompletedOnboarding {
                showingOnboarding = true
            }
        }
        .sheet(isPresented: $showingLegalConsent) {
            NavigationView {
                LegalConsentView()
                    .environmentObject(authService)
            }
            .interactiveDismissDisabled(!legalConsentAccepted)
        }
    }
    
    private func updateLegalConsentPresentation(isAuthenticated: Bool) {
        showingLegalConsent = isAuthenticated && !legalConsentAccepted
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .withToast()
}
