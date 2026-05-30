//
//  SignUpSuccessView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/21/25.
//

import SwiftUI

struct SignUpSuccessView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email: String
    @State private var isResending = false
    @State private var showResendSuccess = false
    @State private var showResendError = false
    @State private var resendErrorMessage = ""
    
    init(email: String) {
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
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                        .padding(.bottom, DesignSystem.Spacing.lg)
                        .springyAppear(using: DesignSystem.Motion.emphasized)
                        
                        // Success Message
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("Thanks for Signing Up!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Please check your email to verify your account. We've sent a verification link to \(email).")
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                        .springyAppear(using: DesignSystem.Motion.spring(), delay: 0.1)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // Resend Email Button
                        Button(action: resendVerificationEmail) {
                            HStack {
                                if isResending {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "envelope.fill")
                                }
                                Text(isResending ? "Sending..." : "Resend Verification Email")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(DesignSystem.Spacing.md)
                            .background(
                                Group {
                                    if isResending {
                                        DesignSystem.Colors.textTertiary
                                    } else {
                                        DesignSystem.Gradients.primary
                                    }
                                }
                            )
                            .foregroundColor(.white)
                            .cornerRadius(DesignSystem.CornerRadius.md)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isResending)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .springyAppear(using: DesignSystem.Motion.spring(), delay: 0.2)
                        
                        // Return to Sign In Button
                        Button(action: {
                            // Go back to sign in page
                            authService.isShowingSignUpSuccess = false
                            // Clear sign up form state
                            authService.infoMessage = nil
                            authService.errorMessage = nil
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                Text("Return to Sign In")
                                    .fontWeight(.semibold)
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
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .springyAppear(using: DesignSystem.Motion.spring(), delay: 0.3)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        authService.isShowingSignUpSuccess = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .alert("Email Sent", isPresented: $showResendSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Verification email has been sent to \(email). Please check your inbox and spam folder.")
            }
            .alert("Error", isPresented: $showResendError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(resendErrorMessage)
            }
        }
    }
    
    private func resendVerificationEmail() {
        isResending = true
        resendErrorMessage = ""
        
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
                    resendErrorMessage = "Failed to resend verification email: \(error.localizedDescription)\n\nPlease check:\n1. Supabase Dashboard → Authentication → Settings\n2. Email spam folder\n3. Try again in a few minutes"
                    showResendError = true
                }
            }
        }
    }
}

#Preview {
    SignUpSuccessView(email: "example@email.com")
        .environmentObject(AuthService())
}

