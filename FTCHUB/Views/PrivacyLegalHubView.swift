//
//  PrivacyLegalHubView.swift
//  FTCHUB
//

import SwiftUI

struct PrivacyLegalHubView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("ftchub.legalConsentAccepted") private var legalConsentAccepted = false

    var body: some View {
        ScrollView {
            SettingsListCard {
                NavigationLink {
                    LegalConsentView()
                        .environmentObject(authService)
                } label: {
                    SettingsListRow(
                        icon: legalConsentAccepted ? "checkmark.shield" : "exclamationmark.shield",
                        title: L10n.Legal.consentTitle,
                        subtitle: legalConsentAccepted
                            ? L10n.Settings.legalConsentSubtitleAccepted
                            : L10n.Settings.legalConsentSubtitleRequired,
                        trailing: legalConsentAccepted
                            ? AnyView(Image(systemName: "checkmark.circle.fill").foregroundColor(DesignSystem.Colors.success))
                            : nil,
                        showsDisclosure: !legalConsentAccepted
                    )
                }
                .buttonStyle(.plain)

                settingsListDivider()

                NavigationLink(destination: PrivacyDataProcessingView()) {
                    SettingsListRow(
                        icon: "server.rack",
                        title: L10n.Settings.dataSubprocessorsTitle,
                        subtitle: L10n.Settings.dataSubprocessorsSubtitle,
                        showsDisclosure: false
                    )
                }
                .buttonStyle(.plain)

                settingsListDivider()

                NavigationLink(destination: LegalDocumentView(title: L10n.Legal.privacyPolicyTitle, resourceName: "PrivacyPolicy")) {
                    SettingsListRow(
                        icon: "shield.lefthalf.filled",
                        title: L10n.Legal.privacyPolicyTitle,
                        subtitle: L10n.Settings.privacyPolicySubtitle,
                        showsDisclosure: false
                    )
                }
                .buttonStyle(.plain)

                settingsListDivider()

                NavigationLink(destination: LegalDocumentView(title: L10n.Legal.termsTitle, resourceName: "TermsOfService")) {
                    SettingsListRow(
                        icon: "doc.plaintext",
                        title: L10n.Legal.termsTitle,
                        subtitle: L10n.Settings.termsSubtitle,
                        showsDisclosure: false
                    )
                }
                .buttonStyle(.plain)

                settingsListDivider()

                NavigationLink(destination: LegalDocumentView(title: L10n.Legal.supportTitle, resourceName: "SupportGuide")) {
                    SettingsListRow(
                        icon: "lifepreserver",
                        title: L10n.Legal.supportTitle,
                        subtitle: L10n.Settings.supportSubtitle,
                        showsDisclosure: false
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(L10n.Settings.privacyLegalHubTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyLegalHubView()
            .environmentObject(AuthService())
    }
}
