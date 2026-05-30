//
//  EmailVerificationView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/21/25.
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email: String
    @State private var isResending = false
    @State private var showResendSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(email: String = "") {
        _email = State(initialValue: email)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        Spacer()
                            .frame(height: 60)
                        
                        // Success Icon with Animation
                        ZStack {
                            Circle()
                                .fill(DesignSystem.Colors.success.opacity(0.1))
                                .frame(width: 140, height: 140)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80, weight: .medium))
                                .foregroundStyle(DesignSystem.Colors.success)
                        }
                        .padding(.bottom, DesignSystem.Spacing.lg)
                        .springyAppear(using: DesignSystem.Motion.emphasized)
                        
                        // Success Message
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("Email Verified!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Thank you for verifying your email address. Your account has been confirmed and you can now sign in.")
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                        .springyAppear(using: DesignSystem.Motion.spring(), delay: 0.1)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // Action Buttons
                        VStack(spacing: DesignSystem.Spacing.md) {
                            // Go Back to Login Button
                            Button(action: {
                                // Dismiss and go back to login
                                authService.isShowingEmailVerification = false
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left.circle.fill")
                                    Text("Go Back to Login")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(DesignSystem.Spacing.md)
                                .background(DesignSystem.Gradients.primary)
                                .foregroundColor(.white)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .springyAppear(using: DesignSystem.Motion.spring(), delay: 0.2)
                            
                            // Resend Email Button
                            Button(action: resendVerificationEmail) {
                                HStack {
                                    if isResending {
                                        ProgressView()
                                            .tint(DesignSystem.Colors.primary)
                                    } else {
                                        Image(systemName: "envelope.fill")
                                    }
                                    Text(isResending ? "Sending..." : "Resend Verification Email")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(DesignSystem.Spacing.md)
                                .background(DesignSystem.Colors.secondaryBackground)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(isResending)
                            .springyAppear(using: DesignSystem.Motion.spring(), delay: 0.3)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        authService.isShowingEmailVerification = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .alert("Email Sent", isPresented: $showResendSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Verification email has been sent to \(email). Please check your inbox.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func resendVerificationEmail() {
        guard !email.isEmpty else {
            errorMessage = "Email address not available. Please go back to login and try again."
            showError = true
            return
        }
        
        isResending = true
        
        Task {
            do {
                try await authService.resendEmailVerification(email: email)
                await MainActor.run {
                    isResending = false
                    showResendSuccess = true
                }
            } catch {
                await MainActor.run {
                    isResending = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    EmailVerificationView(email: "example@email.com")
        .environmentObject(AuthService())
}

