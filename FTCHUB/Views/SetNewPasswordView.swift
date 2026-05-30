//
//  SetNewPasswordView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/21/25.
//

import SwiftUI

struct SetNewPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isUpdating = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 40)
                        
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                DesignSystem.Colors.primary.opacity(0.15),
                                                DesignSystem.Colors.accent.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "lock.rotation")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundStyle(DesignSystem.Gradients.primary)
                            }
                            
                            Text("Set New Password")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Please enter your new password below.")
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 20)
                        
                        // New Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(width: 20)
                                
                                if showPassword {
                                    TextField("Enter new password", text: $newPassword)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .tint(DesignSystem.Colors.primary)
                                } else {
                                    SecureField("Enter new password", text: $newPassword)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .tint(DesignSystem.Colors.primary)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                            .padding(16)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
                            )
                            
                            // Password Strength Indicator
                            if !newPassword.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(DesignSystem.Colors.border)
                                                .frame(height: 4)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(PasswordStrength.calculate(newPassword).color)
                                                .frame(width: geometry.size.width * PasswordStrength.calculate(newPassword).progress, height: 4)
                                        }
                                    }
                                    .frame(height: 4)
                                    
                                    Text(PasswordStrength.calculate(newPassword).displayName)
                                        .font(.caption)
                                        .foregroundColor(PasswordStrength.calculate(newPassword).color)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(width: 20)
                                
                                if showConfirmPassword {
                                    TextField("Confirm new password", text: $confirmPassword)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .tint(DesignSystem.Colors.primary)
                                } else {
                                    SecureField("Confirm new password", text: $confirmPassword)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                        .tint(DesignSystem.Colors.primary)
                                }
                                
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                            .padding(16)
                            .background(DesignSystem.Colors.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        confirmPassword.isEmpty || passwordsMatch ? DesignSystem.Colors.border : DesignSystem.Colors.error,
                                        lineWidth: 1
                                    )
                            )
                            
                            if !confirmPassword.isEmpty && !passwordsMatch {
                                Text("Passwords do not match")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.error)
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Update Password Button
                        Button(action: updatePassword) {
                            HStack {
                                if isUpdating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Update Password →")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isFormValid && !isUpdating
                                    ? LinearGradient(
                                        colors: [DesignSystem.Colors.primary, DesignSystem.Colors.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [DesignSystem.Colors.textTertiary, DesignSystem.Colors.textTertiary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isUpdating)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Password Updated", isPresented: $showSuccess) {
                Button("Go Back to Login", role: .cancel) {
                    // Navigate back to login
                    authService.isShowingPasswordResetForm = false
                    // Sign out the temporary recovery session
                    Task {
                        try? await authService.signOut()
                    }
                }
            } message: {
                Text("Your password has been successfully updated. Please sign in with your new password.")
            }
        }
    }
    
    private var passwordsMatch: Bool {
        newPassword == confirmPassword
    }
    
    private var isFormValid: Bool {
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        passwordsMatch &&
        newPassword.count >= 6
    }
    
    private func updatePassword() {
        guard isFormValid else { return }
        
        Task { @MainActor in
            isUpdating = true
            errorMessage = ""
            defer { isUpdating = false }
            
            do {
                try await authService.updatePassword(newPassword: newPassword)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    SetNewPasswordView()
        .environmentObject(AuthService())
}

