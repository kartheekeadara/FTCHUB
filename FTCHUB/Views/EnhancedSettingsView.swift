//
//  EnhancedSettingsView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 10/27/25.
//

import SwiftUI

struct EnhancedSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var teamService: TeamService
    @ObservedObject private var notificationService = NotificationService.shared
    @State private var showingProfileEditor = false

    private var hasTeam: Bool { teamService.currentTeam != nil }

    /// When `false`, assume an outer `NavigationStack` (e.g. guest More tab) so this view does not nest stacks and duplicate back buttons.
    var embedsNavigationStack: Bool = true
    /// Hides team-only and authenticated account actions when opened from guest More.
    var isGuestContext: Bool = false

    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack {
                    settingsScroll
                }
            } else {
                settingsScroll
            }
        }
        .sheet(isPresented: $showingProfileEditor) {
            if let profile = authService.currentUser {
                ProfileEditorView(profile: profile)
                    .environmentObject(authService)
            } else {
                NavigationView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 64))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(L10n.Settings.profileUnavailable)
                            .multilineTextAlignment(.center)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Button(L10n.General.actionClose) {
                            showingProfileEditor = false
                        }
                        .primaryButtonStyle()
                    }
                    .padding()
                    .navigationTitle(L10n.Settings.profileEditorTitle)
                }
            }
        }
    }

    private var settingsScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                if !isGuestContext {
                    settingsListContent

                    Text(L10n.Settings.deleteAccountCaption)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(Color(.systemBackground))
        .tabBarScrollInset()
        .navigationTitle(L10n.Settings.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var settingsListContent: some View {
        VStack(spacing: 10) {
            Button {
                showingProfileEditor = true
            } label: {
                UserProfileCard(showChevron: true)
            }
            .buttonStyle(.plain)

            if let infoMessage = authService.infoMessage {
                SettingsInfoMessage(message: infoMessage)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }

            NavigationLink {
                AppearanceSettingsView()
            } label: {
                SettingsListRow(
                    icon: "paintbrush",
                    title: L10n.Settings.appearanceTitle,
                    subtitle: L10n.Settings.appearanceSubtitle,
                    showsDisclosure: false
                )
            }
            .buttonStyle(.plain)

            if hasTeam {
                NavigationLink(destination: TeamSettingsView()) {
                    SettingsListRow(
                        icon: "person.3",
                        title: L10n.Settings.teamSettingsTitle,
                        subtitle: L10n.Settings.teamSettingsSubtitle,
                        showsDisclosure: false
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: InviteCodeView()) {
                    SettingsListRow(
                        icon: "person.badge.plus",
                        title: L10n.Settings.inviteMembersTitle,
                        subtitle: L10n.Settings.inviteMembersSubtitle,
                        showsDisclosure: false
                    )
                }
                .buttonStyle(.plain)
            } else {
                TeamRequiredRow(feature: L10n.Settings.teamSettingsTitle)
                    .padding(.horizontal, DesignSystem.Spacing.md)
            }

            NavigationLink {
                NotificationSettingsView()
                    .environmentObject(notificationService)
            } label: {
                SettingsListRow(
                    icon: "bell",
                    title: L10n.Settings.notificationsTitle,
                    subtitle: notificationsSubtitle,
                    showsDisclosure: false
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                PrivacyLegalHubView()
                    .environmentObject(authService)
            } label: {
                SettingsListRow(
                    icon: "shield.lefthalf.filled",
                    title: L10n.Settings.privacyLegalHubTitle,
                    subtitle: L10n.Settings.privacyLegalHubSubtitle,
                    showsDisclosure: false
                )
            }
            .buttonStyle(.plain)

            Button {
                Task {
                    try? await authService.signOut()
                }
            } label: {
                SettingsListRow(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: L10n.General.actionSignOut,
                    subtitle: "",
                    titleColor: DesignSystem.Colors.error,
                    showsDisclosure: false
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                DeleteAccountView()
                    .environmentObject(authService)
            } label: {
                SettingsListRow(
                    icon: "trash",
                    title: L10n.Settings.deleteAccountTitle,
                    subtitle: L10n.Settings.deleteAccountSubtitle,
                    titleColor: DesignSystem.Colors.error,
                    showsDisclosure: false
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var notificationsSubtitle: String {
        if notificationService.isAuthorized {
            return L10n.General.statusConfigured
        }
        return L10n.Settings.notificationsSubtitle
    }
}

// MARK: - Profile Header

struct UserProfileCard: View {
    @EnvironmentObject var authService: AuthService
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(DesignSystem.Gradients.primary)
                .frame(width: 56, height: 56)
                .overlay(
                    Text(authService.currentUser?.initials ?? "?")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(authService.currentUser?.displayName ?? "Unknown User")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)

                Text(authService.currentUser?.email ?? "")
                    .font(.system(size: 13))
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                if let role = authService.currentUser?.role {
                    Text(role.displayName)
                        .font(.caption)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.primary.opacity(0.1))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .cornerRadius(DesignSystem.CornerRadius.sm)
                }

                if authService.currentUser?.isProfileIncomplete == true {
                    Text(L10n.Settings.profileIncompleteHint)
                        .font(.system(size: 13))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.md)
        .contentShape(Rectangle())
    }
}

extension Profile {
    var isProfileIncomplete: Bool {
        let nameMissing = (firstName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            && (lastName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let phoneMissing = phone?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        let emergencyMissing = (emergencyContactName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            || (emergencyContactPhone?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        return nameMissing || phoneMissing || emergencyMissing
    }
}

struct TeamRequiredRow: View {
    let feature: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(DesignSystem.Colors.primary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.General.teamRequiredMessage(feature))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                Text(L10n.General.teamRequiredHint)
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Button {
                    NotificationCenter.default.post(name: .ftcShowTeamTab, object: nil)
                } label: {
                    Text("Go to Team Tab →")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DesignSystem.Colors.primary)
                        .clipShape(Capsule())
                }
                .accessibilityLabel("Open Team tab")
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(DesignSystem.Colors.orangeTintWash)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DesignSystem.Colors.orangeTintBorder, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

extension Notification.Name {
    static let ftcShowTeamTab = Notification.Name("ftchub.showTeamTab")
    static let ftcOpenEvent = Notification.Name("ftchub.openEvent")
    static let ftcOpenTask = Notification.Name("ftchub.openTask")
    static let ftcOpenInventoryItem = Notification.Name("ftchub.openInventoryItem")
    static let ftcOpenMatch = Notification.Name("ftchub.openMatch")
}

struct SettingsInfoMessage: View {
    let message: String

    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(DesignSystem.Colors.success)
                .imageScale(.medium)
            Text(message)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.success)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

struct SettingsErrorMessage: View {
    let message: String

    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignSystem.Colors.error)
                .imageScale(.medium)
            Text(message)
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.error)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

#Preview {
    EnhancedSettingsView()
        .environmentObject(AuthService())
}
