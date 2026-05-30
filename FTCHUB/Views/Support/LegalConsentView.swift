//
//  LegalConsentView.swift
//  FTCHUB
//
//  Created by GPT-5 Codex on 11/8/25.
//

import SwiftUI

struct LegalConsentView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("ftchub.legalConsentAccepted") private var hasAccepted = false
    @State private var consentRecord: LegalConsentRecord?
    
    private var currentUserID: UUID? {
        authService.currentUser?.id
    }
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: $hasAccepted) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.Legal.consentToggle)
                            .font(.subheadline.weight(.semibold))
                        Text(L10n.Legal.consentToggleDescription)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
            } footer: {
                Text(L10n.Legal.consentFooter)
            }
            .listRowBackground(DesignSystem.Colors.cardBackground)
            
            if let consentRecord = consentRecord {
                Section(L10n.Legal.consentStatusTitle) {
                    Label(String(format: L10n.Legal.consentAcceptedPrefix, consentRecord.formattedDate), systemImage: "checkmark.seal.fill")
                        .foregroundColor(DesignSystem.Colors.success)
                    if let email = authService.currentUser?.email {
                        Label(email, systemImage: "envelope.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .font(.subheadline)
                    }
                }
                .listRowBackground(DesignSystem.Colors.cardBackground)
            }
            
            Section("Documents") {
                NavigationLink(destination: LegalDocumentView(title: L10n.Legal.privacyPolicyTitle, resourceName: "PrivacyPolicy")) {
                    Label(L10n.Legal.privacyPolicyTitle, systemImage: "shield.lefthalf.filled")
                }
                
                NavigationLink(destination: LegalDocumentView(title: L10n.Legal.termsTitle, resourceName: "TermsOfService")) {
                    Label(L10n.Legal.termsTitle, systemImage: "doc.plaintext")
                }
            }
            .listRowBackground(DesignSystem.Colors.cardBackground)
            
            Section(L10n.Legal.needHelpSection) {
                NavigationLink(destination: LegalDocumentView(title: L10n.Legal.supportTitle, resourceName: "SupportGuide")) {
                    Label(L10n.Legal.contactSupport, systemImage: "envelope")
                }
            }
            .listRowBackground(DesignSystem.Colors.cardBackground)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle(L10n.Settings.sectionLegal)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncConsentState()
        }
        .task(id: hasAccepted) {
            await handleConsentChange(accepted: hasAccepted)
        }
    }
    
    @MainActor
    private func handleConsentChange(accepted: Bool) async {
        if accepted {
            let record = LegalConsentStore.recordAcceptance(for: currentUserID)
            consentRecord = record
            TelemetryService.shared.logEvent("legal_consent_accepted", parameters: [
                "user": currentUserID?.uuidString ?? "anonymous"
            ])
        } else {
            LegalConsentStore.revokeAcceptance(for: currentUserID)
            consentRecord = nil
            TelemetryService.shared.logEvent("legal_consent_revoked", parameters: [
                "user": currentUserID?.uuidString ?? "anonymous"
            ])
        }
    }
    
    private func syncConsentState() {
        if hasAccepted {
            if let existing = LegalConsentStore.currentRecord(for: currentUserID) {
                consentRecord = existing
            } else {
                let record = LegalConsentStore.recordAcceptance(for: currentUserID)
                consentRecord = record
            }
        } else {
            consentRecord = nil
        }
    }
}

#if DEBUG
struct LegalConsentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LegalConsentView()
                .environmentObject(AuthService())
        }
    }
}
#endif

