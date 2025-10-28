//
//  AuthenticationView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSignUp = false
    @State private var showingPasswordReset = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Header
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "robot.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(DesignSystem.Gradients.primary)
                                .shadow(color: DesignSystem.Colors.primary.opacity(0.2), radius: 20, x: 0, y: 8)
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                Text("FTC Team Hub")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                                
                                Text("DECODE 2025-2026")
                                    .font(.subheadline)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .fontWeight(.medium)
                            }
                            
                            Text("Manage your team, track progress, and dominate the competition")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                .padding(.top, DesignSystem.Spacing.sm)
                        }
                        .padding(.top, DesignSystem.Spacing.xxl)
                        
                        // Form Card
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            if isSignUp {
                                VStack(spacing: DesignSystem.Spacing.md) {
                                    CustomTextField(title: "First Name", text: $firstName, placeholder: "John")
                                    CustomTextField(title: "Last Name", text: $lastName, placeholder: "Doe")
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            CustomTextField(title: "Email", text: $email, placeholder: "john@example.com")
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            CustomTextField(title: "Password", text: $password, placeholder: "••••••••", isSecure: true)
                            
                            if let errorMessage = authService.errorMessage {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(DesignSystem.Colors.error)
                                    Text(errorMessage)
                                        .foregroundColor(DesignSystem.Colors.error)
                                        .font(.caption)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.Colors.error.opacity(0.1))
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .transition(.opacity)
                            }
                            
                            // Action Button
                            Button(action: handleAuth) {
                                HStack {
                                    if authService.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(DesignSystem.Spacing.md)
                                .background(
                                    LinearGradient(
                                        colors: isFormValid ? 
                                            [DesignSystem.Colors.primary, DesignSystem.Colors.accent] :
                                            [DesignSystem.Colors.textTertiary, DesignSystem.Colors.textTertiary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .shadow(color: DesignSystem.Colors.shadow, radius: 8, x: 0, y: 4)
                            }
                            .disabled(authService.isLoading || !isFormValid)
                            
                            if !isSignUp {
                                Button("Forgot Password?") {
                                    showingPasswordReset = true
                                }
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding(.top, DesignSystem.Spacing.xs)
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.border.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: DesignSystem.Colors.shadow, radius: 12, x: 0, y: 4)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        // Toggle Sign Up/Sign In
                        Button(action: { 
                            withAnimation {
                                isSignUp.toggle()
                                authService.errorMessage = nil
                            }
                        }) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: isSignUp ? "arrow.left.circle.fill" : "arrow.right.circle.fill")
                                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(DesignSystem.Colors.primary)
                            .padding(DesignSystem.Spacing.md)
                        }
                        
                        Spacer()
                            .frame(height: DesignSystem.Spacing.xl)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView(email: $email)
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !firstName.isEmpty && !lastName.isEmpty && email.contains("@")
        } else {
            return !email.isEmpty && !password.isEmpty && email.contains("@")
        }
    }
    
    private func handleAuth() {
        Task {
            do {
                if isSignUp {
                    try await authService.signUp(
                        email: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName
                    )
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                // Error is handled by AuthService
            }
        }
    }
}

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var email: String
    @State private var isSending = false
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundStyle(DesignSystem.Gradients.primary)
                
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you instructions to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                CustomTextField(title: "Email", text: $email, placeholder: "john@example.com")
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("sent") ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                        .padding()
                }
                
                Button(action: sendReset) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Send Reset Email")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Gradients.primary)
                    .foregroundColor(.white)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .disabled(email.isEmpty || isSending)
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .navigationTitle("Password Reset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendReset() {
        // TODO: Implement password reset
        message = "Reset email sent to \(email)"
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthService())
}
