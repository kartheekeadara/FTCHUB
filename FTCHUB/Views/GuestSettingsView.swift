//
//  GuestSettingsView.swift
//  FTCHUB
//

import SwiftUI

struct GuestSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingSignUp = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    profileCard
                    appSection
                    supportSection
                    accountSection
                }
                .padding(.top, 10)
            }
            .tabBarScrollInset()
            .background(DesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingSignUp) {
                AuthenticationView(
                    initialSignUpMode: true,
                    showsCloseButton: true,
                    onContinueAsGuest: {
                        showingSignUp = false
                    }
                )
                .environmentObject(authService)
            }
            .onChange(of: authService.isGuestMode) { _, isGuest in
                if isGuest {
                    showingSignUp = false
                }
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primary.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text("G")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Guest User")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    Text("Browsing as a guest")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(16)
        }
        .background(DesignSystem.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    // MARK: - APP Section

    private var appSection: some View {
        GuestMoreSection(header: "APP") {
            AppearanceRow()
        }
    }

    // MARK: - SUPPORT Section

    private var supportSection: some View {
        GuestMoreSection(header: "SUPPORT") {
            HStack(spacing: 14) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 28)
                Text("App Version")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .frame(height: 52)
            .padding(.horizontal, 16)
            Divider().background(DesignSystem.Colors.separator).padding(.leading, 52)
            GuestMoreActionRow(icon: "star.fill", title: "Rate the App") {
                if let url = URL(string: "https://apps.apple.com/app/id6746783505") {
                    UIApplication.shared.open(url)
                }
            }
            Divider().background(DesignSystem.Colors.separator).padding(.leading, 52)
            GuestMoreActionRow(icon: "envelope.fill", title: "Send Feedback") {
                if let url = URL(string: "mailto:support@ftchub.app") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    // MARK: - ACCOUNT Section

    private var accountSection: some View {
        GuestMoreSection(header: "ACCOUNT") {
            Button(action: {
                showingSignUp = true
            }) {
                HStack(spacing: 14) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .frame(width: 28)
                    Text("Sign Up")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Spacer()
                }
                .frame(height: 52)
                .padding(.horizontal, 16)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Shared helper components

private struct GuestMoreSection<Content: View>: View {
    let header: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(header)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .tracking(0.5)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                content
            }
            .background(DesignSystem.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
    }
}

private struct GuestMoreActionRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 28)
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            .frame(height: 52)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct AppearanceRow: View {
    @AppStorage("ftchub.colorScheme") private var colorSchemeRaw: String = "light"

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 20))
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 28)
            Text("Appearance")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            Spacer()
            Picker("Appearance", selection: $colorSchemeRaw) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .frame(height: 52)
        .padding(.horizontal, 16)
    }
}
