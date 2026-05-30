//
//  AuthScreenComponents.swift
//  FTCHUB
//

import SwiftUI
import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Auth light theme (always light on onboarding / sign-in / sign-up)

enum AuthLightTheme {
    /// Pre-sign-in intro carousel (WelcomeView) — as white as possible.
    static let introBackground = Color.white
    /// Sign-in / sign-up screens — light grey so social buttons read clearly.
    static let background = Color(red: 0.92, green: 0.93, blue: 0.95)
    static let surface = Color.white
    static let border = Color(red: 0.82, green: 0.84, blue: 0.87)
    static let textPrimary = Color.black
    static let textSecondary = Color(red: 0.35, green: 0.35, blue: 0.38)
    static let fieldBackground = Color.white
    static let fieldMinHeight: CGFloat = 48
    static let fieldCornerRadius: CGFloat = 12
    static let fieldIconWidth: CGFloat = 20
    static let googleButtonBackground = Color.white
    static let socialButtonHeight: CGFloat = 58
    static let socialButtonCornerRadius: CGFloat = 14
    /// Google branding: standard G logo at 20pt on sign-in buttons.
    static let socialIconSize: CGFloat = 20
    /// Matches Sign in with Apple label visual weight.
    static let socialButtonFont: Font = .system(size: 20, weight: .semibold)
    /// Dark orange solid fill — distinct from primary Sign In, same warm tone.
    static let guestButtonBackground = Color(red: 0.48, green: 0.28, blue: 0.06)
    static let guestButtonForeground = Color.white
}

extension View {
    func authInputFieldChrome() -> some View {
        frame(maxWidth: .infinity, minHeight: AuthLightTheme.fieldMinHeight, alignment: .leading)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(AuthLightTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: AuthLightTheme.fieldCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AuthLightTheme.fieldCornerRadius)
                    .stroke(AuthLightTheme.border, lineWidth: 1)
            )
    }
}

private extension View {
    /// Full-width social row with fixed height matching Sign in with Apple.
    func authSocialButtonFrame() -> some View {
        frame(maxWidth: .infinity)
            .frame(height: AuthLightTheme.socialButtonHeight)
            .clipShape(RoundedRectangle(cornerRadius: AuthLightTheme.socialButtonCornerRadius))
    }
}

private struct AuthLightScreenModifier: ViewModifier {
    let background: Color

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.light)
            .background(background.ignoresSafeArea())
    }
}

extension View {
    /// Sign-in / sign-up (grey background).
    func authLightScreen() -> some View {
        modifier(AuthLightScreenModifier(background: AuthLightTheme.background))
    }

    /// Pre-sign-in intro carousel (white background).
    func authIntroScreen() -> some View {
        modifier(AuthLightScreenModifier(background: AuthLightTheme.introBackground))
    }
}

/// Account mode switch (e.g. Sign Up / Sign In) with highlighted action word, no chevron.
struct AuthSwitchLink: View {
    let prefix: String
    let actionWord: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(prefix)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AuthLightTheme.textSecondary)
                Text(actionWord)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Text action styled like a back control (black, chevron).
struct AuthBackLinkButton: View {
    let title: String
    var showsChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if showsChevron {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(AuthLightTheme.textPrimary)
        }
        .buttonStyle(.plain)
    }
}

struct AuthHeaderView: View {
    let subtitle: String

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("FTCHUB")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AuthLightTheme.textPrimary)

            Text(subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundColor(AuthLightTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct AuthOrDivider: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(AuthLightTheme.border)
                .frame(height: 1)
            Text("or")
                .font(.caption.weight(.medium))
                .foregroundColor(AuthLightTheme.textSecondary)
                .padding(.horizontal, DesignSystem.Spacing.sm)
            Rectangle()
                .fill(AuthLightTheme.border)
                .frame(height: 1)
        }
    }
}

struct SocialSignInButtons: View {
    @EnvironmentObject private var authService: AuthService
    var isDisabled: Bool = false
    @State private var appleSignInNonce: String?

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            SignInWithAppleButton(.signIn) { request in
                appleSignInNonce = AppleSignInHelper.prepareRequest(request)
            } onCompletion: { result in
                handleAppleCompletion(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: .infinity, minHeight: AuthLightTheme.socialButtonHeight, maxHeight: AuthLightTheme.socialButtonHeight)
            .authSocialButtonFrame()
            .disabled(isDisabled || authService.isLoading)

            Button(action: handleGoogleSignIn) {
                HStack(spacing: 12) {
                    Image("GoogleLogo")
                        .resizable()
                        .renderingMode(.original)
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: AuthLightTheme.socialIconSize, height: AuthLightTheme.socialIconSize)
                    Text("Continue with Google")
                        .font(AuthLightTheme.socialButtonFont)
                        .foregroundColor(AuthLightTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: AuthLightTheme.socialButtonHeight)
                .background(AuthLightTheme.googleButtonBackground)
                .clipShape(RoundedRectangle(cornerRadius: AuthLightTheme.socialButtonCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AuthLightTheme.socialButtonCornerRadius)
                        .stroke(AuthLightTheme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isDisabled || authService.isLoading)
            .accessibilityLabel("Continue with Google")
        }
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let nonce = appleSignInNonce else {
                authService.errorMessage = "Sign in with Apple failed. Please try again."
                return
            }

            Task {
                do {
                    let credentials = try AppleSignInHelper.credentials(from: authorization, nonce: nonce)
                    try await authService.completeAppleSignIn(idToken: credentials.idToken, nonce: credentials.nonce)
                } catch let error as AppleSignInHelper.Error {
                    if case .cancelled = error { return }
                    authService.errorMessage = error.localizedDescription
                } catch {
                    // AuthService surfaces errors
                }
            }
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            authService.errorMessage = error.localizedDescription
        }
    }

    private func handleGoogleSignIn() {
        #if canImport(UIKit)
        guard let presenter = ViewControllerLocator.topViewController() else {
            authService.errorMessage = "Unable to present Google Sign-In."
            return
        }

        Task {
            do {
                try await authService.signInWithGoogle(presenting: presenter)
            } catch let error as GoogleSignInHelper.Error {
                if case .cancelled = error { return }
            } catch {
                // AuthService surfaces errors
            }
        }
        #endif
    }
}

struct AuthPrimaryButton: View {
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isEnabled ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct AuthGuestButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("Continue as Guest")
                    .font(.body.weight(.semibold))
                Image(systemName: "eye")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AuthLightTheme.guestButtonBackground)
            .foregroundColor(AuthLightTheme.guestButtonForeground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct AuthFormCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            content
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .shadow(color: DesignSystem.Colors.shadow.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false
    @Binding var showPassword: Bool

    init(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        isSecure: Bool = false,
        showPassword: Binding<Bool> = .constant(false)
    ) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.keyboard = keyboard
        self.isSecure = isSecure
        self._showPassword = showPassword
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(AuthLightTheme.textPrimary)
                .frame(width: AuthLightTheme.fieldIconWidth)

            if isSecure {
                Group {
                    if showPassword {
                        TextField("", text: $text, prompt: authFieldPrompt(placeholder))
                    } else {
                        SecureField("", text: $text, prompt: authFieldPrompt(placeholder))
                    }
                }
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundColor(AuthLightTheme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .tint(AuthLightTheme.textPrimary)

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(AuthLightTheme.textPrimary)
                }
            } else {
                TextField("", text: $text, prompt: authFieldPrompt(placeholder))
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundColor(AuthLightTheme.textPrimary)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .tint(AuthLightTheme.textPrimary)
            }
        }
        .authInputFieldChrome()
    }

    private func authFieldPrompt(_ placeholder: String) -> Text {
        Text(placeholder)
            .foregroundColor(AuthLightTheme.textPrimary.opacity(0.45))
    }
}
