//
//  CheckYourEmailView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct CheckYourEmailView: View {
    @EnvironmentObject var authService: AuthService
    let email: String
    @State private var canResend = true
    @State private var resendCountdown = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Clean white background
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 60)
                        
                        // Illustration - similar to reference (dove with envelope)
                        VStack(spacing: 16) {
                            ZStack {
                                // Background circle with gradient
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignSystem.Colors.success.opacity(0.15),
                                                DesignSystem.Colors.primary.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                
                                // Illustration: Envelope with sparkles (like dove with envelope in reference)
                                VStack(spacing: 8) {
                                    // Main envelope icon
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 50, weight: .medium))
                                        .foregroundStyle(DesignSystem.Gradients.primary)
                                    
                                    // Sparkles around it (like reference)
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkle")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.accent)
                                        Image(systemName: "sparkle")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.accent)
                                        Image(systemName: "sparkle")
                                            .font(.caption)
                                            .foregroundColor(DesignSystem.Colors.accent)
                                    }
                                }
                            }
                            
                            Text("Check Your Email")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Thanks for signing up!")
                                .font(.title3)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .padding(.top, 4)
                            
                            Text("Please check your email in a few minutes - we've sent you a verification link to activate your account.")
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .lineSpacing(4)
                                .padding(.top, 8)
                        }
                        .padding(.top, 40)
                        
                        // Email display
                        VStack(spacing: 16) {
                            Text("We've sent a verification email to:")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text(email)
                                .font(.headline)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(DesignSystem.Colors.primary.opacity(0.1))
                                )
                        }
                        .padding(.horizontal, 24)
                        
                        // Open Email button
                        Button(action: {
                            // Open default email app
                            if let url = URL(string: "message://") {
                                if UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Open My Email")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        
                        // Resend email section
                        VStack(spacing: 12) {
                            if resendCountdown > 0 {
                                Text("Resend email in \(resendCountdown) seconds")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                            }
                            
                            Button(action: resendVerificationEmail) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Resend Verification Email")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: canResend ?
                                            [DesignSystem.Colors.primary, DesignSystem.Colors.accent] :
                                            [DesignSystem.Colors.textTertiary, DesignSystem.Colors.textTertiary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!canResend || authService.isLoading)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        // Help text
                        VStack(spacing: 8) {
                            Text("Didn't receive the email?")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Button("Contact us at kartheek.eadara@gmail.com") {
                                if let url = URL(string: "mailto:kartheek.eadara@gmail.com") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .padding(.top, 16)
                        
                        // Back to sign in
                        Button(action: {
                            authService.isShowingSignUpSuccess = false
                            authService.signUpEmail = ""
                        }) {
                            Text("Back to Sign In")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .padding(.top, 24)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        authService.isShowingSignUpSuccess = false
                        authService.signUpEmail = ""
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }
    
    private func resendVerificationEmail() {
        guard canResend else { return }
        
        Task {
            do {
                try await authService.resendEmailVerification(email: email)
                canResend = false
                resendCountdown = 60
                
                // Start countdown timer
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    resendCountdown -= 1
                    if resendCountdown <= 0 {
                        canResend = true
                        timer.invalidate()
                    }
                }
            } catch {
                // Error is handled by AuthService
            }
        }
    }
}

#Preview {
    CheckYourEmailView(email: "user@example.com")
        .environmentObject(AuthService())
}
