//
//  AuthenticationView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI
import UIKit

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingPasswordReset = false
    @State private var showPassword = false

    private let showsCloseButton: Bool
    private let onContinueAsGuest: (() -> Void)?

    init(
        initialSignUpMode: Bool = false,
        showsCloseButton: Bool = false,
        onContinueAsGuest: (() -> Void)? = nil
    ) {
        self.showsCloseButton = showsCloseButton
        self.onContinueAsGuest = onContinueAsGuest
        _isSignUp = State(initialValue: initialSignUpMode)
    }

    var body: some View {
        NavigationView {
            Group {
                if isSignUp {
                    SignUpFlowView(
                        onSwitchToSignIn: switchToSignIn,
                        onContinueAsGuest: continueAsGuest
                    )
                    .environmentObject(authService)
                } else {
                    signInContent
                }
            }
            .onAppear {
                UITextField.appearance().tintColor = .black
                UITextView.appearance().tintColor = .black
            }
        }
        .authLightScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView(email: $email)
                .environmentObject(authService)
        }
    }

    private var signInContent: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                AuthHeaderView(subtitle: "Built for FIRST Tech Challenge teams")
                    .padding(.top, DesignSystem.Spacing.xl)

                SocialSignInButtons(isDisabled: authService.isLoading)
                .padding(.horizontal, DesignSystem.Spacing.md)

                AuthOrDivider()
                    .padding(.horizontal, DesignSystem.Spacing.md)

                VStack(spacing: DesignSystem.Spacing.lg) {
                    if let errorMessage = authService.errorMessage {
                        CompactErrorView(
                            message: errorMessage,
                            onDismiss: { authService.errorMessage = nil }
                        )
                        .transition(.opacity.combined(with: .scale))
                    }

                    AuthTextField(
                        icon: "envelope.fill",
                        placeholder: "Email address",
                        text: $email,
                        keyboard: .emailAddress
                    )

                    AuthTextField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        showPassword: $showPassword
                    )

                    AuthPrimaryButton(
                        title: "Sign In",
                        isEnabled: isSignInFormValid,
                        isLoading: authService.isLoading,
                        action: handleSignIn
                    )

                    AuthBackLinkButton(title: "Forgot Password?", showsChevron: false) {
                        showingPasswordReset = true
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)

                AuthSwitchLink(
                    prefix: "Don't have an account?",
                    actionWord: "Sign Up",
                    action: switchToSignUp
                )

                AuthGuestButton(action: continueAsGuest)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .padding(.bottom, DesignSystem.Spacing.xxl)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var isSignInFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    private func switchToSignUp() {
        withAnimation(.spring(response: 0.3)) {
            isSignUp = true
            authService.errorMessage = nil
            authService.infoMessage = nil
            password = ""
        }
    }

    private func switchToSignIn() {
        withAnimation(.spring(response: 0.3)) {
            isSignUp = false
            authService.errorMessage = nil
            authService.infoMessage = nil
            password = ""
        }
    }

    private func continueAsGuest() {
        DesignSystem.Haptics.impact(.light)
        onContinueAsGuest?()
        dismiss()
        withAnimation(.spring(response: 0.3)) {
            authService.enterGuestMode()
        }
    }

    private func handleSignIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                // Error is handled by AuthService
            }
        }
    }
}

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @Binding var email: String
    @State private var isSending = false
    @State private var message = ""

    var body: some View {
        NavigationView {
            ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AuthLightTheme.border.opacity(0.35))
                                    .frame(width: 120, height: 120)

                                Image(systemName: "lock.rotation")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundColor(AuthLightTheme.textPrimary)
                            }

                            Text("Forgot Password")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AuthLightTheme.textPrimary)

                            Text("Please enter your email address to reset your password.")
                                .font(.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 40)

                        HStack(spacing: 12) {
                            Image(systemName: "iphone")
                                .font(.title3)
                                .foregroundColor(DesignSystem.Colors.primary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(" Open Email on Your Phone")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(DesignSystem.Colors.textPrimary)

                                Text("You MUST open the password reset link on the same phone where you have the FTC HUB app installed.")
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DesignSystem.Colors.primary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                        .padding(.horizontal, 24)

                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .frame(width: 20)
                            TextField("Enter your email address...", text: $email)
                                .textFieldStyle(.plain)
                                .font(.body)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        }
                        .padding(16)
                        .background(DesignSystem.Colors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.Colors.border, lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                        Button(action: sendReset) {
                            HStack {
                                if isSending {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Send Password →")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(DesignSystem.Colors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(email.isEmpty || isSending)
                        .padding(.horizontal, 24)

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

                        Spacer()
                            .frame(height: 40)
                    }
            }
            .authLightScreen()
            .navigationTitle("Password Reset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }

    private func sendReset() {
        guard !email.isEmpty else { return }

        Task { @MainActor in
            message = ""
            isSending = true
            defer { isSending = false }

            do {
                try await authService.resetPassword(email: email)
                authService.verificationEmail = email
                authService.isShowingPasswordResetSuccess = true
                dismiss()
            } catch {
                message = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthService())
}
