//
//  SignUpFlowView.swift
//  FTCHUB
//

import SwiftUI

struct SignUpFlowView: View {
    @EnvironmentObject var authService: AuthService

    let onSwitchToSignIn: () -> Void
    let onContinueAsGuest: () -> Void

    private static let totalSteps = 4

    @State private var currentStep = 0
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthDay: Int = 1
    @State private var birthMonth: Int = 1
    @State private var birthYear: Int = Calendar.current.component(.year, from: Date()) - 18
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showAgeError = false

    private let months = [
        (1, "January"), (2, "February"), (3, "March"), (4, "April"),
        (5, "May"), (6, "June"), (7, "July"), (8, "August"),
        (9, "September"), (10, "October"), (11, "November"), (12, "December")
    ]

    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 100)...currentYear).reversed()
    }

    private var birthDate: Date {
        var components = DateComponents()
        components.year = birthYear
        components.month = birthMonth
        components.day = birthDay
        return Calendar.current.date(from: components) ?? Date()
    }

    private var validDays: [Int] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = birthYear
        components.month = birthMonth
        let range = calendar.range(of: .day, in: .month, for: calendar.date(from: components) ?? Date())
        let maxDay = range?.count ?? 31
        return Array(1...maxDay)
    }

    var body: some View {
        VStack(spacing: 0) {
            progressHeader
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, 24)

            TabView(selection: $currentStep) {
                profileStep.tag(0)
                accountStep.tag(1)
                securityStep.tag(2)
                birthdayStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: currentStep)

            footerActions
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, 32)
        }
        .authLightScreen()
        .fullScreenCover(isPresented: $authService.isShowingSignUpSuccess) {
            CheckYourEmailView(email: authService.signUpEmail)
                .environmentObject(authService)
        }
    }

    // MARK: - Progress

    private var progressHeader: some View {
        VStack(spacing: 14) {
            Text("FTC HUB")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AuthLightTheme.textPrimary)

            Text(stepSubtitle)
                .font(.subheadline)
                .foregroundColor(AuthLightTheme.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                Text("Step \(currentStep + 1) of \(Self.totalSteps)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
                Text(stepTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.border)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.primary)
                        .frame(
                            width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(Self.totalSteps),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Your name"
        case 1: return "Email"
        case 2: return "Password"
        default: return "Birthday"
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case 0: return "Tell us who you are"
        case 1: return "We'll send a verification link"
        case 2: return "Choose a secure password"
        default: return "Confirm you're at least 13 years old"
        }
    }

    // MARK: - Steps

    private var profileStep: some View {
        stepContainer {
            signUpField(icon: "person.fill", placeholder: "First Name", text: $firstName)
            signUpField(icon: "person.fill", placeholder: "Last Name", text: $lastName)
        }
    }

    private var accountStep: some View {
        stepContainer {
            errorBanner
            signUpField(
                icon: "envelope.fill",
                placeholder: "your email address...",
                text: $email,
                keyboard: .emailAddress,
                autocapitalization: false
            )
        }
    }

    private var securityStep: some View {
        stepContainer {
            errorBanner
            passwordField(title: "Password", text: $password, isVisible: $showPassword)

            if !password.isEmpty {
                passwordStrengthView
            }

            passwordField(title: "Confirm Password", text: $confirmPassword, isVisible: $showConfirmPassword)

            if !confirmPassword.isEmpty && password != confirmPassword {
                ValidationErrorView(message: "Passwords do not match")
                    .padding(.horizontal, 4)
            }
        }
    }

    private var birthdayStep: some View {
        stepContainer {
            errorBanner

            HStack(spacing: 8) {
                birthMenu(
                    label: months.first(where: { $0.0 == birthMonth })?.1 ?? "Month",
                    options: months.map { ($0.0, $0.1) }
                ) { value in
                    birthMonth = value
                    validateDate()
                    showAgeError = !isAgeValid()
                }

                birthMenu(
                    label: "\(birthDay)",
                    options: validDays.map { ($0, "\($0)") }
                ) { value in
                    birthDay = value
                    validateDate()
                    showAgeError = !isAgeValid()
                }

                birthMenu(
                    label: "\(birthYear)",
                    options: years.map { ($0, "\($0)") }
                ) { value in
                    birthYear = value
                    validateDate()
                    showAgeError = !isAgeValid()
                }
            }
            .padding(16)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(showAgeError ? DesignSystem.Colors.error : DesignSystem.Colors.border, lineWidth: 1)
            )

            if showAgeError {
                ValidationErrorView(message: "You must be at least 13 years old to use this app.")
                    .padding(.horizontal, 4)
            }

            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Text("You must be at least 13 years old")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Footer

    private var footerActions: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if currentStep == 0 {
                stepPrimaryButton(showBack: false)

                AuthOrDivider()

                SocialSignInButtons(isDisabled: authService.isLoading)
            } else {
                HStack(spacing: 12) {
                    Button(action: goBack) {
                        Text("Back")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AuthLightTheme.surface)
                            .foregroundColor(AuthLightTheme.textPrimary)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AuthLightTheme.border, lineWidth: 1)
                            )
                    }
                    stepPrimaryButton(showBack: true)
                }
            }

            AuthSwitchLink(
                prefix: "I already have an account?",
                actionWord: "Sign In",
                action: onSwitchToSignIn
            )

            AuthGuestButton(action: onContinueAsGuest)
        }
    }

    @ViewBuilder
    private func stepPrimaryButton(showBack: Bool) -> some View {
        Button(action: primaryAction) {
            HStack {
                if authService.isLoading && currentStep == Self.totalSteps - 1 {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(primaryButtonTitle)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isCurrentStepValid ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
        .disabled(!isCurrentStepValid || (authService.isLoading && currentStep == Self.totalSteps - 1))
        .frame(maxWidth: showBack ? .infinity : .infinity)
    }

    private var primaryButtonTitle: String {
        currentStep == Self.totalSteps - 1 ? "Create Account" : "Next"
    }

    // MARK: - Helpers

    private func stepContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                content()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let errorMessage = authService.errorMessage {
            CompactErrorView(
                message: errorMessage,
                onDismiss: { authService.errorMessage = nil }
            )
            .transition(.opacity.combined(with: .scale))
        }
    }

    private var passwordStrengthView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Password strength: \(PasswordStrength.calculate(password).displayName)")
                    .font(.caption)
                    .foregroundColor(PasswordStrength.calculate(password).color)
                Spacer()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignSystem.Colors.border)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(PasswordStrength.calculate(password).color)
                        .frame(
                            width: geometry.size.width * PasswordStrength.calculate(password).progress,
                            height: 4
                        )
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 4)
    }

    private func signUpField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        autocapitalization: Bool = true
    ) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(AuthLightTheme.textPrimary)
                .frame(width: AuthLightTheme.fieldIconWidth)
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(AuthLightTheme.textPrimary.opacity(0.45)))
                .textFieldStyle(.plain)
                .font(.subheadline)
                .foregroundColor(AuthLightTheme.textPrimary)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization ? .sentences : .never)
                .autocorrectionDisabled(!autocapitalization)
                .tint(AuthLightTheme.textPrimary)
        }
        .authInputFieldChrome()
    }

    private func passwordField(title: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "lock.fill")
                .font(.subheadline)
                .foregroundColor(AuthLightTheme.textPrimary)
                .frame(width: AuthLightTheme.fieldIconWidth)

            if isVisible.wrappedValue {
                TextField("", text: text, prompt: Text(title).foregroundColor(AuthLightTheme.textPrimary.opacity(0.45)))
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundColor(AuthLightTheme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .tint(AuthLightTheme.textPrimary)
            } else {
                SecureField("", text: text, prompt: Text(title).foregroundColor(AuthLightTheme.textPrimary.opacity(0.45)))
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundColor(AuthLightTheme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .tint(AuthLightTheme.textPrimary)
            }

            Button(action: { isVisible.wrappedValue.toggle() }) {
                Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .font(.subheadline)
                    .foregroundColor(AuthLightTheme.textPrimary)
            }
        }
        .authInputFieldChrome()
    }

    private func birthMenu(
        label: String,
        options: [(Int, String)],
        onSelect: @escaping (Int) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.0) { option in
                Button(action: { onSelect(option.0) }) {
                    HStack {
                        Text(option.1)
                        // selection check handled by label refresh
                    }
                }
            }
        } label: {
            Text(label)
                .font(.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0:
            return !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
                !lastName.trimmingCharacters(in: .whitespaces).isEmpty
        case 1:
            return !email.isEmpty && email.contains("@")
        case 2:
            return !password.isEmpty && password == confirmPassword
        default:
            return isAgeValid()
        }
    }

    private func goBack() {
        authService.errorMessage = nil
        withAnimation(.spring(response: 0.3)) {
            currentStep = max(0, currentStep - 1)
        }
    }

    private func primaryAction() {
        if currentStep < Self.totalSteps - 1 {
            authService.errorMessage = nil
            withAnimation(.spring(response: 0.3)) {
                currentStep += 1
            }
            return
        }
        createAccount()
    }

    private func createAccount() {
        guard isAgeValid() else {
            showAgeError = true
            authService.errorMessage = "You must be at least 13 years old to create an account. If you need access, please have a parent or guardian contact us at kartheek.eadara@gmail.com"
            return
        }

        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    firstName: firstName.trimmingCharacters(in: .whitespaces),
                    lastName: lastName.trimmingCharacters(in: .whitespaces)
                )
            } catch {
                // Error handled by AuthService
            }
        }
    }

    private func validateDate() {
        let maxDay = validDays.max() ?? 31
        if birthDay > maxDay {
            birthDay = maxDay
        }
    }

    private func isAgeValid() -> Bool {
        let calendar = Calendar.current
        let age = calendar.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return age >= 13
    }
}

#Preview {
    NavigationView {
        SignUpFlowView(onSwitchToSignIn: {}, onContinueAsGuest: {})
            .environmentObject(AuthService())
    }
}
